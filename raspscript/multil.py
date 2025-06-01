import os
import time
import signal
import subprocess
import firebase_admin
from firebase_admin import credentials, db
import socket
import netifaces

# --- Khởi tạo Firebase ---
cred = credentials.Certificate("streamsensorapp.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'FIREBASE_DATABASE_URL'
})

# --- Hàm lấy và cập nhật IP ---
def get_ip_addresses():
    try:
        default_iface = netifaces.gateways()['default'][netifaces.AF_INET][1]
        iface_info = netifaces.ifaddresses(default_iface)[netifaces.AF_INET][0]
        return {"ip": iface_info['addr']}
    except:
        return {"ip": "Không thể lấy IP"}

def update_initial_ip():
    try:
        ip_data = get_ip_addresses()
        ip_ref = db.reference("ip_address")
        ip_ref.set(ip_data)
        print(f"[KHỞI ĐỘNG] Đã cập nhật IP ban đầu: {ip_data['ip']}")
    except Exception as e:
        print(f"[KHỞI ĐỘNG] Lỗi cập nhật IP ban đầu: {e}")

# --- Cấu hình từng script: đường dẫn và Popen handle ---
scripts = {
    'status1': {
        'cmd': ['python3', 'nhietdodoam.py'],
        'proc': None,
        'ref': db.reference('status1')
    },
    'status2': {
        'cmd': ['python3', 'ngay27_5.py'],
        'proc': None,
        'ref': db.reference('status2')
    },
    'status3': {
        'cmd': ['python3', 'battat_io_firebase.py'],
        'proc': None,
        'ref': db.reference('status3')
    },
}

def start_script(key):
    info = scripts[key]
    if info['proc'] is None:
        # tạo process group mới với preexec_fn=os.setsid
        p = subprocess.Popen(
            info['cmd'],
            preexec_fn=os.setsid
        )
        info['proc'] = p
        print(f"{key}: Đã chạy PID={p.pid}")

def stop_script(key):
    info = scripts[key]
    p = info['proc']
    if p is not None and p.poll() is None:  # vẫn đang chạy
        # kill toàn bộ process group
        os.killpg(p.pid, signal.SIGTERM)
        p.wait()
        print(f"{key}: Đã dừng PID={p.pid}")
    info['proc'] = None

def check_all_statuses(interval=20):
    last = {k: None for k in scripts}
    while True:
        for key, info in scripts.items():
            raw = info['ref'].get()
            try:
                val = int(raw)
            except (TypeError, ValueError):
                print(f"{key}: Giá trị không phải số: {raw!r}")
                continue

            if val != last[key]:
                print(f"{key} changed: {last[key]} -> {val}")
                last[key] = val
                if val == 1:
                    start_script(key)
                else:
                    stop_script(key)
        time.sleep(interval)

if __name__ == "__main__":
    try:
        print("Cập nhật IP ban đầu...")
        update_initial_ip()
        
        print("Bắt đầu polling (5s interval)...")
        check_all_statuses()
    except KeyboardInterrupt:
        print("Ctrl+C: Dừng tất cả scripts…")
        for k in scripts:
            stop_script(k)
        print("Kết thúc.")