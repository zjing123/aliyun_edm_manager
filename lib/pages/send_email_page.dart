import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mail_task_provider.dart';
import '../providers/receiver_list_provider.dart';
import '../providers/global_config_provider.dart';
import '../models/mail_task_model.dart';
import '../models/template_model.dart';
import '../models/sender_address_model.dart';
import '../services/aliyun_edm_service.dart';
import 'config_page.dart';

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const _CreateEmailDialog();
      },
    );
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
              child: Consumer<MailTaskProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (provider.error != null) {
                    final error = provider.error!;
                    
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
                  
                  if (provider.tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.mail_outline,
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
                  
                  return _buildTaskList(provider.tasks);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<MailTaskModel> tasks) {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 1200;
          return Column(
            children: [
              // 表格头部
              _buildTableHeader(isWideScreen),
              // 表格内容
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTableRow(task, index, isWideScreen);
                  },
                ),
              ),
              // 分页控件
              _buildPagination(),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPagination() {
    return Consumer<MailTaskProvider>(
      builder: (context, provider, child) {
        if (provider.totalPages <= 1) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 分页信息
              Text(
                '共 ${provider.totalCount} 条记录，第 ${provider.currentPage}/${provider.totalPages} 页',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              // 分页控件
              Row(
                children: [
                  // 首页
                  _buildPaginationButton(
                    icon: Icons.first_page,
                    tooltip: '首页',
                    enabled: provider.currentPage > 1,
                    onPressed: provider.firstPage,
                  ),
                  const SizedBox(width: 8),
                  // 上一页
                  _buildPaginationButton(
                    icon: Icons.chevron_left,
                    tooltip: '上一页',
                    enabled: provider.currentPage > 1,
                    onPressed: provider.previousPage,
                  ),
                  const SizedBox(width: 16),
                  // 页码输入框
                  _buildPageInput(provider),
                  const SizedBox(width: 16),
                  // 下一页
                  _buildPaginationButton(
                    icon: Icons.chevron_right,
                    tooltip: '下一页',
                    enabled: provider.currentPage < provider.totalPages,
                    onPressed: provider.nextPage,
                  ),
                  const SizedBox(width: 8),
                  // 末页
                  _buildPaginationButton(
                    icon: Icons.last_page,
                    tooltip: '末页',
                    enabled: provider.currentPage < provider.totalPages,
                    onPressed: provider.lastPage,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPaginationButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
            borderRadius: BorderRadius.circular(4),
            color: enabled ? Colors.white : Colors.grey[50],
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPageInput(MailTaskProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 40, // 调整高度与按钮保持一致
          child: TextFormField(
            initialValue: provider.currentPage.toString(),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // 调整内边距
              isDense: true,
            ),
            onFieldSubmitted: (value) {
              final page = int.tryParse(value);
              if (page != null && page >= 1 && page <= provider.totalPages) {
                provider.goToPage(page);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '/ ${provider.totalPages}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildHeaderCell('模板名称', flex: isWideScreen ? 2 : 2),
            _buildHeaderCell('收件人列表', flex: isWideScreen ? 2 : 2),
            if (isWideScreen) _buildHeaderCell('任务ID', flex: 1),
            if (isWideScreen) _buildHeaderCell('邮件标签', flex: 1),
            _buildHeaderCell('请求数量', flex: 1),
            _buildHeaderCell('创建时间', flex: isWideScreen ? 2 : 2),
            _buildHeaderCell('状态', flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTableRow(MailTaskModel task, int index, bool isWideScreen) {
    final isEven = index % 2 == 0;
    
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildTableCell(
              task.templateName.isNotEmpty ? task.templateName : '未命名模板',
              flex: isWideScreen ? 2 : 2,
              fontWeight: FontWeight.w500,
            ),
            _buildTableCell(task.receiversName, flex: isWideScreen ? 2 : 2),
            if (isWideScreen) _buildTableCell(task.taskId, flex: 1),
            if (isWideScreen) _buildTableCell(task.tagName.isNotEmpty ? task.tagName : '--', flex: 1),
            _buildTableCell(task.requestCount, flex: 1),
            _buildTableCell(_formatDateTime(task.createTime), flex: isWideScreen ? 2 : 2),
            _buildStatusCell(task.taskStatus, flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String content, {int flex = 1, FontWeight? fontWeight}) {
    return Expanded(
      flex: flex,
      child: Text(
        content,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[800],
          fontWeight: fontWeight,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  Widget _buildStatusCell(String status, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: _buildStatusChip(status),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;
    
    switch (status) {
      case '1':
        chipColor = Colors.green;
        statusText = '成功';
        break;
      case '2':
        chipColor = Colors.orange;
        statusText = '发送中';
        break;
      case '3':
        chipColor = Colors.red;
        statusText = '失败';
        break;
      default:
        chipColor = Colors.grey;
        statusText = '未知';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }



  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '--';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}

class _CreateEmailDialog extends StatefulWidget {
  const _CreateEmailDialog();

  @override
  State<_CreateEmailDialog> createState() => _CreateEmailDialogState();
}

class _CreateEmailDialogState extends State<_CreateEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _replyToController = TextEditingController();
  
  String? _selectedReceiver;
  String? _selectedTemplate;
  String? _selectedSender;
  String? _selectedAddressType;
  String? _selectedTagName;
  bool _enableClickTrace = false;
  
  List<String> _receiverNames = [];
  List<TemplateModel> _templates = [];
  List<SenderAddressModel> _senderAddresses = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final globalConfig = context.read<GlobalConfigProvider>();
      final edmService = AliyunEdmService();
      edmService.setGlobalConfigProvider(globalConfig);
      
      // 加载收件人列表
      final receiverProvider = context.read<ReceiverListProvider>();
      await receiverProvider.loadReceivers();
      _receiverNames = receiverProvider.receivers.map((r) => r.receiversName).toList();
      
      // 加载模板列表
      _templates = await edmService.getAvailableTemplates();
      
      // 加载发信地址列表
      _senderAddresses = await edmService.getAvailableSenderAddresses();
      
    } catch (e) {
      print('加载数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  const Icon(Icons.send, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    '新建邮件发送',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 任务名称
                        TextFormField(
                          controller: _taskNameController,
                          decoration: const InputDecoration(
                            labelText: '任务名称（可选）',
                            hintText: '请输入任务名称',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 收件人列表
                        DropdownButtonFormField<String>(
                          value: _selectedReceiver,
                          decoration: const InputDecoration(
                            labelText: '收件人列表 *',
                            border: OutlineInputBorder(),
                          ),
                          items: _receiverNames.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedReceiver = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请选择收件人列表';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 邮件模板
                        DropdownButtonFormField<String>(
                          value: _selectedTemplate,
                          decoration: const InputDecoration(
                            labelText: '邮件模板 *',
                            border: OutlineInputBorder(),
                          ),
                          items: _templates.map((template) {
                            return DropdownMenuItem(
                              value: template.templateName,
                              child: Text(template.templateName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTemplate = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请选择邮件模板';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 发信地址
                        DropdownButtonFormField<String>(
                          value: _selectedSender,
                          decoration: const InputDecoration(
                            labelText: '发信地址 *',
                            border: OutlineInputBorder(),
                          ),
                          items: _senderAddresses.map((address) {
                            return DropdownMenuItem(
                              value: address.accountName,
                              child: Text(address.accountName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSender = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请选择发信地址';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 发信类型
                        DropdownButtonFormField<String>(
                          value: _selectedAddressType,
                          decoration: const InputDecoration(
                            labelText: '发信类型 *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '0', child: Text('随机账号')),
                            DropdownMenuItem(value: '1', child: Text('固定账号')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedAddressType = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请选择发信类型';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 邮件标签
                        TextFormField(
                          onChanged: (value) {
                            _selectedTagName = value;
                          },
                          decoration: const InputDecoration(
                            labelText: '邮件标签',
                            hintText: '请输入邮件标签',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 回复地址
                        TextFormField(
                          controller: _replyToController,
                          decoration: const InputDecoration(
                            labelText: '回复地址',
                            hintText: '请输入回复地址',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                                return '请输入有效的邮件地址';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 点击追踪
                        Row(
                          children: [
                            Checkbox(
                              value: _enableClickTrace,
                              onChanged: (value) {
                                setState(() {
                                  _enableClickTrace = value ?? false;
                                });
                              },
                            ),
                            const Text('启用点击追踪'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('发送邮件'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedReceiver == null || _selectedTemplate == null || 
        _selectedSender == null || _selectedAddressType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请完整填写所有必填字段'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final request = BatchSendMailRequest(
        receiversName: _selectedReceiver!,
        templateName: _selectedTemplate!,
        accountName: _selectedSender!,
        clickTrace: _enableClickTrace ? '1' : '0',
        addressType: _selectedAddressType!,
        tagName: _selectedTagName ?? '',
        replyToAddress: _replyToController.text,
        taskName: _taskNameController.text.isNotEmpty ? _taskNameController.text : null,
      );
      
      final provider = context.read<MailTaskProvider>();
      final success = await provider.sendMail(request);
      
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('邮件发送成功！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('邮件发送失败: ${provider.error ?? '未知错误'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('邮件发送失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _replyToController.dispose();
    super.dispose();
  }
}