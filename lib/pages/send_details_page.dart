import 'package:flutter/material.dart';

class SendDetailsPage extends StatefulWidget {
  const SendDetailsPage({super.key});

  @override
  State<SendDetailsPage> createState() => _SendDetailsPageState();
}

class _SendDetailsPageState extends State<SendDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 模拟详细发送记录
  final List<Map<String, dynamic>> _detailRecords = [
    {
      'email': 'user1@example.com',
      'status': '发送成功',
      'sendTime': '2025-01-15 14:30:12',
      'deliverTime': '2025-01-15 14:30:15',
      'openTime': '2025-01-15 15:20:30',
      'clickTime': '2025-01-15 15:25:45',
      'isOpened': true,
      'isClicked': true,
    },
    {
      'email': 'user2@example.com',
      'status': '发送成功',
      'sendTime': '2025-01-15 14:30:13',
      'deliverTime': '2025-01-15 14:30:16',
      'openTime': '2025-01-15 16:10:20',
      'clickTime': null,
      'isOpened': true,
      'isClicked': false,
    },
    {
      'email': 'user3@example.com',
      'status': '发送失败',
      'sendTime': '2025-01-15 14:30:14',
      'deliverTime': null,
      'openTime': null,
      'clickTime': null,
      'isOpened': false,
      'isClicked': false,
      'errorMsg': '邮箱地址无效',
    },
    // 更多记录...
  ];

  final List<Map<String, dynamic>> _errorRecords = [
    {
      'email': 'invalid@invalid-domain.com',
      'errorType': '域名不存在',
      'errorMsg': 'DNS解析失败，域名不存在',
      'attemptTime': '2025-01-15 14:30:14',
    },
    {
      'email': 'bounce@example.com',
      'errorType': '邮箱满',
      'errorMsg': '收件人邮箱已满，无法接收邮件',
      'attemptTime': '2025-01-15 14:30:20',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('发送详情'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: 实现导出功能
            },
            tooltip: '导出数据',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '发送概览'),
            Tab(text: '详细记录'),
            Tab(text: '错误记录'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(args),
          _buildDetailTab(),
          _buildErrorTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic>? args) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 基本信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '发送基本信息',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem('邮件主题', args?['subject'] ?? '春季新品发布通知'),
                      ),
                      Expanded(
                        child: _buildInfoItem('收件人列表', args?['recipient'] ?? '营销列表1'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem('发送时间', args?['time'] ?? '2025-01-15 14:30:00'),
                      ),
                      Expanded(
                        child: _buildInfoItem('发送状态', args?['status'] ?? '已完成'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 统计数据卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '发送统计',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('总发送量', args?['count']?.toString() ?? '1500', Icons.send, Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('成功发送', args?['success']?.toString() ?? '1432', Icons.check_circle, Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('发送失败', args?['failed']?.toString() ?? '68', Icons.error, Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('已打开', '876', Icons.visibility, Colors.purple),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('已点击', '234', Icons.mouse, Colors.teal),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('打开率', '61.2%', Icons.analytics, Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    '详细发送记录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    hint: const Text('筛选状态'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('全部')),
                      DropdownMenuItem(value: 'success', child: Text('成功')),
                      DropdownMenuItem(value: 'failed', child: Text('失败')),
                      DropdownMenuItem(value: 'opened', child: Text('已打开')),
                      DropdownMenuItem(value: 'clicked', child: Text('已点击')),
                    ],
                    onChanged: (value) {
                      // TODO: 实现筛选功能
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('邮箱地址')),
                    DataColumn(label: Text('发送状态')),
                    DataColumn(label: Text('发送时间')),
                    DataColumn(label: Text('送达时间')),
                    DataColumn(label: Text('打开时间')),
                    DataColumn(label: Text('点击时间')),
                  ],
                  rows: _detailRecords.map((record) {
                    return DataRow(
                      cells: [
                        DataCell(Text(record['email'] ?? '')),
                        DataCell(
                          Chip(
                            label: Text(record['status'] ?? ''),
                            backgroundColor: record['status'] == '发送成功'
                                ? Colors.green[100]
                                : Colors.red[100],
                            labelStyle: TextStyle(
                              color: record['status'] == '发送成功'
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(Text(record['sendTime'] ?? '')),
                        DataCell(Text(record['deliverTime'] ?? '-')),
                        DataCell(Text(record['openTime'] ?? '-')),
                        DataCell(Text(record['clickTime'] ?? '-')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '错误记录',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('邮箱地址')),
                    DataColumn(label: Text('错误类型')),
                    DataColumn(label: Text('错误信息')),
                    DataColumn(label: Text('尝试时间')),
                  ],
                  rows: _errorRecords.map((record) {
                    return DataRow(
                      cells: [
                        DataCell(Text(record['email'] ?? '')),
                        DataCell(
                          Chip(
                            label: Text(record['errorType'] ?? ''),
                            backgroundColor: Colors.red[100],
                            labelStyle: TextStyle(
                              color: Colors.red[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 200,
                            child: Text(
                              record['errorMsg'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(record['attemptTime'] ?? '')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}