from flask import Flask, Response
import cv2
import numpy as np
import time
import threading
import firebase_admin
from firebase_admin import credentials, db
import socket
import ipaddress
import netifaces
from concurrent.futures import ThreadPoolExecutor
import cv2.aruco as aruco
import requests

app = Flask(__name__)

# ==== Firebase ====
cred = credentials.Certificate("streamsensorapp.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'FIREBASE_DATABASE_URL'
})
roi_ref = db.reference("roi")
auth_ref = db.reference("auth")
detect_ref = db.reference("detect") 
ip_ref = db.reference("ip_address")

# ==== Initial ROI ====
roi_x, roi_y, roi_w, roi_h = 150, 300, 400, 100

# ==== Config ====
CAPTURE_INTERVAL    = 8    # seconds between detections
NO_MOTION_THRESHOLD  = 45   # seconds without motion to trigger alert
ALERT_INTERVAL       = 8    # seconds between alerts
IP_UPDATE_INTERVAL   = 600   # cập nhật IP mỗi 6 phút
webhook_url = "WEBHOOK_URL"
LAST_ARUCO_TIME = 0
ARUCO_INTERVAL = 600  # chạy ArUco mỗi 600 giây


# ==== Shared state ====
latest_frame      = None
frame_lock        = threading.Lock()
last_motion_time  = time.time()
last_ip_update   = 0
motion_ratio      = 0.0
alerting          = False

# ==== Update ROI from Firebase ====
def update_roi(event):
    global roi_x, roi_y, roi_w, roi_h
    data = event.data
    path = event.path.lstrip("/")
    if isinstance(data, dict):
        roi_x = data.get('x', roi_x)
        roi_y = data.get('y', roi_y)
        roi_w = data.get('w', roi_w)
        roi_h = data.get('h', roi_h)
    elif isinstance(data, int) and path in ['x','y','w','h']:
        mapping = {'x':'roi_x', 'y':'roi_y', 'w':'roi_w', 'h':'roi_h'}
        globals()[mapping[path]] = data

threading.Thread(target=lambda: roi_ref.listen(update_roi), daemon=True).start()

# ==== Network scan utilities ====
def get_subnet():
    iface = netifaces.gateways()['default'][netifaces.AF_INET][1]
    info = netifaces.ifaddresses(iface)[netifaces.AF_INET][0]
    return f"{info['addr']}/{info['netmask']}"

def check_port(ip, port):
    try:
        sock = socket.socket()
        sock.settimeout(0.5)
        open_ = sock.connect_ex((str(ip), port)) == 0
        sock.close()
        return open_
    except:
        return False

def find_rtsp_camera(subnet):
    network = ipaddress.IPv4Network(subnet, strict=False)
    with ThreadPoolExecutor(max_workers=50) as ex:
        futures = {ex.submit(check_port, ip, 554): ip for ip in network.hosts()}
        for f in futures:
            if f.result():
                return str(futures[f])
    return None

# ==== Initialize camera URL ====
camera_url = None
def init_camera():
    global camera_url
    subnet = get_subnet()
    cam_ip = find_rtsp_camera(subnet)
    if not cam_ip:
        raise RuntimeError("Camera not found in local network")
    creds = auth_ref.get() or {}
    user = creds.get('username', 'admin')
    pwd  = creds.get('password', 'admin')
    camera_url = f"rtsp://{user}:{pwd}@{cam_ip}:554/stream1"

# ==== Thread 1: Capture latest frame ====
def capture_thread():
    cap = cv2.VideoCapture(camera_url)
    if not cap.isOpened():
        print("Failed to open camera stream")
        return
    while True:
        ret, frame = cap.read()
        if ret:
            with frame_lock:
                global latest_frame
                latest_frame = frame.copy()
        time.sleep(0.01)

# ==== Thread 2: Motion detection (ROI-only with ArUco) ====
def detection_thread():
    """mỗi CAPTURE_INTERVAL lấy frame, detect ArUco, crop ROI, detect motion"""

    global last_motion_time, motion_ratio, alerting, LAST_ARUCO_TIME

    prev_frame = None
    aruco_dict = aruco.getPredefinedDictionary(aruco.DICT_4X4_50)
    last_motion_state = 0  # Thêm biến để theo dõi trạng thái motion trước đó

    while True:
        time.sleep(CAPTURE_INTERVAL)
        # Lấy frame mới nhất
        with frame_lock:
            frame = latest_frame.copy() if latest_frame is not None else None
        if frame is None:
            continue

        # Grayscale + blur
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray_blur = cv2.GaussianBlur(gray, (5, 5), 0)

        # Phát hiện ArUco marker để cập nhật ROI
        now = time.time()
        if now - LAST_ARUCO_TIME > ARUCO_INTERVAL:
            corners, ids, _ = aruco.detectMarkers(frame, aruco_dict)
            if ids is not None:
                for i, marker_id in enumerate(ids.flatten()):
                    if marker_id == 0:
                        top_left = corners[i][0][0]
                        roi_x_new, roi_y_new = int(top_left[0]), int(top_left[1])
                        globals().update({'roi_x': roi_x_new, 'roi_y': roi_y_new})
                        break
            LAST_ARUCO_TIME = now

        # Giới hạn ROI trong ảnh
        h, w = gray_blur.shape
        x0 = min(max(0, roi_x), w - 1)
        y0 = min(max(0, roi_y), h - 1)
        x1 = min(x0 + roi_w, w)
        y1 = min(y0 + roi_h, h)

        # Crop vùng ROI
        roi_gray = gray_blur[y0:y1, x0:x1]
        if roi_gray.size == 0:
            continue

        # Khởi tạo hoặc đảm bảo cùng kích thước
        if prev_frame is None or prev_frame.shape != roi_gray.shape:
            prev_frame = roi_gray.copy()
            continue

        # Tính khác biệt và threshold
        delta = cv2.absdiff(prev_frame, roi_gray)
        thresh = cv2.threshold(delta, 35, 255, cv2.THRESH_BINARY)[1]
        thresh = cv2.dilate(thresh, None, iterations=2)

        # Tính tỷ lệ pixel trắng
        white_pixels = np.sum(thresh == 255)
        total_pixels = roi_gray.shape[0] * roi_gray.shape[1]
        white_ratio = (white_pixels / total_pixels) * 100
        motion_ratio = white_ratio

        # Cập nhật thời gian motion và Firebase
        current_motion_state = 1 if white_ratio > 10 else 0
        if current_motion_state != last_motion_state:
            try:
                detect_ref.update({
                    'motion': current_motion_state,
                    'message': "Motion detected" if current_motion_state == 1 else "Không phát hiện chuyển động"
                })
                print(f"[FIREBASE] Status updated: {'Motion detected' if current_motion_state == 1 else 'No motion'}")
            except Exception as e:
                print(f"[FIREBASE] Update failed: {str(e)}")
            last_motion_state = current_motion_state

        if white_ratio > 10:
            last_motion_time = time.time()
            alerting = False

        # Lưu frame để lần sau so sánh
        prev_frame = roi_gray.copy()

# ==== Thread 3: Alert ====
def alert_thread():
    global alerting
    while True:
        current_time = time.time()  # Lưu time.time() để tái sử dụng

        if current_time - last_motion_time > NO_MOTION_THRESHOLD:
            if not alerting:
                print("[ALERT] Starting no-motion alerts...")
                alerting = True

            # Cập nhật Firebase
            try:
                detect_ref.update({
                    'motion': 0,
                    'message': "Không phát hiện chuyển động"
                })
                print("[FIREBASE] Status updated: No motion")

                # Gửi cảnh báo qua Discord webhook
                data = {
                    "content": "@everyone 📢 Raspberry Pi: Không phát hiện chuyển động, động cơ có thể đang bị hỏng!"
                }
                response = requests.post(webhook_url, json=data)
                if response.status_code == 204:
                    print("Gửi cảnh báo Discord thành công!")
                else:
                    print(f"Lỗi gửi Discord: {response.status_code} - {response.text}")

            except Exception as e:
                print(f"[FIREBASE/DISCORD] Update failed: {str(e)}")

            time.sleep(ALERT_INTERVAL)
        else:
            if alerting:
                print("[ALERT] Motion resumed, stopping alerts")
                alerting = False

                # Cập nhật Firebase khi có chuyển động
                try:
                    detect_ref.update({
                        'motion': 1,
                        'message': "Đang có chuyển động!"
                    })
                    print("[FIREBASE] Status updated: Motion detected")
                except Exception as e:
                    print(f"[FIREBASE] Update failed: {str(e)}")
            time.sleep(1)

# ==== Flask endpoint: show full frame with ROI and motion % ====
def gen_flask():
    while True:
        with frame_lock:
            frame = None if latest_frame is None else latest_frame.copy()
            current_motion = motion_ratio
        if frame is None:
            time.sleep(0.1)
            continue
        # Draw ROI rectangle (green)
        x0, y0 = max(0, roi_x), max(0, roi_y)
        x1, y1 = x0 + roi_w, y0 + roi_h
        cv2.rectangle(frame, (x0, y0), (x1, y1), (0, 255, 0), 2)
        # Overlay motion percentage
        text = f"Motion: {current_motion:.1f}%"
        cv2.putText(frame, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
        _, buf = cv2.imencode('.jpg', frame)
        yield (b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + buf.tobytes() + b'\r\n')

@app.route('/video')
def video_feed():
    return Response(gen_flask(), mimetype='multipart/x-mixed-replace; boundary=frame')

def get_ip_addresses():
    try:
        # Lấy giao diện mạng chính (thường là eth0 hoặc wlan0 trên Raspberry Pi)
        default_iface = netifaces.gateways()['default'][netifaces.AF_INET][1]
        # Lấy địa chỉ IP của giao diện đó
        iface_info = netifaces.ifaddresses(default_iface)[netifaces.AF_INET][0]
        return {"ip": iface_info['addr']}
    except:
        return {"ip": "Không thể lấy IP"}

# ==== Thread 4: IP Update ====
def ip_update_thread():
    global last_ip_update
    while True:
        current_time = time.time()
        if current_time - last_ip_update > IP_UPDATE_INTERVAL:
            try:
                ip_data = get_ip_addresses()
                ip_ref.set(ip_data)
                print(f"[IP] Đã cập nhật IP Raspberry Pi: {ip_data['ip']}")
                last_ip_update = current_time
            except Exception as e:
                print(f"[IP] Lỗi cập nhật: {e}")
        time.sleep(60)  # Kiểm tra mỗi phút

if __name__ == '__main__':
    init_camera()
    threading.Thread(target=capture_thread, daemon=True).start()
    threading.Thread(target=detection_thread, daemon=True).start()
    threading.Thread(target=alert_thread, daemon=True).start()
    threading.Thread(target=ip_update_thread, daemon=True).start()
    app.run(host='0.0.0.0', port=5000, debug=False)