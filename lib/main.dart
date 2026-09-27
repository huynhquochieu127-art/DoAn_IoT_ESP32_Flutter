import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
void main() {
  runApp(const ESP32ControlApp());
}

class ESP32ControlApp extends StatelessWidget {
  const ESP32ControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Smart Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ControlScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  // 👉 HÃY THAY ĐỔI ĐỊA CHỈ IP NÀY BẰNG IP CỦA ESP32 TRÊN SERIAL MONITOR
  final String ipAddress = "172.20.10.3";

  double _temperature = 0.0;
  double _humidity = 0.0;
  bool _isLedOn = false;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _fetchData(); // Lấy dữ liệu ngay khi mở app

    // 🔄 Tự động gọi lại hàm _fetchData mỗi 2 giây để cập nhật nhiệt độ mới từ ESP32
    Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchData();
    });
  }

  // Hàm gọi API lấy nhiệt độ, độ ẩm và trạng thái đèn từ ESP32
  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddress/data'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _temperature = data['temperature'];
          _humidity = data['humidity'];
          _isLedOn = data['led'] == 1;
        });
      }
    } catch (e) {
      debugPrint("Lỗi kết nối ESP32: $e");
    }
  }

  // Hàm gửi lệnh bật/tắt đèn LED thủ công từ điện thoại
  Future<void> _toggleLed(bool value) async {
    setState(() {
      _isLoading = true;
    });
    String stateStr = value ? "on" : "off";
    try {
      final response = await http.get(Uri.parse('http://$ipAddress/led?state=$stateStr'));
      if (response.statusCode == 200) {
        setState(() {
          _isLedOn = value;
        });
      }
    } catch (e) {
      debugPrint("Lỗi điều khiển đèn: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giám Sát & Điều Khiển ESP32'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData, // Nút bấm làm mới dữ liệu
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Hai thẻ Card hiển thị nhiệt độ và độ ẩm
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'Nhiệt Độ',
                    value: '${_temperature.toStringAsFixed(1)} °C',
                    icon: Icons.thermostat,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Độ Ẩm',
                    value: '${_humidity.toStringAsFixed(1)} %',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Thẻ Card điều khiển bật/tắt đèn LED
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLedOn ? Icons.lightbulb : Icons.lightbulb_outline,
                          color: _isLedOn ? Colors.amber : Colors.grey,
                          size: 36,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Đèn Cảnh Báo LED',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Switch(
                      value: _isLedOn,
                      activeColor: Colors.blueAccent,
                      onChanged: _toggleLed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}