import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';

class InvalidAddressPage extends StatelessWidget {
  const InvalidAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('无效地址')),
      drawer: const AppDrawer(currentRoute: '/invalid-address'),
      body: const Center(
        child: Text('无效地址功能开发中...'),
      ),
    );
  }
}