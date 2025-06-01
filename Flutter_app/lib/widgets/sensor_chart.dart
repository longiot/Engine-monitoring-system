import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import 'dart:math';

/// Widget hiển thị biểu đồ dữ liệu cảm biến (nhiệt độ hoặc độ ẩm)
class SensorChart extends StatelessWidget {
  /// Danh sách dữ liệu cảm biến
  final List<SensorData> data;
  
  /// Tiêu đề của biểu đồ
  final String title;
  
  /// Màu sắc của đường biểu đồ
  final Color lineColor;
  
  /// Xác định biểu đồ hiển thị nhiệt độ (true) hay độ ẩm (false)
  final bool isTemperature;
  
  /// Ngày được chọn để lọc dữ liệu
  final DateTime? selectedDate;
  
  /// Controller điều khiển cuộn ngang
  final ScrollController scrollController;

  const SensorChart({
    Key? key,
    required this.data,
    required this.title,
    required this.lineColor,
    required this.isTemperature,
    required this.selectedDate,
    required this.scrollController,
  }) : super(key: key);

  /// Lọc dữ liệu theo ngày được chọn
  List<SensorData> getFilteredData() {
    if (selectedDate == null) return data;

    return data.where((item) {
      final dataDate = DateTime(
        item.timestamp.year,
        item.timestamp.month,
        item.timestamp.day,
      );
      final selected = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
      return dataDate.isAtSameMomentAs(selected);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = getFilteredData();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Tiêu đề biểu đồ
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Vùng hiển thị biểu đồ có thể cuộn ngang
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: scrollController,
              child: SizedBox(
                width: filteredData.isEmpty
                    ? MediaQuery.of(context).size.width
                    : max(MediaQuery.of(context).size.width, filteredData.length * 50.0),
                height: 250,
                child: LineChart(
                  LineChartData(
                    // Tính giá trị min, max cho trục Y
                    minY: (filteredData.map((e) => 
                      isTemperature ? e.temperature : e.humidity
                    ).reduce((a, b) => a < b ? a : b) - 2).floorToDouble(),
                    maxY: (filteredData.map((e) => 
                      isTemperature ? e.temperature : e.humidity
                    ).reduce((a, b) => a > b ? a : b) + 2).ceilToDouble(),
                    // Cấu hình đường biểu đồ
                    lineBarsData: [
                      LineChartBarData(
                        spots: filteredData.asMap().entries.map((e) {
                          return FlSpot(
                            e.key.toDouble(),
                            isTemperature ? e.value.temperature : e.value.humidity,
                          );
                        }).toList(),
                        isCurved: false,
                        color: lineColor,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    // Cấu hình hiển thị các trục
                    titlesData: FlTitlesData(
                      // Cấu hình trục X (thời gian)
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= filteredData.length) {
                              return const Text('');
                            }
                            final date = filteredData[value.toInt()].timestamp;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  DateFormat('HH:mm\ndd/MM').format(date),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      // Cấu hình trục Y (giá trị)
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toStringAsFixed(1)}${isTemperature ? '°C' : '%'}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    // Cấu hình tương tác
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey.withAlpha(200),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 