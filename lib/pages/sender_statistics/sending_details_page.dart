import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/sender_statistics/sender_statistics_provider.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_detail_model.dart';

class SendingDetailsPage extends StatelessWidget {
  const SendingDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final globalConfig = context.read<GlobalConfigProvider>();
        return SenderStatisticsProvider(globalConfig)..loadDetails();
      },
      child: Consumer<SenderStatisticsProvider>(
        builder: (context, provider, child) {
          final sendingRecords = provider.details;

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
                                      DataCell(Text(record.recipient)),
                                      DataCell(Text(record.subject)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(record.status),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            record.statusText,
                                            style: TextStyle(
                                              color: _getStatusTextColor(record.status),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(_formatDateTime(record.sendTime))),
                                      DataCell(Text(record.openTime != null 
                                          ? _formatDateTime(record.openTime!) 
                                          : '-')),
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
        },
      ),
    );
  }

  Color _getStatusColor(SendingStatus status) {
    switch (status) {
      case SendingStatus.sent:
        return Colors.blue[50]!;
      case SendingStatus.opened:
        return Colors.green[50]!;
      case SendingStatus.failed:
        return Colors.red[50]!;
    }
  }

  Color _getStatusTextColor(SendingStatus status) {
    switch (status) {
      case SendingStatus.sent:
        return Colors.blue[700]!;
      case SendingStatus.opened:
        return Colors.green[700]!;
      case SendingStatus.failed:
        return Colors.red[700]!;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}