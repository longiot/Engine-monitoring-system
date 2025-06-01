import time
import RPi.GPIO as GPIO
import firebase_admin
from firebase_admin import credentials, db

# ==== Cấu hình GPIO ====
GPIO.setmode(GPIO.BCM)
PIN_1 = 4
PIN_2 = 27
GPIO.setup(PIN_1, GPIO.OUT)
GPIO.setup(PIN_2, GPIO.OUT)

# ==== Kết nối Firebase ====
cred = credentials.Certificate("streamsensorapp.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'FIREBASE_DATABASE_URL'  # Thay link này!
})

ref = db.reference("thietbi")

print("Bắt đầu điều khiển GPIO từ Firebase...")
try:
    while True:
        data = ref.get()
        if data:
            gpio4_state = data.get("maybom", 0)
            gpio27_state = data.get("oxi", 0)

            GPIO.output(PIN_1, GPIO.HIGH if gpio4_state else GPIO.LOW)
            GPIO.output(PIN_2, GPIO.HIGH if gpio27_state else GPIO.LOW)

            print(f"[may_bom]: {'BẬT' if gpio4_state else 'TẮT'} | [may_tao_oxi]: {'BẬT' if gpio27_state else 'TẮT'}")

        else:
            print("Không nhận được dữ liệu từ Firebase.")

        time.sleep(15)

except KeyboardInterrupt:
    print("\n Dừng chương trình.")

finally:
    GPIO.cleanup()