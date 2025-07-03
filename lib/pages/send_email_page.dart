import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';

class SendEmailPage extends StatelessWidget {
  const SendEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发送邮件')),
      drawer: const AppDrawer(currentRoute: '/send-email'),
      body: const Center(
        child: Text('发送邮件功能开发中...'),
      ),
    );
  }
}