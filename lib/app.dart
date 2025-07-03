import 'package:flutter/material.dart';
import 'pages/main_layout.dart';

class EDMApp extends StatelessWidget {
  const EDMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '阿里云EDM管理',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainLayout(),
    );
  }
}