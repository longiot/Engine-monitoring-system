import 'package:flutter/material.dart';

/// Widget điều khiển các thiết bị (máy bơm và máy oxi)
class ControlPanel extends StatelessWidget {
  /// Trạng thái hiện tại của máy bơm (0: Tắt, 1: Bật)
  final int maybomStatus;
  
  /// Trạng thái hiện tại của máy oxi (0: Tắt, 1: Bật)
  final int oxiStatus;
  
  /// Callback khi thay đổi trạng thái máy bơm
  final Function(int) onMaybomChanged;
  
  /// Callback khi thay đổi trạng thái máy oxi
  final Function(int) onOxiChanged;

  const ControlPanel({
    Key? key,
    required this.maybomStatus,
    required this.oxiStatus,
    required this.onMaybomChanged,
    required this.onOxiChanged,
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
              'Điều khiển thiết bị',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Điều khiển máy bơm
                _buildControlColumn(
                  'Máy bơm',
                  Icons.opacity,
                  maybomStatus,
                  onMaybomChanged,
                ),
                // Điều khiển máy oxi
                _buildControlColumn(
                  'Máy oxi',
                  Icons.air,
                  oxiStatus,
                  onOxiChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tạo cột điều khiển cho một thiết bị
  /// 
  /// [title]: Tên thiết bị
  /// [icon]: Icon đại diện cho thiết bị
  /// [status]: Trạng thái hiện tại (0: Tắt, 1: Bật)
  /// [onChanged]: Callback khi thay đổi trạng thái
  Widget _buildControlColumn(
    String title,
    IconData icon,
    int status,
    Function(int) onChanged,
  ) {
    return Column(
      children: [
        Icon(icon, size: 30),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            // Nút TẮT
            ElevatedButton(
              onPressed: () => onChanged(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 0 ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('TẮT'),
            ),
            const SizedBox(width: 8),
            // Nút BẬT
            ElevatedButton(
              onPressed: () => onChanged(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 1 ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('BẬT'),
            ),
          ],
        ),
      ],
    );
  }
} 