import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  // ⚠️ KIỂM TRA LẠI IP CỦA BẠN
  final String ipAddress = "172.20.10.3";

  double _temperature = 0.0;
  double _humidity = 0.0;
  bool _isLedOn = false;
  bool _isAutoMode = true;

  double _maxTemp = -999.0;
  double _minTemp = 999.0;

  final List<FlSpot> _tempHistory = [];
  int _timeIndex = 0;

  final List<Map<String, dynamic>> _notifications = [];
  String _lastCondition = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchData();
    });
  }

  // --- HÀM TẠO THÔNG BÁO SỔ TỪ TRÊN XUỐNG ---
  void _showTopNotification(String message, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14))),
          ],
        ),
        backgroundColor: color.withOpacity(0.95), // Màu nền hơi trong suốt cho sang
        behavior: SnackBarBehavior.floating,
        // Dùng margin để đẩy thông báo lên sát mép trên màn hình
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 180,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 5), // Tự động ẩn sau 5 giây
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 10,
      ),
    );
  }

  void _checkAndAddNotification(double temp, double hum) {
    String currentCondition = "normal";
    String message = "";
    IconData icon = Icons.info;
    Color color = Colors.grey;

    if (temp >= 35.0) {
      currentCondition = "warning";
      message = "NGUY HIỂM: Nhiệt độ vượt 35°C. Đã tự động kích hoạt hệ thống cảnh báo!";
      icon = Icons.warning_amber_rounded;
      color = Colors.red;
    } else if (temp >= 30.0 && temp < 35.0) {
      currentCondition = "hot";
      message = "Thời tiết nóng. Bật phun sương & đẩy ngay bài quảng cáo đồ uống giải nhiệt!";
      icon = Icons.local_fire_department;
      color = Colors.orange;
    } else if (temp < 25.0 && hum > 80.0) {
      currentCondition = "cold_wet";
      message = "Trời mưa ẩm. Bật hút ẩm kho & chạy chiến dịch Flash Sale giao hàng ngay!";
      icon = Icons.water_drop;
      color = Colors.blue;
    } else if (temp >= 25.0 && temp < 30.0) {
      currentCondition = "ideal";
      message = "Môi trường lý tưởng. Đề xuất giảm công suất máy lạnh để tối ưu chi phí.";
      icon = Icons.eco;
      color = Colors.green;
    } else {
      currentCondition = "normal";
    }

    if (currentCondition != _lastCondition && currentCondition != "normal") {
      DateTime now = DateTime.now();
      String timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day}/${now.month}";

      setState(() {
        _notifications.insert(0, {
          "time": timeString,
          "message": message,
          "icon": icon,
          "color": color,
        });
        _lastCondition = currentCondition;
      });

      // Gọi hiển thị thông báo popup trượt xuống
      _showTopNotification(message, icon, color);
    }
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddress/data'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _temperature = data['temperature'].toDouble();
          _humidity = data['humidity'].toDouble();
          _isLedOn = data['led'] == 1;
          _isAutoMode = data['isAuto'] == "true";

          if (_temperature > _maxTemp) _maxTemp = _temperature;
          if (_minTemp == 999.0 || _temperature < _minTemp) _minTemp = _temperature;

          _tempHistory.add(FlSpot(_timeIndex.toDouble(), _temperature));
          _timeIndex++;
          if (_tempHistory.length > 15) {
            _tempHistory.removeAt(0);
          }
        });
        _checkAndAddNotification(_temperature, _humidity);
      }
    } catch (e) {
      debugPrint('Lỗi kết nối: $e');
    }
  }

  Future<void> _toggleLed(bool value) async {
    if (_isAutoMode) return;
    try {
      String state = value ? "on" : "off";
      await http.get(Uri.parse('http://$ipAddress/led?state=$state'));
      setState(() {
        _isLedOn = value;
      });
    } catch (e) {
      debugPrint('Lỗi đèn: $e');
    }
  }

  Future<void> _toggleMode(bool value) async {
    try {
      String mode = value ? "true" : "false";
      await http.get(Uri.parse('http://$ipAddress/mode?auto=$mode'));
      setState(() {
        _isAutoMode = value;
      });
    } catch (e) {
      debugPrint('Lỗi đổi chế độ: $e');
    }
  }

  Widget _buildSmartSuggestionCard() {
    String message = "";
    Color cardColor = Colors.white;
    Color textColor = Colors.black87;
    IconData icon = Icons.lightbulb_outline;
    Color iconColor = Colors.amber;

    if (_temperature >= 35.0) {
      message = "NGUY HIỂM: Nhiệt độ vượt 35°C. Đã tự động kích hoạt hệ thống cảnh báo!";
      cardColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.red;
    } else if (_temperature >= 30.0 && _temperature < 35.0) {
      message = "Thời tiết nóng bức. Đề xuất: Bật phun sương & đẩy mạnh bài quảng cáo đồ uống giải nhiệt trên nền tảng mạng xã hội.";
      cardColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      icon = Icons.local_fire_department;
      iconColor = Colors.orange;
    } else if (_temperature < 25.0 && _humidity > 80.0) {
      message = "Trời mưa ẩm. Đề xuất: Bật hút ẩm kho. Khuyến nghị chạy chiến dịch Flash Sale trên ShopeeFood/GrabFood.";
      cardColor = Colors.lightBlue.shade50;
      textColor = Colors.blue.shade900;
      icon = Icons.water_drop;
      iconColor = Colors.blue;
    } else if (_temperature >= 25.0 && _temperature < 30.0) {
      message = "Điều kiện môi trường lý tưởng. Đề xuất: Giảm công suất điều hòa, mở cửa đón gió để tối ưu chi phí vận hành.";
      cardColor = Colors.green.shade50;
      textColor = Colors.green.shade900;
      icon = Icons.eco;
      iconColor = Colors.green;
    } else {
      message = "Thông số ở mức bình thường. Gợi ý: Duy trì vận hành tiêu chuẩn. Theo dõi hàng tồn kho.";
      cardColor = Colors.grey.shade100;
      textColor = Colors.grey.shade800;
      icon = Icons.analytics;
      iconColor = Colors.grey.shade600;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text("Trợ Lý Vận Hành (AI)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 14, color: textColor, height: 1.4)),
        ],
      ),
    );
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Lịch Sử Thông Báo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(),
              Expanded(
                child: _notifications.isEmpty
                    ? const Center(child: Text("Hiện chưa có thông báo nào.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final note = _notifications[index];
                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: note["color"].withOpacity(0.2),
                          child: Icon(note["icon"], color: note["color"]),
                        ),
                        title: Text(note["message"], style: const TextStyle(fontSize: 14)),
                        subtitle: Text(note["time"], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color tempCardColor = _temperature >= 35.0 ? Colors.red.shade50 : Colors.white;
    Color tempTextColor = _temperature >= 35.0 ? Colors.red.shade700 : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giám Sát & Điều Khiển ESP32', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _notifications.isNotEmpty,
              label: Text('${_notifications.length}'),
              child: const Icon(Icons.notifications, color: Colors.white),
            ),
            onPressed: _showNotificationPanel,
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 1,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text("Chế độ Tự động (Auto)", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isAutoMode ? "Mạch ưu tiên tự bật đèn khi >= 35°C" : "Tự điều khiển bằng nút bên dưới"),
                value: _isAutoMode,
                activeColor: Colors.blueAccent,
                onChanged: _toggleMode,
              ),
            ),
            const SizedBox(height: 16),

            _buildSmartSuggestionCard(),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMainCard("Nhiệt Độ", "${_temperature.toStringAsFixed(1)}°C", Icons.thermostat, tempTextColor, tempCardColor),
                _buildMainCard("Độ Ẩm", "${_humidity.toStringAsFixed(1)}%", Icons.water_drop, Colors.blue, Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallCard("Max", "${_maxTemp == -999.0 ? '--' : _maxTemp.toStringAsFixed(1)}°C", Colors.redAccent),
                _buildSmallCard("Min", "${_minTemp == 999.0 ? '--' : _minTemp.toStringAsFixed(1)}°C", Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              color: _isAutoMode ? Colors.grey[200] : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber),
                        SizedBox(width: 12),
                        Text("Đèn Cảnh Báo LED", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Switch(
                      value: _isLedOn,
                      onChanged: _isAutoMode ? null : _toggleLed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Biểu Đồ Biến Thiên Nhiệt Độ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _tempHistory.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                LineChartData(
                  minY: 20,
                  maxY: 45,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _tempHistory,
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, spreadRadius: 1)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}