import 'package:flutter/material.dart';

/// Widget điều chỉnh vùng nhận diện (Region of Interest - ROI)
class ROIControl extends StatelessWidget {
  /// Chiều cao của vùng ROI (pixels)
  final int h;
  
  /// Chiều rộng của vùng ROI (pixels)
  final int w;
  
  /// Tọa độ X của điểm bắt đầu vùng ROI (pixels)
  final int x;
  
  /// Tọa độ Y của điểm bắt đầu vùng ROI (pixels)
  final int y;
  
  /// Callback khi thay đổi giá trị ROI
  /// [field]: Trường cần thay đổi ('h', 'w', 'x', 'y')
  /// [value]: Giá trị mới
  final Function(String, int) onROIChanged;

  const ROIControl({
    Key? key,
    required this.h,
    required this.w,
    required this.x,
    required this.y,
    required this.onROIChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Điều chỉnh vùng nhận diện (ROI)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Điều chỉnh kích thước
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildROIControl('Chiều cao', h, (value) => onROIChanged('h', value)),
                _buildROIControl('Chiều rộng', w, (value) => onROIChanged('w', value)),
              ],
            ),
            const SizedBox(height: 16),
            // Điều chỉnh vị trí
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildROIControl('Tọa độ X', x, (value) => onROIChanged('x', value)),
                _buildROIControl('Tọa độ Y', y, (value) => onROIChanged('y', value)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tạo một bộ điều khiển cho một thông số ROI
  /// 
  /// [label]: Tên thông số
  /// [value]: Giá trị hiện tại
  /// [onChanged]: Callback khi thay đổi giá trị
  Widget _buildROIControl(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nút giảm giá trị
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => onChanged(value - 10),
            ),
            // Hiển thị giá trị hiện tại
            SizedBox(
              width: 60,
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            // Nút tăng giá trị
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onChanged(value + 10),
            ),
          ],
        ),
      ],
    );
  }
} 