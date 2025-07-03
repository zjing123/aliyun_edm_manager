import 'package:flutter/material.dart';

class SendingDetailsPage extends StatelessWidget {
  const SendingDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sendingRecords = [
      {
        'recipient': 'user1@example.com',
        'subject': '欢迎注册我们的服务',
        'status': '已发送',
        'sendTime': '2025-06-27 10:30:00',
        'openTime': '2025-06-27 11:15:00',
      },
      {
        'recipient': 'user2@example.com',
        'subject': '密码重置提醒',
        'status': '已打开',
        'sendTime': '2025-06-27 09:45:00',
        'openTime': '2025-06-27 09:50:00',
      },
      {
        'recipient': 'user3@example.com',
        'subject': '订单确认',
        'status': '发送失败',
        'sendTime': '2025-06-27 08:20:00',
        'openTime': '-',
      },
      {
        'recipient': 'user4@example.com',
        'subject': '月度账单',
        'status': '已发送',
        'sendTime': '2025-06-26 18:00:00',
        'openTime': '-',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '发送详情',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 筛选栏
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '搜索收件人',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '状态',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('全部')),
                      DropdownMenuItem(value: 'sent', child: Text('已发送')),
                      DropdownMenuItem(value: 'opened', child: Text('已打开')),
                      DropdownMenuItem(value: 'failed', child: Text('发送失败')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('筛选'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 数据表格
            Expanded(
              child: Container(
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                      columns: const [
                        DataColumn(label: Text('收件人')),
                        DataColumn(label: Text('邮件主题')),
                        DataColumn(label: Text('状态')),
                        DataColumn(label: Text('发送时间')),
                        DataColumn(label: Text('打开时间')),
                        DataColumn(label: Text('操作')),
                      ],
                      rows: sendingRecords
                          .map(
                            (record) => DataRow(
                              cells: [
                                DataCell(Text(record['recipient'] as String)),
                                DataCell(Text(record['subject'] as String)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(record['status'] as String),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      record['status'] as String,
                                      style: TextStyle(
                                        color: _getStatusTextColor(record['status'] as String),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(record['sendTime'] as String)),
                                DataCell(Text(record['openTime'] as String)),
                                DataCell(
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text('详情'),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '已发送':
        return Colors.blue[50]!;
      case '已打开':
        return Colors.green[50]!;
      case '发送失败':
        return Colors.red[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case '已发送':
        return Colors.blue[700]!;
      case '已打开':
        return Colors.green[700]!;
      case '发送失败':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}