import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:intl/intl.dart';

import 'models/sensor_data.dart';
import 'services/firebase_service.dart';
import 'widgets/sensor_chart.dart';
import 'widgets/control_panel.dart';
import 'widgets/roi_control.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SensorScreen(),
    );
  }
}

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  VlcPlayerController? _vlcController;
  final ScrollController _tempScrollController = ScrollController();
  final ScrollController _humidScrollController = ScrollController();
  
  List<SensorData> weeklyData = [];
  DateTime? _selectedDate;
  bool isLoadingData = false;

  // State variables
  double? temperature;
  double? humidity;
  int? status2;
  String? ip;
  int? maybomStatus;
  int? oxiStatus;
  int h = 0;
  int w = 0;
  int x = 0;
  int y = 0;

  @override
  void initState() {
    super.initState();
    _initializeListeners();
    _fetchWeeklyData();
  }

  void _initializeListeners() {
    _firebaseService.sensorStream.listen((data) {
      if (!mounted) return;
        setState(() {
        temperature = data['temperature'];
        humidity = data['humidity'];
        });
    });

    _firebaseService.ipStream.listen((value) {
      if (!mounted) return;
      setState(() {
        ip = value;
        _updateVideoController();
      });
    });

    _firebaseService.status2Stream.listen((value) {
      if (!mounted) return;
      setState(() {
        status2 = value;
      });
    });

    _firebaseService.maybomStream.listen((value) {
      if (!mounted) return;
      setState(() {
        maybomStatus = value;
      });
    });

    _firebaseService.oxiStream.listen((value) {
      if (!mounted) return;
      setState(() {
        oxiStatus = value;
      });
    });

    _firebaseService.roiStream.listen((data) {
      if (!mounted) return;
        setState(() {
        h = data['h'] ?? 0;
        w = data['w'] ?? 0;
        x = data['x'] ?? 0;
        y = data['y'] ?? 0;
      });
    });
  }

  void _updateVideoController() {
    if (_vlcController != null) {
      _vlcController!.dispose();
      _vlcController = null;
    }
    if (ip != null && ip != '--') {
      String streamUrl = 'http://$ip:5000/video';
      _vlcController = VlcPlayerController.network(
        streamUrl,
        autoPlay: true,
        options: VlcPlayerOptions(),
      );
    }
  }

  Future<void> restartVideoStream() async {
    if (_vlcController != null) {
      await _vlcController!.dispose();
      _vlcController = null;
    }
    
    setState(() {}); // Trigger rebuild to remove old player

    await Future.delayed(const Duration(milliseconds: 500));
    
    if (ip != null && ip != '--') {
      String streamUrl = 'http://$ip:5000/video';
      setState(() {
        _vlcController = VlcPlayerController.network(
          streamUrl,
          autoPlay: true,
          options: VlcPlayerOptions(),
        );
      });
    }
  }

  Future<void> _fetchWeeklyData() async {
    if (isLoadingData) return;
    setState(() {
      isLoadingData = true;
    });

    try {
      final data = await _firebaseService.fetchWeeklyData();
      setState(() {
        weeklyData = data;
        isLoadingData = false;
      });
      await restartVideoStream();
    } catch (e) {
      setState(() {
        isLoadingData = false;
      });
    }
  }

  List<DateTime> getAvailableDates() {
    if (weeklyData.isEmpty) return [];

    final dates = weeklyData.map((data) => DateTime(
      data.timestamp.year,
      data.timestamp.month,
      data.timestamp.day,
    )).toSet().toList();

    dates.sort((a, b) => a.compareTo(b));
    return dates;
  }

  void _scrollToEnd() {
    if (_tempScrollController.hasClients) {
      _tempScrollController.animateTo(
        _tempScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    if (_humidScrollController.hasClients) {
      _humidScrollController.animateTo(
        _humidScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    _vlcController?.dispose();
    _tempScrollController.dispose();
    _humidScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giám sát ao nuôi'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWeeklyData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEnvironmentCard(),
            const SizedBox(height: 16),
            
            ControlPanel(
              maybomStatus: maybomStatus ?? 0,
              oxiStatus: oxiStatus ?? 0,
              onMaybomChanged: (value) => _firebaseService.updateMaybom(value),
              onOxiChanged: (value) => _firebaseService.updateOxi(value),
            ),
            const SizedBox(height: 16),

            _buildMonitoringModeCard(),
            const SizedBox(height: 16),

            ROIControl(
              h: h,
              w: w,
              x: x,
              y: y,
              onROIChanged: _firebaseService.updateROI,
            ),
            const SizedBox(height: 16),

            _buildCameraCard(),
            const SizedBox(height: 16),

            _buildChartSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    return Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Thông số môi trường',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                _buildEnvironmentValue(
                  Icons.thermostat,
                  Colors.red,
                  temperature?.toStringAsFixed(1) ?? "--",
                  "°C",
                  "Nhiệt độ",
                ),
                _buildEnvironmentValue(
                  Icons.water_drop,
                  Colors.blue,
                  humidity?.toStringAsFixed(1) ?? "--",
                  "%",
                  "Độ ẩm",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildEnvironmentValue(
    IconData icon,
    Color color,
    String value,
    String unit,
    String label,
  ) {
    return Column(
                  children: [
        Icon(icon, size: 40, color: color),
                            const SizedBox(height: 8),
        Text(
          "$value$unit",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildMonitoringModeCard() {
    return Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Chế độ giám sát',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_camera_back, size: 30),
                        const SizedBox(width: 8),
                        Switch(
                          value: (status2 ?? 0) == 1,
                  onChanged: (_) => _firebaseService.updateStatus2((status2 ?? 0) == 1 ? 0 : 1),
                        ),
                      ],
                    ),
                    Text(
                      'IP: ${ip ?? "--"}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildCameraCard() {
    if (_vlcController != null) {
      return Card(
                elevation: 4,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Camera quan sát',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: VlcPlayer(
                        controller: _vlcController!,
                        aspectRatio: 16 / 9,
                        placeholder: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],
                ),
      );
    }
    
    return const Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.videocam_off, size: 40, color: Colors.red),
                      SizedBox(height: 8),
                      Text(
                        'Không thể kết nối camera',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildChartSection() {
    return Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Dữ liệu 7 ngày gần nhất',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (isLoadingData)
                      const Center(child: CircularProgressIndicator())
                    else if (weeklyData.isEmpty)
                      const Center(child: Text('Không có dữ liệu'))
                    else
                      Column(
                        children: [
                  _buildDatePicker(),
                  const SizedBox(height: 16),
                  SensorChart(
                    data: weeklyData,
                    title: 'Biểu đồ nhiệt độ',
                    lineColor: Colors.red,
                    isTemperature: true,
                    selectedDate: _selectedDate,
                    scrollController: _tempScrollController,
                  ),
                  const SizedBox(height: 16),
                  SensorChart(
                    data: weeklyData,
                    title: 'Biểu đồ độ ẩm',
                    lineColor: Colors.blue,
                    isTemperature: false,
                    selectedDate: _selectedDate,
                    scrollController: _humidScrollController,
                  ),
                ],
                                  ),
                                ],
                              ),
                            ),
    );
  }

  Widget _buildDatePicker() {
    return DropdownButton<DateTime>(
                                    value: _selectedDate,
                                    hint: const Text('Chọn ngày'),
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<DateTime>(
                                        value: null,
                                        child: Text('Tất cả'),
                                      ),
                                      ...getAvailableDates().map((date) {
                                        return DropdownMenuItem<DateTime>(
                                          value: date,
                                          child: Text(DateFormat('dd/MM/yyyy').format(date)),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDate = value;
                                      });
                                    },
    );
  }
}