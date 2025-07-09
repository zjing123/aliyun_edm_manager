import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/sender_statistics/sender_statistics_provider.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/pages/sender_statistics/sending_details_page.dart';

class SendingDataPage extends StatefulWidget {
  const SendingDataPage({super.key});

  @override
  State<SendingDataPage> createState() => _SendingDataPageState();
}

class _SendingDataPageState extends State<SendingDataPage> {
  DateTime? _startTime;
  DateTime? _endTime;
  String? _selectedTagName;
  String? _selectedAccountName;

  @override
  void initState() {
    super.initState();
    // 设置默认时间范围为最近7天
    final now = DateTime.now();
    _startTime = now.subtract(const Duration(days: 7));
    _endTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final globalConfig = context.read<GlobalConfigProvider>();
        final provider = SenderStatisticsProvider(globalConfig);
        // 初始化时加载标签和地址数据
        provider.loadTags();
        provider.loadAddresses();
        // 加载最近7天的数据
        provider.loadStatistics(
          startTime: _startTime!,
          endTime: _endTime!,
        );
        return provider;
      },
      child: Consumer<SenderStatisticsProvider>(
        builder: (context, provider, child) {
          final summary = provider.getSummaryStatistics();
          
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
                        '发送数据',
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
                  const SizedBox(height: 24),
                  // 统计概览
                  Row(
                    children: [
                      _buildStatCard(
                        title: '总发送量',
                        value: '${summary['totalSent']}',
                        icon: Icons.email,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: '成功发送',
                        value: '${summary['successSent']}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: '失败发送',
                        value: '${summary['failedSent']}',
                        icon: Icons.error,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: '成功率',
                        value: '${summary['successRate'].toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 过滤组件
                  _buildFilterSection(context, provider),
                  const SizedBox(height: 24),
                  // 图表区域
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(24),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '发送趋势',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => _loadTrend(context, provider, 7),
                                  child: const Text('7天'),
                                ),
                                TextButton(
                                  onPressed: () => _loadTrend(context, provider, 30),
                                  child: const Text('30天'),
                                ),
                                TextButton(
                                  onPressed: () => _loadTrend(context, provider, 90),
                                  child: const Text('90天'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (provider.isLoading)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (provider.trend.isNotEmpty)
                          Expanded(
                            child: _buildTrendChart(provider),
                          )
                        else
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bar_chart,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '暂无趋势数据',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
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
                          color: Colors.black.withOpacity(0.05),
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
                                '发送数据列表',
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
                              child: _buildDataTable(provider),
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

  Widget _buildFilterSection(BuildContext context, SenderStatisticsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            '筛选条件',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 邮件标签
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '邮件标签',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _selectedTagName,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('全部'),
                    ),
                    ...provider.tags.map((tag) => DropdownMenuItem<String>(
                      value: tag.tagName,
                      child: Text(tag.tagName),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTagName = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // 发信地址
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '发信地址',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _selectedAccountName,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('全部'),
                    ),
                    ...provider.addresses.map((address) => DropdownMenuItem<String>(
                      value: address.accountName,
                      child: Text(address.accountName),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountName = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // 起始时间
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startTime ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startTime = date;
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
                      _startTime != null 
                          ? '${_startTime!.year}-${_startTime!.month.toString().padLeft(2, '0')}-${_startTime!.day.toString().padLeft(2, '0')}'
                          : '请选择日期',
                      style: TextStyle(
                        color: _startTime != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 结束时间
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endTime ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endTime = date;
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
                      _endTime != null 
                          ? '${_endTime!.year}-${_endTime!.month.toString().padLeft(2, '0')}-${_endTime!.day.toString().padLeft(2, '0')}'
                          : '请选择日期',
                      style: TextStyle(
                        color: _endTime != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 查询按钮
              SizedBox(
                width: 80,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    provider.setFilterParams(
                      tagName: _selectedTagName,
                      accountName: _selectedAccountName,
                      startTime: _startTime,
                      endTime: _endTime,
                    );
                    provider.applyFilters();
                  },
                  child: const Text('查询'),
                ),
              ),
              const SizedBox(width: 12),
              // 重置按钮
              SizedBox(
                width: 80,
                height: 40,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTagName = null;
                      _selectedAccountName = null;
                      _startTime = DateTime.now().subtract(const Duration(days: 7));
                      _endTime = DateTime.now();
                    });
                    provider.resetFilterParams();
                    provider.loadStatistics(
                      startTime: _startTime!,
                      endTime: _endTime!,
                    );
                  },
                  child: const Text('重置'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(SenderStatisticsProvider provider) {
    final records = provider.statistics?.records ?? [];
    
    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
      columns: const [
        DataColumn(label: Text('创建时间（UTC+8）')),
        DataColumn(label: Text('总数')),
        DataColumn(label: Text('成功')),
        DataColumn(label: Text('失败')),
        DataColumn(label: Text('无效地址')),
        DataColumn(label: Text('成功率')),
        DataColumn(label: Text('无效地址率')),
        DataColumn(label: Text('操作')),
      ],
      rows: records.map((record) => DataRow(
        cells: [
          DataCell(Text(_formatDateTime(record.createTime))),
          DataCell(Text(record.requestCount)),
          DataCell(Text(record.successCount)),
          DataCell(Text(record.faildCount)),
          DataCell(Text(record.unavailableCount)),
          DataCell(Text(record.succeededPercent)),
          DataCell(Text(record.unavailablePercent)),
          DataCell(
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SendingDetailsPage(),
                  ),
                );
              },
              child: const Text('详情'),
            ),
          ),
        ],
      )).toList(),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      // 假设API返回的时间格式为 yyyy-MM-dd HH:mm:ss
      final dateTime = DateTime.parse(dateTimeStr);
      // 转换为UTC+8时区
      final utc8Time = dateTime.add(const Duration(hours: 8));
      return '${utc8Time.year}-${utc8Time.month.toString().padLeft(2, '0')}-${utc8Time.day.toString().padLeft(2, '0')} ${utc8Time.hour.toString().padLeft(2, '0')}:${utc8Time.minute.toString().padLeft(2, '0')}:${utc8Time.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr; // 如果解析失败，返回原始字符串
    }
  }

  void _loadTrend(BuildContext context, SenderStatisticsProvider provider, int days) {
    provider.loadTrend(days: days);
  }

  Widget _buildTrendChart(SenderStatisticsProvider provider) {
    return ListView.builder(
      itemCount: provider.trend.length,
      itemBuilder: (context, index) {
        final trend = provider.trend[index];
        if (trend.records.isEmpty) return const SizedBox.shrink();
        
        final record = trend.records.first;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(record.createTime),
            subtitle: Text('成功: ${record.successCount}, 失败: ${record.faildCount}'),
            trailing: Text(
              record.succeededPercent,
              style: TextStyle(
                color: record.successRate >= 90 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}