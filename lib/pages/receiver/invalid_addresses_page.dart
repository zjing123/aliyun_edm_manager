import 'package:flutter/material.dart';

class InvalidAddressesPage extends StatelessWidget {
  const InvalidAddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final invalidAddresses = [
      {'email': 'invalid@example.com', 'reason': '域名不存在', 'addTime': '2025-06-27 10:30:00'},
      {'email': 'test@', 'reason': '格式错误', 'addTime': '2025-06-26 15:20:00'},
      {'email': 'user@invalid.domain', 'reason': 'MX记录不存在', 'addTime': '2025-06-25 09:45:00'},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '无效地址',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
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
                        DataColumn(label: Text('邮箱地址')),
                        DataColumn(label: Text('无效原因')),
                        DataColumn(label: Text('添加时间')),
                        DataColumn(label: Text('操作')),
                      ],
                      rows: invalidAddresses
                          .map(
                            (address) => DataRow(
                              cells: [
                                DataCell(Text(address['email'] as String)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      address['reason'] as String,
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(address['addTime'] as String)),
                                DataCell(
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text('移除'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
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
}