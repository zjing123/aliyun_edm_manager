import 'package:flutter/material.dart';

class SendDetailsPage extends StatefulWidget {
  const SendDetailsPage({super.key});

  @override
  State<SendDetailsPage> createState() => _SendDetailsPageState();
}

class _SendDetailsPageState extends State<SendDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 筛选区域
            Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '搜索邮件主题或收件人',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // TODO: 实现搜索功能
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: '全部状态',
                  items: const [
                    DropdownMenuItem(value: '全部状态', child: Text('全部状态')),
                    DropdownMenuItem(value: '发送成功', child: Text('发送成功')),
                    DropdownMenuItem(value: '发送失败', child: Text('发送失败')),
                    DropdownMenuItem(value: '发送中', child: Text('发送中')),
                  ],
                  onChanged: (value) {
                    // TODO: 实现状态筛选
                  },
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 实现导出功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('导出功能开发中...')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('导出'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 发送详情列表
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '发送详情列表',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mail_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无发送记录',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '发送邮件后，详情记录将在这里显示',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 