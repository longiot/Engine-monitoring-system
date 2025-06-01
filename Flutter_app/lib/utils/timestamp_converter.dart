/// Utility class để chuyển đổi timestamp thành DateTime
class TimestampConverter {
  /// Chuyển đổi timestamp từ Firebase thành đối tượng DateTime
  /// 
  /// [timestamp]: Giá trị timestamp có thể ở dạng seconds (10 chữ số) 
  /// hoặc milliseconds (13 chữ số)
  /// 
  /// Returns DateTime tương ứng hoặc DateTime.now() nếu có lỗi
  static DateTime convert(dynamic timestamp) {
    if (timestamp is int) {
      String timestampStr = timestamp.toString();
      // Kiểm tra độ dài của timestamp để xác định đơn vị
      if (timestampStr.length == 10) {
        // Timestamp ở dạng seconds
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        // Timestamp ở dạng milliseconds
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    return DateTime.now(); // Giá trị mặc định khi có lỗi
  }
} 