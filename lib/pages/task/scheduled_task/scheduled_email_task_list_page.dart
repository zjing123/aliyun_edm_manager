import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/task/scheduled_email_task_provider.dart';
import 'package:aliyun_edm_manager/providers/receiver/receiver_list_provider.dart';
import 'package:aliyun_edm_manager/models/task/scheduled_email_task_model.dart';
import 'scheduled_email_task_create_page.dart';

class ScheduledEmailTaskListPage extends StatefulWidget {
  const ScheduledEmailTaskListPage({super.key});

  @override
  State<ScheduledEmailTaskListPage> createState() => _ScheduledEmailTaskListPageState();
}

class _ScheduledEmailTaskListPageState extends State<ScheduledEmailTaskListPage> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 同时加载定时发送邮件和收件人列表数据
      context.read<ScheduledEmailTaskProvider>().fetchTasks();
      context.read<ReceiverListProvider>().loadReceivers();
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
                  '定时发送邮件',
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
              child: Consumer<ScheduledEmailTaskProvider>(
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
                            '暂无定时发送邮件',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击"新建任务"开始创建您的第一个定时发送邮件',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTask(),
        backgroundColor: Colors.white.withOpacity(0.9),
        foregroundColor: Colors.blue,
        elevation: 4,
        child: const Icon(Icons.add),
        tooltip: '新建定时发送邮件任务',
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Consumer<ScheduledEmailTaskProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<Map<String, int>>(
          future: provider.getTaskStatistics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final stats = snapshot.data ?? {};
            
            return Row(
              children: [
                _buildStatCard('总任务', stats['total'] ?? 0, Icons.task, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('运行中', stats['processing'] ?? 0, Icons.play_circle, Colors.green),
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

  Widget _buildTaskCard(ScheduledEmailTaskModel task, ScheduledEmailTaskProvider provider) {
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
                _buildStatusChip(task),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('发件人', '${task.senderName} <${task.senderAddress}>'),
                ),
                Expanded(
                  child: Consumer<ReceiverListProvider>(
                    builder: (context, receiverProvider, child) {
                      return _buildInfoItem('收件人列表', _getReceiverListNames(task.receiverLists, receiverProvider));
                    },
                  ),
                ),
                Expanded(
                  child: Consumer<ReceiverListProvider>(
                    builder: (context, receiverProvider, child) {
                      return _buildInfoItem('收件人数量', '${_getTotalReceiverCount(task.receiverLists, receiverProvider)}');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeDisplay(task),
                ),
                _buildActionButtons(task, provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ScheduledEmailTaskModel task) {
    final now = DateTime.now();
    
    // 检查任务是否已过期
    final isExpired = task.scheduledStartTime != null && 
                      task.scheduledStartTime!.isBefore(now) && 
                      (task.status == 'pending' || task.status == 'paused');
    
    Color color;
    String text;
    IconData icon;
    
    // 如果任务过期，优先显示过期状态
    if (isExpired) {
      color = Colors.red;
      text = '已过期';
      icon = Icons.schedule_outlined;
    } else {
      // 根据任务状态显示
      switch (task.status) {
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

  Widget _buildActionButtons(ScheduledEmailTaskModel task, ScheduledEmailTaskProvider provider) {
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

  List<ScheduledEmailTaskModel> _getFilteredTasks(List<ScheduledEmailTaskModel> tasks) {
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
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _getTaskStartTimeText(ScheduledEmailTaskModel task) {
    // 如果有定时发送时间，直接显示时间
    if (task.scheduledStartTime != null) {
      return _formatDateTime(task.scheduledStartTime!);
    }
    
    // 如果任务已经开始，显示实际开始时间
    if (task.startedAt != null) {
      return _formatDateTime(task.startedAt!);
    }
    
    // 如果都没有，根据任务状态显示相应文本
    switch (task.status) {
      case 'pending':
        return '等待开始';
      case 'running':
        return '运行中';
      case 'completed':
        return '已完成';
      case 'failed':
        return '任务失败';
      case 'paused':
        return '已暂停';
      default:
        return '未知状态';
    }
  }

  Widget _buildTimeDisplay(ScheduledEmailTaskModel task) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;
    
    final createdTimeText = Text(
      '创建时间: ${_formatDateTime(task.createdAt)}',
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 12,
      ),
    );
    
    final startTimeText = Text(
      '任务开始时间: ${_getTaskStartTimeText(task)}',
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 12,
      ),
    );
    
    if (isWideScreen) {
      // 宽屏显示在一行
      return Row(
        children: [
          createdTimeText,
          const SizedBox(width: 24), // 增加间距
          startTimeText,
        ],
      );
    } else {
      // 窄屏分行显示
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          createdTimeText,
          const SizedBox(height: 4),
          startTimeText,
        ],
      );
    }
  }

  void _navigateToCreateTask() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ScheduledEmailTaskCreatePage(),
      ),
    );
  }

  void _startTask(String taskId, ScheduledEmailTaskProvider provider) async {
    final success = await provider.updateTaskStatus(taskId, 'running');
    if (success) {
      _showSnackBar('任务已开始');
    } else {
      _showSnackBar('启动任务失败', isError: true);
    }
  }

  void _pauseTask(String taskId, ScheduledEmailTaskProvider provider) async {
    final success = await provider.pauseTask(taskId);
    if (success) {
      _showSnackBar('任务已暂停');
    } else {
      _showSnackBar('暂停任务失败', isError: true);
    }
  }

  void _resumeTask(String taskId, ScheduledEmailTaskProvider provider) async {
    final success = await provider.resumeTask(taskId);
    if (success) {
      _showSnackBar('任务已恢复');
    } else {
      _showSnackBar('恢复任务失败', isError: true);
    }
  }

  void _stopTask(String taskId, ScheduledEmailTaskProvider provider) async {
    final success = await provider.stopTask(taskId);
    if (success) {
      _showSnackBar('任务已停止');
    } else {
      _showSnackBar('停止任务失败', isError: true);
    }
  }

  void _deleteTask(String taskId, ScheduledEmailTaskProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 警告图标
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red[600],
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              // 标题
              Text(
                '确认删除',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              // 内容
              Text(
                '确定要删除这个定时发送邮件吗？\n此操作不可恢复。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final success = await provider.deleteTask(taskId);
                        if (success) {
                          _showSnackBar('任务已删除');
                        } else {
                          _showSnackBar('删除任务失败', isError: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '删除',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewTaskDetail(ScheduledEmailTaskModel task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 500,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '任务详情',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  ),
                ),
                // 内容区域
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem('任务名称', task.taskName),
                        _buildDetailItem('模板名称', task.templateName),
                        _buildDetailItem('发送方地址', task.senderAddress),
                        _buildDetailItem('发送方名称', task.senderName),
                        Consumer<ReceiverListProvider>(
                          builder: (context, receiverProvider, child) {
                            return _buildDetailItem('收件人列表', _getReceiverListNames(task.receiverLists, receiverProvider));
                          },
                        ),
                        Consumer<ReceiverListProvider>(
                          builder: (context, receiverProvider, child) {
                            return _buildDetailItem('收件人数量', '${_getTotalReceiverCount(task.receiverLists, receiverProvider)}');
                          },
                        ),
                        _buildDetailItem('发送类型', task.senderType == '0' ? '随机发送' : '固定发送'),
                        if (task.tag != null && task.tag!.isNotEmpty)
                          _buildDetailItem('标签', task.tag!),
                        _buildDetailItem('启用追踪', task.enableTracking ? '是' : '否'),
                        _buildDetailItem('任务状态', _getStatusText(task.status)),
                        _buildDetailItem('创建时间', _formatDateTime(task.createdAt)),
                        if (task.scheduledStartTime != null)
                          _buildDetailItem('定时发送时间', _formatDateTime(task.scheduledStartTime!)),
                        if (task.startedAt != null)
                          _buildDetailItem('开始时间', _formatDateTime(task.startedAt!)),
                        if (task.completedAt != null)
                          _buildDetailItem('完成时间', _formatDateTime(task.completedAt!)),
                        if (task.sendIntervalMinutes != null)
                          _buildDetailItem('发送间隔', '${task.sendIntervalMinutes}分钟'),
                        if (task.errorMessage != null && task.errorMessage!.isNotEmpty)
                          _buildDetailItem('错误信息', task.errorMessage!, isError: true),
                      ],
                    ),
                  ),
                ),
                // 按钮区域
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _editTask(task);
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('编辑'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[600],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteTask(task.taskId, Provider.of<ScheduledEmailTaskProvider>(context, listen: false));
                        },
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('删除'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[600],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isError ? Colors.red[600] : Colors.grey[800],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '等待中';
      case 'running':
        return '运行中';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      case 'paused':
        return '已暂停';
      default:
        return '未知';
    }
  }

  void _editTask(ScheduledEmailTaskModel task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScheduledEmailTaskCreatePage(taskToEdit: task),
      ),
    );
  }

  // 获取收件人列表名称
  String _getReceiverListNames(List<ReceiverListConfig> receiverLists, ReceiverListProvider receiverListProvider) {
    if (receiverLists.isEmpty) {
      return '无收件人列表';
    }
    
    // 调试信息
    print('收件人列表配置数量: ${receiverLists.length}');
    print('可用收件人列表数量: ${receiverListProvider.receivers.length}');
    
    if (receiverLists.length == 1) {
      // 单个列表，通过ID查找真实名称
      final list = receiverLists.first;
      print('查找收件人ID: ${list.receiverId}');
      
      final realReceiver = receiverListProvider.findReceiverById(list.receiverId);
      if (realReceiver != null) {
        print('找到真实收件人列表: ${realReceiver.receiversName}');
        return realReceiver.receiversName;
      }
      
      print('未找到真实收件人列表，使用备用名称');
      // 如果找不到，使用备用名称
      return list.listName?.isNotEmpty == true ? list.listName! : list.receiverName;
    } else {
      // 多个列表，显示第一个列表名称 + 数量
      final firstList = receiverLists.first;
      print('查找第一个收件人ID: ${firstList.receiverId}');
      
      final realReceiver = receiverListProvider.findReceiverById(firstList.receiverId);
      String firstName;
      if (realReceiver != null) {
        firstName = realReceiver.receiversName;
        print('找到第一个真实收件人列表: $firstName');
      } else {
        firstName = firstList.listName?.isNotEmpty == true 
            ? firstList.listName! 
            : firstList.receiverName;
        print('使用第一个备用名称: $firstName');
      }
      return '$firstName 等${receiverLists.length}个列表';
    }
  }

  // 获取总收件人数量
  int _getTotalReceiverCount(List<ReceiverListConfig> receiverLists, ReceiverListProvider receiverListProvider) {
    if (receiverLists.isEmpty) {
      return 0;
    }
    
    return receiverLists.fold<int>(0, (total, list) {
      // 优先使用真实的收件人列表数据
      final realReceiver = receiverListProvider.findReceiverById(list.receiverId);
      if (realReceiver != null) {
        return total + realReceiver.count;
      }
      // 如果找不到真实数据，使用任务配置中的数据
      return total + (list.receiverCount ?? list.emailCount);
    });
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