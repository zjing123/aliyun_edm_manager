import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/sender_statistics/sender_statistics_provider.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';

class SendingDataPage extends StatelessWidget {
  const SendingDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final globalConfig = context.read<GlobalConfigProvider>();
        final provider = SenderStatisticsProvider(globalConfig);
        // 加载最近7天的数据
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        provider.loadStatistics(
          startTime: sevenDaysAgo,
          endTime: now,
        );
        return provider;
      },
      child: Consumer<SenderStatisticsProvider>(
        builder: (context, provider, child) {
          final summary = provider.getSummaryStatistics();
          
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: Padding(
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
                  // 图表区域
                  Expanded(
                    child: Container(
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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