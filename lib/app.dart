import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/global_config_provider.dart';
import 'widgets/main_layout.dart';

class EDMApp extends StatefulWidget {
  const EDMApp({super.key});

  @override
  State<EDMApp> createState() => _EDMAppState();
}

class _EDMAppState extends State<EDMApp> {
  @override
  void initState() {
    super.initState();
    // 在应用启动时初始化全局配置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final globalConfig = context.read<GlobalConfigProvider>();
      globalConfig.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '阿里云EDM管理',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainLayout(),
    );
  }
}