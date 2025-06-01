/// Model đại diện cho dữ liệu cảm biến tại một thời điểm
class SensorData {
  /// Thời điểm ghi nhận dữ liệu
  final DateTime timestamp;
  
  /// Giá trị nhiệt độ (°C)
  final double temperature;
  
  /// Giá trị độ ẩm (%)
  final double humidity;

  /// Constructor với các tham số bắt buộc
  SensorData({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
  });

  /// Factory constructor để tạo đối tượng từ Map data
  /// [map]: Map chứa dữ liệu từ Firebase
  /// [timestamp]: Thời điểm của dữ liệu
  factory SensorData.fromMap(Map<dynamic, dynamic> map, DateTime timestamp) {
    return SensorData(
      timestamp: timestamp,
      temperature: double.tryParse(map['temp']?.toString() ?? '0') ?? 0,
      humidity: double.tryParse(map['humidity']?.toString() ?? '0') ?? 0,
    );
  }
} 