import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/sender_statistics/sender_statistics_provider.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_detail_model.dart';

class SendingDetailsPage extends StatefulWidget {
  const SendingDetailsPage({super.key});

  @override
  State<SendingDetailsPage> createState() => _SendingDetailsPageState();
}

class _SendingDetailsPageState extends State<SendingDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final globalConfig = context.read<GlobalConfigProvider>();
        final provider = SenderStatisticsProvider(globalConfig);
        // 初始化时加载详情数据
        provider.loadDetails();
        return provider;
      },
      child: Consumer<SenderStatisticsProvider>(
        builder: (context, provider, child) {
          final sendingRecords = provider.details;

          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '发送详情',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (provider.error != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            provider.error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 筛选栏
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // 根据屏幕宽度动态调整控件宽度
                      final screenWidth = constraints.maxWidth;
                      final isLargeScreen = screenWidth > 1500;
                      final itemWidth = isLargeScreen ? 300.0 : 200.0;
                      final maxContainerWidth = isLargeScreen ? 1400.0 : screenWidth * 0.98;
                      
                      return Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContainerWidth),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: itemWidth,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    labelText: '搜索收件人',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: '状态',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  value: _selectedStatus,
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('全部')),
                                    DropdownMenuItem(value: 'sent', child: Text('已发送')),
                                    DropdownMenuItem(value: 'opened', child: Text('已打开')),
                                    DropdownMenuItem(value: 'failed', child: Text('发送失败')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedStatus = value;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate ?? DateTime.now(),
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _startDate = date;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: '起始时间',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      _startDate != null 
                                          ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                                          : '请选择日期',
                                      style: TextStyle(
                                        color: _startDate != null ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate ?? DateTime.now(),
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _endDate = date;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: '结束时间',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      _endDate != null 
                                          ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                                          : '请选择日期',
                                      style: TextStyle(
                                        color: _endDate != null ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 72,
                                height: 40,
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _selectedStatus = null;
                                      _startDate = null;
                                      _endDate = null;
                                    });
                                    provider.loadDetails();
                                  },
                                  child: const Text('重置'),
                                ),
                              ),
                              SizedBox(
                                width: 72,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final recipient = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
                                    final status = _selectedStatus == null ? null : _parseStatus(_selectedStatus!);
                                    
                                    provider.loadDetails(
                                      recipient: recipient,
                                      status: status,
                                      startDate: _startDate,
                                      endDate: _endDate,
                                    );
                                  },
                                  child: const Text('筛选'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // 数据表格
                  Container(
                    height: 400, // 固定高度
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '发送详情列表',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (provider.isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
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
                                              onPressed: () {
                                                // TODO: 实现单个邮件详情查看
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('邮件详情功能开发中...'),
                                                  ),
                                                );
                                              },
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
                      ],
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

  SendingStatus? _parseStatus(String status) {
    switch (status) {
      case 'sent':
        return SendingStatus.sent;
      case 'opened':
        return SendingStatus.opened;
      case 'failed':
        return SendingStatus.failed;
      default:
        return null;
    }
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