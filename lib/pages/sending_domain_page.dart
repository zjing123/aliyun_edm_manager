import 'package:flutter/material.dart';

class SendingDomainPage extends StatefulWidget {
  const SendingDomainPage({super.key});

  @override
  State<SendingDomainPage> createState() => _SendingDomainPageState();
}

class _SendingDomainPageState extends State<SendingDomainPage> {
  final List<Map<String, dynamic>> _domains = [
    {
      'domain': 'example.com',
      'status': '已验证',
      'type': 'DKIM',
      'createTime': '2025-06-27 10:30:00',
    },
    {
      'domain': 'mail.example.com',
      'status': '待验证',
      'type': 'SPF',
      'createTime': '2025-06-26 15:45:00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题和操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '发信域名',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddDomainDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新建发信域名'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
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
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                    columns: const [
                      DataColumn(label: Text('域名')),
                      DataColumn(label: Text('状态')),
                      DataColumn(label: Text('验证类型')),
                      DataColumn(label: Text('创建时间')),
                      DataColumn(label: Text('操作')),
                    ],
                    rows: _domains
                        .map(
                          (domain) => DataRow(
                            cells: [
                              DataCell(Text(domain['domain'])),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: domain['status'] == '已验证'
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    domain['status'],
                                    style: TextStyle(
                                      color: domain['status'] == '已验证'
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(domain['type'])),
                              DataCell(Text(domain['createTime'])),
                              DataCell(
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text('详情'),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text('删除'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
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
          ],
        ),
      ),
    );
  }

  void _showAddDomainDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建发信域名'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '域名',
                hintText: '请输入域名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '验证类型',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'DKIM', child: Text('DKIM')),
                DropdownMenuItem(value: 'SPF', child: Text('SPF')),
                DropdownMenuItem(value: 'DMARC', child: Text('DMARC')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 添加域名逻辑
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}