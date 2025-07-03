import 'package:flutter/material.dart';

class InvalidAddressesPage extends StatefulWidget {
  const InvalidAddressesPage({super.key});

  @override
  State<InvalidAddressesPage> createState() => _InvalidAddressesPageState();
}

class _InvalidAddressesPageState extends State<InvalidAddressesPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = '全部';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 操作区域
            Row(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜索无效邮件地址',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // TODO: 实现搜索功能
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: const [
                    DropdownMenuItem(value: '全部', child: Text('全部')),
                    DropdownMenuItem(value: '格式错误', child: Text('格式错误')),
                    DropdownMenuItem(value: '域名无效', child: Text('域名无效')),
                    DropdownMenuItem(value: '邮箱不存在', child: Text('邮箱不存在')),
                    DropdownMenuItem(value: '被退回', child: Text('被退回')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? '全部';
                    });
                  },
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _exportInvalidAddresses,
                  icon: const Icon(Icons.download),
                  label: const Text('导出'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _clearInvalidAddresses,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('清空'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 统计信息
            Row(
              children: [
                _buildStatCard('总计', '0', Colors.grey),
                const SizedBox(width: 16),
                _buildStatCard('格式错误', '0', Colors.red),
                const SizedBox(width: 16),
                _buildStatCard('域名无效', '0', Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard('邮箱不存在', '0', Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('被退回', '0', Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            // 无效地址列表
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '无效地址列表',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.green[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无无效地址',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '系统会自动检测并记录无效的邮件地址',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportInvalidAddresses() {
    // TODO: 实现导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('导出无效地址功能开发中...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearInvalidAddresses() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有无效地址记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: 实现清空功能
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('清空无效地址功能开发中...'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 