import 'package:flutter/material.dart';
import 'control_screen.dart'; // Import cái file giao diện bạn vừa tạo ở trên

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Smart Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ControlScreen(), // Gọi cái màn hình bên file kia ra hiển thị
      debugShowCheckedModeBanner: false, // Ẩn cái chữ DEBUG xấu xí ở góc
    );
  }
}