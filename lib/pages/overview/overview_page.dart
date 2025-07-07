import 'package:flutter/material.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '概览',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // 统计卡片
            Row(
              children: [
                _buildStatCard(
                  title: '今日发送',
                  value: '12,345',
                  icon: Icons.send,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: '成功率',
                  value: '98.5%',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: '收件人总数',
                  value: '456,789',
                  icon: Icons.people,
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: '模板数量',
                  value: '23',
                  icon: Icons.description,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // 快速操作
            const Text(
              '快速操作',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildQuickAction(
                  context,
                  title: '新建收件人列表',
                  icon: Icons.group_add,
                  onTap: () {},
                ),
                _buildQuickAction(
                  context,
                  title: '发送邮件',
                  icon: Icons.email,
                  onTap: () {},
                ),
                _buildQuickAction(
                  context,
                  title: '创建模板',
                  icon: Icons.text_snippet,
                  onTap: () {},
                ),
                _buildQuickAction(
                  context,
                  title: '查看报告',
                  icon: Icons.analytics,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
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
              color: Colors.black.withOpacity(0.05),
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
                Icon(icon, color: color, size: 24),
                Icon(Icons.trending_up, color: Colors.green[400], size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
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

  Widget _buildQuickAction(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}