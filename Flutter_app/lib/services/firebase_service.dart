import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../utils/timestamp_converter.dart';

/// Service class để xử lý tất cả tương tác với Firebase Realtime Database
class FirebaseService {
  // Firebase references
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('nhietdo');
  final DatabaseReference _ipRef = FirebaseDatabase.instance.ref('ip_address');
  final DatabaseReference _status2Ref = FirebaseDatabase.instance.ref('status2');
  final DatabaseReference _maybomRef = FirebaseDatabase.instance.ref('thietbi/maybom');
  final DatabaseReference _oxiRef = FirebaseDatabase.instance.ref('thietbi/oxi');
  final DatabaseReference _roiRef = FirebaseDatabase.instance.ref('roi');
  final DatabaseReference _sensorDataRef = FirebaseDatabase.instance.ref('sensor_data');

  /// Stream dữ liệu cảm biến hiện tại (nhiệt độ và độ ẩm)
  Stream<Map<String, dynamic>> get sensorStream {
    return _sensorRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return {
        'temperature': data?['temperature']?.toDouble() ?? 0.0,
        'humidity': data?['humidity']?.toDouble() ?? 0.0,
      };
    });
  }

  /// Stream địa chỉ IP của camera
  Stream<String> get ipStream {
    return _ipRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return data?['ip']?.toString() ?? '--';
    });
  }

  /// Stream trạng thái chế độ giám sát
  Stream<int> get status2Stream {
    return _status2Ref.onValue.map((event) {
      return int.tryParse(event.snapshot.value?.toString() ?? '0') ?? 0;
    });
  }

  /// Stream trạng thái máy bơm
  Stream<int> get maybomStream {
    return _maybomRef.onValue.map((event) {
      return int.tryParse(event.snapshot.value?.toString() ?? '0') ?? 0;
    });
  }

  /// Stream trạng thái máy oxi
  Stream<int> get oxiStream {
    return _oxiRef.onValue.map((event) {
      return int.tryParse(event.snapshot.value?.toString() ?? '0') ?? 0;
    });
  }

  /// Stream cấu hình ROI (Region of Interest)
  Stream<Map<String, int>> get roiStream {
    return _roiRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return {
        'h': (data?['h'] as num?)?.toInt() ?? 0,
        'w': (data?['w'] as num?)?.toInt() ?? 0,
        'x': (data?['x'] as num?)?.toInt() ?? 0,
        'y': (data?['y'] as num?)?.toInt() ?? 0,
      };
    });
  }

  /// Cập nhật trạng thái chế độ giám sát
  /// [value]: 0 - Tắt, 1 - Bật
  Future<void> updateStatus2(int value) async {
    await _status2Ref.set(value);
  }

  /// Điều khiển máy bơm
  /// [value]: 0 - Tắt, 1 - Bật
  Future<void> updateMaybom(int value) async {
    await _maybomRef.set(value);
  }

  /// Điều khiển máy oxi
  /// [value]: 0 - Tắt, 1 - Bật
  Future<void> updateOxi(int value) async {
    await _oxiRef.set(value);
  }

  /// Cập nhật cấu hình ROI
  /// [field]: Trường cần cập nhật ('h', 'w', 'x', 'y')
  /// [value]: Giá trị mới
  Future<void> updateROI(String field, int value) async {
    Map<String, dynamic> updates = {};
    switch (field) {
      case 'h': // Chiều cao
        if (value > 0 && value <= 1080) updates['h'] = value;
        break;
      case 'w': // Chiều rộng
        if (value > 0 && value <= 1920) updates['w'] = value;
        break;
      case 'x': // Tọa độ X
        if (value >= 0 && value < 1920) updates['x'] = value;
        break;
      case 'y': // Tọa độ Y
        if (value >= 0 && value < 1080) updates['y'] = value;
        break;
    }
    if (updates.isNotEmpty) {
      await _roiRef.update(updates);
    }
  }

  /// Lấy dữ liệu cảm biến của 7 ngày gần nhất
  Future<List<SensorData>> fetchWeeklyData() async {
    final snapshot = await _sensorDataRef.get();
    List<SensorData> allData = [];

    if (snapshot.exists && snapshot.value != null) {
      final allDates = snapshot.value as Map<dynamic, dynamic>;
      
      // Duyệt qua từng ngày và chuyển đổi dữ liệu
      allDates.forEach((dateStr, dateData) {
        if (dateData is Map) {
          dateData.forEach((key, value) {
            if (value is Map) {
              final dateTime = TimestampConverter.convert(int.tryParse(key.toString()));
              allData.add(SensorData.fromMap(value, dateTime));
            }
          });
        }
      });
    }

    // Sắp xếp và lọc dữ liệu 7 ngày gần nhất
    allData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    return allData.where((data) => 
      data.timestamp.isAfter(sevenDaysAgo) && 
      data.timestamp.isBefore(now.add(const Duration(days: 1)))
    ).toList();
  }
} 