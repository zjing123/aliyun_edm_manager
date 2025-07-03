import 'package:flutter/material.dart';

class SenderAddressPage extends StatefulWidget {
  const SenderAddressPage({super.key});

  @override
  State<SenderAddressPage> createState() => _SenderAddressPageState();
}

class _SenderAddressPageState extends State<SenderAddressPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发送地址'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: 实现添加发送地址功能
            },
            tooltip: '新建发送地址',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: 实现刷新功能
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '发送地址管理',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '管理邮件发送地址列表',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}