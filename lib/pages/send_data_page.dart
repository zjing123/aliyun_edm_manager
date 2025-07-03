import 'package:flutter/material.dart';

class SendDataPage extends StatefulWidget {
  const SendDataPage({super.key});

  @override
  State<SendDataPage> createState() => _SendDataPageState();
}

class _SendDataPageState extends State<SendDataPage> {
  String _selectedPeriod = '今天';
  
  // 模拟发送数据
  final Map<String, Map<String, int>> _sendData = {
    '今天': {
      '总发送': 1234,
      '成功发送': 1180,
      '发送失败': 54,
      '退信数量': 12,
      '打开率': 68,
      '点击率': 23,
    },
    '昨天': {
      '总发送': 2156,
      '成功发送': 2089,
      '发送失败': 67,
      '退信数量': 18,
      '打开率': 72,
      '点击率': 31,
    },
    '本周': {
      '总发送': 8765,
      '成功发送': 8432,
      '发送失败': 333,
      '退信数量': 87,
      '打开率': 65,
      '点击率': 28,
    },
    '本月': {
      '总发送': 34521,
      '成功发送': 33245,
      '发送失败': 1276,
      '退信数量': 456,
      '打开率': 58,
      '点击率': 25,
    },
  };

  final List<Map<String, dynamic>> _recentSends = [
    {
      'time': '2025-01-15 14:30:00',
      'subject': '春季新品发布通知',
      'recipient': '营销列表1',
      'count': 1500,
      'success': 1432,
      'failed': 68,
      'status': '已完成',
    },
    {
      'time': '2025-01-15 10:15:00',
      'subject': '会员积分到期提醒',
      'recipient': '会员列表',
      'count': 856,
      'success': 823,
      'failed': 33,
      'status': '已完成',
    },
    {
      'time': '2025-01-14 16:45:00',
      'subject': '系统维护通知',
      'recipient': '全员列表',
      'count': 2341,
      'success': 2301,
      'failed': 40,
      'status': '已完成',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentData = _sendData[_selectedPeriod] ?? {};
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('发送数据'),
        automaticallyImplyLeading: false,
        actions: [
          DropdownButton<String>(
            value: _selectedPeriod,
            items: _sendData.keys.map((period) {
              return DropdownMenuItem(
                value: period,
                child: Text(period),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPeriod = value;
                });
              }
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: 实现刷新功能
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 统计卡片区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_selectedPeriod 发送统计',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '总发送',
                            currentData['总发送']?.toString() ?? '0',
                            Icons.send,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            '成功发送',
                            currentData['成功发送']?.toString() ?? '0',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            '发送失败',
                            currentData['发送失败']?.toString() ?? '0',
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '退信数量',
                            currentData['退信数量']?.toString() ?? '0',
                            Icons.reply,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            '打开率',
                            '${currentData['打开率'] ?? 0}%',
                            Icons.visibility,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            '点击率',
                            '${currentData['点击率'] ?? 0}%',
                            Icons.mouse,
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 最近发送记录
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '最近发送记录',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('发送时间')),
                              DataColumn(label: Text('邮件主题')),
                              DataColumn(label: Text('收件人列表')),
                              DataColumn(label: Text('发送数量')),
                              DataColumn(label: Text('成功/失败')),
                              DataColumn(label: Text('状态')),
                              DataColumn(label: Text('操作')),
                            ],
                            rows: _recentSends.map((record) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(record['time'] ?? '')),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        record['subject'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(record['recipient'] ?? '')),
                                  DataCell(Text(record['count']?.toString() ?? '')),
                                  DataCell(
                                    Text('${record['success']}/${record['failed']}'),
                                  ),
                                  DataCell(
                                    Chip(
                                      label: Text(record['status'] ?? ''),
                                      backgroundColor: Colors.green[100],
                                      labelStyle: TextStyle(
                                        color: Colors.green[800],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/send-details',
                                          arguments: record,
                                        );
                                      },
                                      child: const Text('查看详情'),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}