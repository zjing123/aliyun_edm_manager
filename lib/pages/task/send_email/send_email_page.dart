import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/task/mail_task_provider.dart';
import 'package:aliyun_edm_manager/models/task/mail_task_model.dart';
import 'package:aliyun_edm_manager/pages/config/config_page.dart';
import 'send_email_create_page.dart';

// 表格渲染性能优化说明：
// 1. 使用 _buildOptimizedTaskList() 替代原来的 _buildTaskList()
// 2. 表格内容使用 Selector<MailTaskProvider, List<MailTaskModel>> 只监听任务数据变化
// 3. 表格头部复选框使用 Selector<MailTaskProvider, bool> 只监听选择状态变化
// 4. 每个表格行的复选框使用 Selector 只监听该行的选择状态变化
// 5. 这样在翻页时，只有表格内容会重新渲染，表格头部和分页控件不会重新渲染

// 任务列表状态封装类
class _TaskListState {
  final bool isLoading;
  final String? error;
  final bool tasksEmpty;
  final bool hasExistingTasks;

  _TaskListState({
    required this.isLoading,
    required this.error,
    required this.tasksEmpty,
    required this.hasExistingTasks,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TaskListState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.tasksEmpty == tasksEmpty &&
        other.hasExistingTasks == hasExistingTasks;
  }

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode ^ tasksEmpty.hashCode ^ hasExistingTasks.hashCode;
}

class SendEmailPage extends StatefulWidget {
  const SendEmailPage({super.key});

  @override
  State<SendEmailPage> createState() => _SendEmailPageState();
}

class _SendEmailPageState extends State<SendEmailPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MailTaskProvider>().forceRefresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MailTaskProvider>().forceRefresh();
    });
  }

  void _reloadList() {
    context.read<MailTaskProvider>().forceRefresh();
  }

  void _openConfigPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ConfigPage()),
    );
    
    if (result == true) {
      _reloadList();
    }
  }

  void _showCreateDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SendEmailCreatePage()),
    ).then((_) {
      // 返回时刷新列表
      _reloadList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildPage();
  }

  Widget _buildPage() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("阿里云 EDM 邮件发送"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openConfigPage,
            tooltip: '配置',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadList,
            tooltip: '刷新列表',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题和操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '邮件发送记录',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('新建发送'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 提示信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '说明：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. 此页面显示所有已发送的邮件任务记录。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '2. 点击"新建发送"按钮可以创建新的邮件发送任务。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '3. 邮件发送需要先配置收件人列表、邮件模板和发信地址。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 邮件任务列表
            Expanded(
              child: _buildTaskListSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListSelector() {
    return Selector<MailTaskProvider, _TaskListState>(
      selector: (context, provider) => _TaskListState(
        isLoading: provider.isLoading,
        error: provider.error,
        tasksEmpty: provider.tasks.isEmpty,
        hasExistingTasks: provider.tasks.isNotEmpty,
      ),
      builder: (context, state, child) {
        // 首次加载时显示完整的加载指示器
        if (state.isLoading && !state.hasExistingTasks) {
          return const Center(child: CircularProgressIndicator());
        }
                  
        if (state.error != null) {
          final error = state.error!;
                    
          if (error.contains('Access Key') && error.contains('未配置')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '需要配置阿里云AccessKey',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '请点击右上角设置按钮配置您的阿里云AccessKey信息',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openConfigPage,
                    icon: const Icon(Icons.settings),
                    label: const Text('去配置'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
                    
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  '加载失败',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _reloadList,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
                  
        if (state.tasksEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  '暂无邮件发送记录',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '点击"新建发送"按钮开始发送邮件',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.send),
                  label: const Text('新建发送'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
                  
        return _buildOptimizedTaskList();
      },
    );
  }

  Widget _buildOptimizedTaskList() {
    return Column(
      children: [
        // 表格头部
        _buildTableHeader(),
        const SizedBox(height: 10),
        // 表格内容
        Expanded(
          child: _buildTableContent(),
        ),
        // 选中记录统计
        _buildSelectionStats(),
        // 分页控件
        _buildPagination(),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Selector<MailTaskProvider, bool>(
      selector: (context, provider) => provider.selectAll,
      builder: (context, isAllSelected, child) {
        return Container(
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: isAllSelected,
                  onChanged: (value) {
                    context.read<MailTaskProvider>().toggleSelectAll();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    '邮件模板',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '收件人列表',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '标签',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '请求数量',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '状态',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    '创建时间',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '操作',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableContent() {
    return Selector<MailTaskProvider, List<MailTaskModel>>(
      selector: (context, provider) => provider.tasks,
      builder: (context, tasks, child) {
        return Container(
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
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskRow(task, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskRow(MailTaskModel task, int index) {
    return Selector<MailTaskProvider, bool>(
      selector: (context, provider) => provider.isTaskSelected(task.taskId),
      builder: (context, isSelected, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    context.read<MailTaskProvider>().toggleTaskSelection(task.taskId);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    task.templateName,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    task.receiversName,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    task.tagName.isNotEmpty ? task.tagName : '无',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    task.requestCount,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildStatusChip(task),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    task.formattedCreateTime(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () => _showTaskDetails(task),
                        tooltip: '查看详情',
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

  Widget _buildStatusChip(MailTaskModel task) {
    Color chipColor;
    switch (task.taskStatus) {
      case '1':
        chipColor = Colors.green;
        break;
      case '2':
        chipColor = Colors.orange;
        break;
      case '3':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }
    
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        task.statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSelectionStats() {
    return Selector<MailTaskProvider, Map<String, dynamic>>(
      selector: (context, provider) => {
        'selectedCount': provider.selectedCount,
        'selectedRequestCount': provider.selectedRequestCount,
        'selectedSuccessCount': provider.selectedSuccessCount,
      },
      builder: (context, statsData, child) {
        final selectedCount = statsData['selectedCount'] as int;
        final selectedRequestCount = statsData['selectedRequestCount'] as int;
        final selectedSuccessCount = statsData['selectedSuccessCount'] as int;
        
        if (selectedCount == 0) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '已选中 $selectedCount 条记录',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(width: 24),
              Text(
                '请求数量：$selectedRequestCount',
                style: TextStyle(
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '成功数量：$selectedSuccessCount',
                style: TextStyle(
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '成功率：${selectedRequestCount > 0 ? ((selectedSuccessCount / selectedRequestCount) * 100).toStringAsFixed(1) : '0.0'}%',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Selector<MailTaskProvider, Map<String, dynamic>>(
      selector: (context, provider) => {
        'currentPage': provider.currentPage,
        'totalPages': provider.totalPages,
        'totalCount': provider.totalCount,
        'pageSize': provider.pageSize,
      },
      builder: (context, paginationData, child) {
        final currentPage = paginationData['currentPage'] as int;
        final totalPages = paginationData['totalPages'] as int;
        final totalCount = paginationData['totalCount'] as int;
        final pageSize = paginationData['pageSize'] as int;
        
        return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '共 $totalCount 条记录，第 ${currentPage + 1} 页，共 $totalPages 页',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Row(
                children: [
                  // 首页按钮
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: currentPage > 0
                        ? () => context.read<MailTaskProvider>().firstPage()
                        : null,
                    tooltip: '首页',
                  ),
                  // 上一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 0
                        ? () => context.read<MailTaskProvider>().previousPage()
                        : null,
                    tooltip: '上一页',
                  ),
                  // 页码显示和输入
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Text(
                          '第 ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: TextEditingController(text: '${currentPage + 1}'),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              final page = int.tryParse(value);
                              if (page != null && page >= 1 && page <= totalPages) {
                                context.read<MailTaskProvider>().goToPage(page);
                              } else {
                                // 如果输入的页码无效，显示提示并重置输入框
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('请输入有效的页码（1-$totalPages）'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                // 重置输入框为当前页码
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        Text(
                          ' 页，共 $totalPages 页',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // 下一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: currentPage < totalPages - 1
                        ? () => context.read<MailTaskProvider>().nextPage()
                        : null,
                    tooltip: '下一页',
                  ),
                  // 末页按钮
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: currentPage < totalPages - 1
                        ? () => context.read<MailTaskProvider>().lastPage()
                        : null,
                    tooltip: '末页',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTaskDetails(MailTaskModel task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          backgroundColor: Colors.white,
          child: Container(
            constraints: const BoxConstraints(minWidth: 350, maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '任务详情',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                _buildDetailRow('邮件模板', task.templateName),
                _buildDetailRow('收件人列表', task.receiversName),
                _buildDetailRow('发信类型', task.addressType == '0' ? '随机地址' : '固定地址'),
                _buildDetailRow('邮件标签', task.tagName.isNotEmpty ? task.tagName : '无'),
                _buildDetailRow('请求数量', task.requestCount),
                _buildDetailRow('状态', task.statusText),
                if (task.createTime.isNotEmpty)
                  _buildDetailRow('创建时间', task.formattedCreateTime()),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label：',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}