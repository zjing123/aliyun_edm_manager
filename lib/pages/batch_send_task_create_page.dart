import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/batch_send_task_model.dart';
import '../models/receiver_list_model.dart';
import '../providers/batch_send_task_provider.dart';
import '../providers/receiver_list_provider.dart';

class BatchSendTaskCreatePage extends StatefulWidget {
  const BatchSendTaskCreatePage({super.key});

  @override
  State<BatchSendTaskCreatePage> createState() => _BatchSendTaskCreatePageState();
}

class _BatchSendTaskCreatePageState extends State<BatchSendTaskCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _senderAddressController = TextEditingController();
  final _tagController = TextEditingController();

  String? _selectedTemplateId;
  String? _selectedTemplateName;
  List<ReceiverListConfig> _selectedReceiverLists = [];
  bool _enableTracking = false;

  // 模拟的模板数据
  final List<Map<String, String>> _templates = [
    {'id': 'template-001', 'name': '欢迎邮件模板'},
    {'id': 'template-002', 'name': '密码重置模板'},
    {'id': 'template-003', 'name': '订单确认模板'},
    {'id': 'template-004', 'name': '促销活动模板'},
    {'id': 'template-005', 'name': '系统通知模板'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiverListProvider>().loadReceivers();
    });
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _senderNameController.dispose();
    _senderAddressController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('新建批量发送任务'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 32),
                      _buildTemplateSection(),
                      const SizedBox(height: 32),
                      _buildReceiverListsSection(),
                      const SizedBox(height: 32),
                      _buildSenderSection(),
                      const SizedBox(height: 32),
                      _buildAdvancedSettingsSection(),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                '基本信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _taskNameController,
            decoration: const InputDecoration(
              labelText: '任务名称 *',
              hintText: '请输入任务名称',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入任务名称';
              }
              if (value.length > 50) {
                return '任务名称不能超过50个字符';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            children: [
              Icon(Icons.description, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                '邮件模板',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '选择模板 *',
              border: OutlineInputBorder(),
            ),
            value: _selectedTemplateId,
            items: _templates.map((template) {
              return DropdownMenuItem(
                value: template['id'],
                child: Text(template['name']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTemplateId = value;
                _selectedTemplateName = _templates
                    .firstWhere((t) => t['id'] == value)['name'];
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请选择邮件模板';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverListsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            children: [
              Icon(Icons.people_outline, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                '收件人列表',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '选择收件人列表并设置发送间隔（按列表顺序发送，每个列表发送完成后等待指定时间再发送下一个列表）',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Consumer<ReceiverListProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final receivers = provider.receivers;
              if (receivers.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无收件人列表',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '请先创建收件人列表',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  ...receivers.map((receiver) => _buildReceiverListTile(receiver)),
                  if (_selectedReceiverLists.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSelectedReceiversSummary(),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverListTile(ReceiverListModel receiver) {
    final isSelected = _selectedReceiverLists.any((r) => r.receiverId == receiver.receiverId);
    final selectedConfig = _selectedReceiverLists.firstWhere(
      (r) => r.receiverId == receiver.receiverId,
      orElse: () => ReceiverListConfig(
        receiverId: receiver.receiverId,
        receiverName: receiver.receiversName,
        intervalMinutes: 5,
        emailCount: receiver.count,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.blue[50] : Colors.grey[50],
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedReceiverLists.add(selectedConfig);
                  } else {
                    _selectedReceiverLists.removeWhere(
                      (r) => r.receiverId == receiver.receiverId,
                    );
                  }
                });
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receiver.receiversName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${receiver.count} 个收件人',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!receiver.isDeletable)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '只读',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
                                children: isSelected
                            ? <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: selectedConfig.intervalMinutes.toString(),
                              decoration: const InputDecoration(
                                labelText: '发送间隔（分钟）',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final interval = int.tryParse(value) ?? 5;
                                setState(() {
                                  final index = _selectedReceiverLists.indexWhere(
                                    (r) => r.receiverId == receiver.receiverId,
                                  );
                                  if (index != -1) {
                                    _selectedReceiverLists[index] = ReceiverListConfig(
                                      receiverId: receiver.receiverId,
                                      receiverName: receiver.receiversName,
                                      intervalMinutes: interval,
                                      emailCount: receiver.count,
                                    );
                                  }
                                });
                              },
                              validator: (value) {
                                final interval = int.tryParse(value ?? '');
                                if (interval == null || interval < 1) {
                                  return '请输入有效的间隔时间（至少1分钟）';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '此列表将在前一个列表发送完成后等待 $selectedConfig.intervalMinutes 分钟再开始发送',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildSelectedReceiversSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '发送顺序预览',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._selectedReceiverLists.asMap().entries.map((entry) {
            final index = entry.key;
            final config = entry.value;
            final isLast = index == _selectedReceiverLists.length - 1;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      config.receiverName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '间隔 ${config.intervalMinutes} 分钟',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_downward, color: Colors.grey[400], size: 16),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSenderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            children: [
              Icon(Icons.email_outlined, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                '发件人设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _senderNameController,
                  decoration: const InputDecoration(
                    labelText: '发件人名称 *',
                    hintText: '请输入发件人名称',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入发件人名称';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _senderAddressController,
                  decoration: const InputDecoration(
                    labelText: '发件人邮箱 *',
                    hintText: '请输入发件人邮箱',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入发件人邮箱';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '请输入有效的邮箱地址';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tagController,
            decoration: const InputDecoration(
              labelText: '发件标签',
              hintText: '可选，用于标识邮件来源',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            children: [
              Icon(Icons.settings_outlined, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                '高级设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('启用邮件跟踪'),
            subtitle: const Text('跟踪邮件的打开、点击等行为'),
            value: _enableTracking,
            onChanged: (value) {
              setState(() {
                _enableTracking = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _createTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('创建任务'),
            ),
          ),
        ],
      ),
    );
  }

  void _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReceiverLists.isEmpty) {
      _showSnackBar('请至少选择一个收件人列表', isError: true);
      return;
    }

    final task = BatchSendTaskModel(
      taskId: 'task-${DateTime.now().millisecondsSinceEpoch}',
      taskName: _taskNameController.text,
      templateId: _selectedTemplateId!,
      templateName: _selectedTemplateName!,
      receiverLists: _selectedReceiverLists,
      senderAddress: _senderAddressController.text,
      senderName: _senderNameController.text,
      tag: _tagController.text.isNotEmpty ? _tagController.text : null,
      enableTracking: _enableTracking,
      createdAt: DateTime.now(),
      totalEmails: _selectedReceiverLists.fold(0, (sum, config) => sum + config.emailCount),
    );

    final provider = context.read<BatchSendTaskProvider>();
    final success = await provider.addTask(task);

    if (success) {
      _showSnackBar('批量发送任务创建成功');
      Navigator.of(context).pop();
    } else {
      _showSnackBar('创建任务失败', isError: true);
    }
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