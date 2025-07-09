import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/track/track_provider.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/models/track/track_model.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';

class TrackDataPage extends StatefulWidget {
  const TrackDataPage({super.key});

  @override
  State<TrackDataPage> createState() => _TrackDataPageState();
}

class _TrackDataPageState extends State<TrackDataPage> {
  DateTime? _startTime;
  DateTime? _endTime;
  String? _selectedTagName;
  String? _selectedAccountName;

  @override
  void initState() {
    super.initState();
    // 设置默认时间范围（最近7天）
    final now = DateTime.now();
    _endTime = now;
    _startTime = now.subtract(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final globalConfig = context.read<GlobalConfigProvider>();
        final serviceManager = AliyunServiceManager();
        serviceManager.initialize(globalConfig);
        final provider = TrackProvider(serviceManager);
        // 初始化数据
        provider.initialize();
        return provider;
      },
      child: Consumer<TrackProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 页面标题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '跟踪数据',
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
                  
                  // 过滤组件
                  _buildFilterSection(provider),
                  const SizedBox(height: 24),
                  
                  // 统计概览
                  _buildStatisticsCards(provider),
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
                        const Text(
                          '跟踪趋势',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (provider.isLoading)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (provider.trackList.isNotEmpty)
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
                                    '暂无跟踪数据',
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
                    height: 400,
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
                              '跟踪数据列表',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '共 ${provider.total} 条记录',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
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
                        else
                          Expanded(
                            child: _buildDataTable(provider),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // 底部间距，确保内容完全可见
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(TrackProvider provider) {
    return Container(
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
          const Text(
            '过滤条件',
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
                      child: Text('全部', overflow: TextOverflow.ellipsis),
                    ),
                    ...provider.emailTags.map((tag) => DropdownMenuItem<String>(
                      value: tag.tagName,
                      child: Text(
                        tag.tagName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTagName = value;
                    });
                  },
                  isExpanded: true,
                  menuMaxHeight: 200,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: 20,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(8),
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
                      child: Text('全部', overflow: TextOverflow.ellipsis),
                    ),
                    ...provider.senderAddresses.map((address) => DropdownMenuItem<String>(
                      value: address.accountName,
                      child: Text(
                        address.accountName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountName = value;
                    });
                  },
                  isExpanded: true,
                  menuMaxHeight: 200,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: 20,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(8),
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
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
                    ),
                    child: Text(
                      _startTime != null
                          ? '${_startTime!.year}-${_startTime!.month.toString().padLeft(2, '0')}-${_startTime!.day.toString().padLeft(2, '0')}'
                          : '请选择',
                      overflow: TextOverflow.ellipsis,
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
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
                    ),
                    child: Text(
                      _endTime != null
                          ? '${_endTime!.year}-${_endTime!.month.toString().padLeft(2, '0')}-${_endTime!.day.toString().padLeft(2, '0')}'
                          : '请选择',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 查询按钮
              SizedBox(
                width: 80,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // 验证时间范围
                    if (!provider.isValidTimeRange(_startTime, _endTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('时间范围不能超过7天，请重新选择'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    provider.setFilters(
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
              
              const SizedBox(width: 8),
              
              // 重置按钮
              SizedBox(
                width: 80,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTagName = null;
                      _selectedAccountName = null;
                      _startTime = null;
                      _endTime = null;
                    });
                    provider.resetFilters();
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

  Widget _buildStatisticsCards(TrackProvider provider) {
    final stats = provider.statistics;
    final totalSent = stats['totalSent'] ?? 0;
    final totalOpened = stats['totalOpened'] ?? 0;
    final totalClicked = stats['totalClicked'] ?? 0;
    final openRate = stats['openRate'] ?? 0.0;
    final clickRate = stats['clickRate'] ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: '总发送量',
            value: '$totalSent',
            icon: Icons.email,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: '总打开量',
            value: '$totalOpened',
            icon: Icons.visibility,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: '总点击量',
            value: '$totalClicked',
            icon: Icons.touch_app,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: '打开率',
            value: '${openRate.toStringAsFixed(2)}%',
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: '点击率',
            value: '${clickRate.toStringAsFixed(2)}%',
            icon: Icons.trending_up,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
    );
  }

  Widget _buildTrendChart(TrackProvider provider) {
    return ListView.builder(
      itemCount: provider.trackList.length,
      itemBuilder: (context, index) {
        final record = provider.trackList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(provider.formatDateTime(record.createTime)),
            subtitle: Text('发送: ${record.totalNumber}, 打开: ${record.rcptOpenCount}, 点击: ${record.rcptClickCount}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '打开率: ${provider.formatPercentage(record.rcptOpenRate)}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '点击率: ${provider.formatPercentage(record.rcptClickRate)}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(TrackProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          columns: const [
            DataColumn(label: Text('创建时间（UTC+8）')),
            DataColumn(label: Text('点击量')),
            DataColumn(label: Text('点击率')),
            DataColumn(label: Text('独立打开数')),
            DataColumn(label: Text('独立打开率')),
            DataColumn(label: Text('独立点击数')),
            DataColumn(label: Text('独立点击率')),
            DataColumn(label: Text('打开量')),
            DataColumn(label: Text('打开率')),
            DataColumn(label: Text('总数')),
            DataColumn(label: Text('操作')),
          ],
          rows: provider.trackList.map((record) => DataRow(
            cells: [
              DataCell(Text(provider.formatDateTime(record.createTime))),
              DataCell(Text(record.rcptClickCount)),
              DataCell(Text(provider.formatPercentage(record.rcptClickRate))),
              DataCell(Text(record.rcptUniqueOpenCount)),
              DataCell(Text(provider.formatPercentage(record.rcptUniqueOpenRate))),
              DataCell(Text(record.rcptUniqueClickCount)),
              DataCell(Text(provider.formatPercentage(record.rcptUniqueClickRate))),
              DataCell(Text(record.rcptOpenCount)),
              DataCell(Text(provider.formatPercentage(record.rcptOpenRate))),
              DataCell(Text(record.totalNumber)),
              DataCell(
                TextButton(
                  onPressed: () {
                    // TODO: 实现详情查看功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('详情功能开发中...')),
                    );
                  },
                  child: const Text('详情'),
                ),
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }
}