import 'package:flutter/material.dart';

class EventDistributionPage extends StatelessWidget {
  const EventDistributionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '事件分发',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '事件订阅设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('发送成功'),
                    subtitle: const Text('邮件发送成功时触发'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  CheckboxListTile(
                    title: const Text('发送失败'),
                    subtitle: const Text('邮件发送失败时触发'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  CheckboxListTile(
                    title: const Text('邮件打开'),
                    subtitle: const Text('收件人打开邮件时触发'),
                    value: false,
                    onChanged: (value) {},
                  ),
                  CheckboxListTile(
                    title: const Text('链接点击'),
                    subtitle: const Text('收件人点击邮件中的链接时触发'),
                    value: false,
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Webhook URL',
                      hintText: '请输入接收事件的URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('保存设置'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}