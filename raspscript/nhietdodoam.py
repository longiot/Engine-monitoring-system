import time
import board
import adafruit_dht
import firebase_admin
from firebase_admin import credentials, db
from datetime import datetime, timedelta

# Khởi tạo cảm biến DHT11 ở chân GPIO17 (D17 tương đương GPIO17)
dhtDevice = adafruit_dht.DHT11(board.D17)

# Khởi tạo Firebase
cred = credentials.Certificate("streamsensorapp.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'FIREBASE_DATABASE_URL'
})
sensor_data_ref = db.reference("sensor_data")
latest_data_ref = db.reference("nhietdo")

def delete_old_data():
    try:
        # Tính ngày 7 ngày trước
        seven_days_ago = datetime.now() - timedelta(days=7)
        date_to_delete = seven_days_ago.strftime("%Y-%m-%d")
        
        # Xóa dữ liệu cũ
        sensor_data_ref.child(date_to_delete).delete()
        print(f"Đã xóa dữ liệu của ngày {date_to_delete}")
    except Exception as e:
        print(f"Lỗi khi xóa dữ liệu cũ: {e}")

def update_firebase(temperature, humidity, max_retries=3):
    # Lấy thời gian hiện tại
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    timestamp = int(time.time())
    
    # Dữ liệu cho sensor_data (lịch sử)
    history_data = {
        "temp": temperature,
        "humidity": humidity
    }
    
    # Dữ liệu cho node nhietdo (mới nhất)
    latest_data = {
        'temperature': temperature,
        'humidity': humidity,
    }
    
    for attempt in range(max_retries):
        try:
            # Cập nhật dữ liệu lịch sử
            date_ref = sensor_data_ref.child(date_str)
            date_ref.child(str(timestamp)).set(history_data)
            
            # Cập nhật dữ liệu mới nhất
            latest_data_ref.set(latest_data)
            return True
        except Exception as e:
            print(f"Lần {attempt + 1}: Lỗi gửi Firebase: {e}")
            if attempt < max_retries - 1:
                time.sleep(2)
    return False

# Biến để theo dõi lần cuối xóa dữ liệu
last_cleanup = datetime.now()

# Vòng lặp đọc và gửi dữ liệu
while True:
    try:
        # Kiểm tra xem đã đến lúc xóa dữ liệu cũ chưa (1 lần/ngày)
        now = datetime.now()
        if (now - last_cleanup).days >= 1:
            delete_old_data()
            last_cleanup = now
        
        temperature = dhtDevice.temperature
        humidity = dhtDevice.humidity
        if temperature is not None and humidity is not None:
            print(f"Nhiệt độ: {temperature}°C, Độ ẩm: {humidity}%")
            success = update_firebase(temperature, humidity)
            if success:
                print("Đã gửi dữ liệu thành công")
            else:
                print("Không thể gửi dữ liệu sau nhiều lần thử")
        else:
            print("Không đọc được cảm biến")
    except Exception as e:
        print("Lỗi khi đọc/gửi dữ liệu:", e)

    time.sleep(600)