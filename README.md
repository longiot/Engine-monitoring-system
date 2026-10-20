# 🚀 Engine Monitoring System

Hệ thống giám sát trạng thái hoạt động của động cơ và môi trường (ao nuôi / trạm bơm) kết hợp **IoT (Raspberry Pi)**, **Thị giác máy tính (OpenCV)** và **Ứng dụng di động (Flutter)**.

---

## 📌 Giới thiệu dự án

Dự án giúp tự động hóa quá trình theo dõi tình trạng vận hành của động cơ (máy bơm, quạt nước/guồng tạo oxy,...) và các chỉ số môi trường xung quanh, đồng thời gửi cảnh báo sự cố kịp thời và cho phép điều khiển thiết bị từ xa.

---

## ⚡ Các tính năng chính

- **Giám sát hoạt động động cơ (Computer Vision)**:
  - Kết nối luồng RTSP từ camera và theo dõi chuyển động trong vùng chọn (ROI).
  - Tự động căn chỉnh vị trí ROI bằng **ArUco Marker** khi camera bị rung lắc hoặc dịch chuyển.
  - Tự động phát hiện khi động cơ dừng quay quá thời gian cho phép và gửi cảnh báo khẩn cấp qua **Discord Webhook** & **Firebase**.
  - Phát luồng video trực tiếp (MJPEG stream) kèm hiển thị tỷ lệ chuyển động.

- **Đo thông số môi trường**:
  - Đọc nhiệt độ và độ ẩm thời gian thực từ cảm biến **DHT11**.
  - Tự động lưu trữ lịch sử đo đạc và dọn dẹp dữ liệu cũ quá 7 ngày.

- **Điều khiển thiết bị từ xa**:
  - Đóng/ngắt rơ-le (Relay) để bật/tắt máy bơm nước và máy tạo oxy từ xa qua Firebase.

- **Ứng dụng di động (Flutter App)**:
  - Xem trực tiếp video từ camera giám sát.
  - Tinh chỉnh tọa độ và kích thước khung ROI trực tiếp trên app.
  - Bật/tắt các thiết bị ngoại vi chỉ với một chạm.
  - Xem biểu đồ biến thiên nhiệt độ và độ ẩm theo thời gian.

---

## 🛠 Công nghệ & Phần cứng sử dụng

- **Phần cứng**: Raspberry Pi, Camera IP (RTSP), Cảm biến DHT11, Relay 2 kênh.
- **Xử lý tại biên (Edge Device)**: Python 3, OpenCV (Aruco & Motion Detection), Flask, Firebase Admin SDK.
- **Backend / Đám mây**: Firebase Realtime Database, Discord Webhook.
- **Mobile App**: Flutter (Dart), `flutter_vlc_player`, `fl_chart`.

---

## 📁 Cấu trúc thư mục

```text
Engine-monitoring-system/
├── Flutter_app/        # Mã nguồn ứng dụng di động Flutter (Android / iOS)
├── raspscript/         # Các script Python chạy trên Raspberry Pi
│   ├── multil.py             # Quản lý tiến trình & cập nhật IP
│   ├── ngay27_5.py           # Xử lý hình ảnh, phát hiện chuyển động & stream video
│   ├── nhietdodoam.py        # Đọc cảm biến DHT11 và đồng bộ dữ liệu
│   └── battat_io_firebase.py # Điều khiển đóng/ngắt Relay thiết bị
└── README.md           # Giới thiệu dự án
```
