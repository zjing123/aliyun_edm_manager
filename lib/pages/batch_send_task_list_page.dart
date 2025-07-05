import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/batch_send_task_provider.dart';
import '../models/batch_send_task_model.dart';
import 'batch_send_task_create_page.dart';

class BatchSendTaskListPage extends StatefulWidget {
  const BatchSendTaskListPage({super.key});

  @override
  State<BatchSendTaskListPage> createState() => _BatchSendTaskListPageState();
}

class _BatchSendTaskListPageState extends State<BatchSendTaskListPage> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BatchSendTaskProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  '批量发送任务',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreateTask(),
                  icon: const Icon(Icons.add),
                  label: const Text('新建任务'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildStatisticsCards(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<BatchSendTaskProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            '加载失败: ${provider.error}',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.fetchTasks(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredTasks = _getFilteredTasks(provider.tasks);
                  
                  if (filteredTasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '暂无批量发送任务',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击"新建任务"开始创建您的第一个批量发送任务',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(filteredTasks[index], provider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Consumer<BatchSendTaskProvider>(
      builder: (context, provider, child) {
        final stats = provider.getTaskStatistics();
        
        return Row(
          children: [
            _buildStatCard('总任务', stats['total'] ?? 0, Icons.task, Colors.blue),
            const SizedBox(width: 16),
            _buildStatCard('运行中', stats['running'] ?? 0, Icons.play_circle, Colors.green),
            const SizedBox(width: 16),
            _buildStatCard('已完成', stats['completed'] ?? 0, Icons.check_circle, Colors.orange),
            const SizedBox(width: 16),
            _buildStatCard('已暂停', stats['paused'] ?? 0, Icons.pause_circle, Colors.yellow),
            const SizedBox(width: 16),
            _buildStatCard('失败', stats['failed'] ?? 0, Icons.error, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索任务名称、模板名称或发件人',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: '状态筛选',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: _statusFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('全部状态')),
              DropdownMenuItem(value: 'pending', child: Text('等待中')),
              DropdownMenuItem(value: 'running', child: Text('运行中')),
              DropdownMenuItem(value: 'completed', child: Text('已完成')),
              DropdownMenuItem(value: 'failed', child: Text('失败')),
              DropdownMenuItem(value: 'paused', child: Text('已暂停')),
            ],
            onChanged: (value) {
              setState(() {
                _statusFilter = value ?? 'all';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(BatchSendTaskModel task, BatchSendTaskProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.taskName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '模板: ${task.templateName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(task.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('发件人', '${task.senderName} <${task.senderAddress}>'),
                ),
                Expanded(
                  child: _buildInfoItem('收件人列表', '${task.receiverLists.length} 个列表'),
                ),
                Expanded(
                  child: _buildInfoItem('总邮件数', '${task.totalEmails}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(task),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '创建时间: ${_formatDateTime(task.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
                _buildActionButtons(task, provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.blue;
        text = '等待中';
        icon = Icons.schedule;
        break;
      case 'running':
        color = Colors.green;
        text = '运行中';
        icon = Icons.play_circle;
        break;
      case 'completed':
        color = Colors.orange;
        text = '已完成';
        icon = Icons.check_circle;
        break;
      case 'failed':
        color = Colors.red;
        text = '失败';
        icon = Icons.error;
        break;
      case 'paused':
        color = Colors.yellow;
        text = '已暂停';
        icon = Icons.pause_circle;
        break;
      default:
        color = Colors.grey;
        text = '未知';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BatchSendTaskModel task) {
    final progress = task.totalEmails > 0 ? task.sentEmails / task.totalEmails : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '发送进度',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              '${task.sentEmails}/${task.totalEmails} (${(progress * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            task.status == 'failed' ? Colors.red : Colors.blue,
          ),
        ),
        if (task.failedEmails > 0) ...[
          const SizedBox(height: 4),
          Text(
            '失败: ${task.failedEmails}',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BatchSendTaskModel task, BatchSendTaskProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.status == 'pending') ...[
          TextButton.icon(
            onPressed: () => _startTask(task.taskId, provider),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('开始'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ] else if (task.status == 'running') ...[
          TextButton.icon(
            onPressed: () => _pauseTask(task.taskId, provider),
            icon: const Icon(Icons.pause, size: 16),
            label: const Text('暂停'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _stopTask(task.taskId, provider),
            icon: const Icon(Icons.stop, size: 16),
            label: const Text('停止'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ] else if (task.status == 'paused') ...[
          TextButton.icon(
            onPressed: () => _resumeTask(task.taskId, provider),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('恢复'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ],
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _viewTaskDetail(task),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('详情'),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _deleteTask(task.taskId, provider),
          icon: const Icon(Icons.delete, size: 16),
          label: const Text('删除'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }

  List<BatchSendTaskModel> _getFilteredTasks(List<BatchSendTaskModel> tasks) {
    var filtered = tasks;

    // 状态筛选
    if (_statusFilter != 'all') {
      filtered = filtered.where((task) => task.status == _statusFilter).toList();
    }

    // 搜索筛选
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.taskName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               task.templateName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               task.senderName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToCreateTask() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BatchSendTaskCreatePage(),
      ),
    );
  }

  void _startTask(String taskId, BatchSendTaskProvider provider) async {
    final success = await provider.updateTaskStatus(taskId, 'running');
    if (success) {
      _showSnackBar('任务已开始');
    } else {
      _showSnackBar('启动任务失败', isError: true);
    }
  }

  void _pauseTask(String taskId, BatchSendTaskProvider provider) async {
    final success = await provider.pauseTask(taskId);
    if (success) {
      _showSnackBar('任务已暂停');
    } else {
      _showSnackBar('暂停任务失败', isError: true);
    }
  }

  void _resumeTask(String taskId, BatchSendTaskProvider provider) async {
    final success = await provider.resumeTask(taskId);
    if (success) {
      _showSnackBar('任务已恢复');
    } else {
      _showSnackBar('恢复任务失败', isError: true);
    }
  }

  void _stopTask(String taskId, BatchSendTaskProvider provider) async {
    final success = await provider.stopTask(taskId);
    if (success) {
      _showSnackBar('任务已停止');
    } else {
      _showSnackBar('停止任务失败', isError: true);
    }
  }

  void _deleteTask(String taskId, BatchSendTaskProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个批量发送任务吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await provider.deleteTask(taskId);
              if (success) {
                _showSnackBar('任务已删除');
              } else {
                _showSnackBar('删除任务失败', isError: true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _viewTaskDetail(BatchSendTaskModel task) {
    // TODO: 实现任务详情页面
    _showSnackBar('任务详情功能开发中...');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 