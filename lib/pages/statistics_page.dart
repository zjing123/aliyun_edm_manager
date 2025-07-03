import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      drawer: const AppDrawer(currentRoute: '/statistics'),
      body: const Center(
        child: Text('数据统计功能开发中...'),
      ),
    );
  }
}