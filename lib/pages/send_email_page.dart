import 'package:flutter/material.dart';

class SendEmailPage extends StatefulWidget {
  const SendEmailPage({super.key});

  @override
  State<SendEmailPage> createState() => _SendEmailPageState();
}

class _SendEmailPageState extends State<SendEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedReceiver = '';
  String _selectedTemplate = '';

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 操作按钮区域
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _sendEmail,
                    icon: const Icon(Icons.send),
                    label: const Text('发送邮件'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _saveDraft,
                    icon: const Icon(Icons.save),
                    label: const Text('保存草稿'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _previewEmail,
                    icon: const Icon(Icons.preview),
                    label: const Text('预览'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 邮件编辑区域
              Expanded(
                child: Row(
                  children: [
                    // 左侧编辑区域
                    Expanded(
                      flex: 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '邮件编辑',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 收件人选择
                              DropdownButtonFormField<String>(
                                value: _selectedReceiver.isEmpty ? null : _selectedReceiver,
                                decoration: const InputDecoration(
                                  labelText: '收件人列表',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'list1', child: Text('收件人列表1')),
                                  DropdownMenuItem(value: 'list2', child: Text('收件人列表2')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedReceiver = value ?? '';
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
                              // 模板选择
                              DropdownButtonFormField<String>(
                                value: _selectedTemplate.isEmpty ? null : _selectedTemplate,
                                decoration: const InputDecoration(
                                  labelText: '邮件模板（可选）',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'template1', child: Text('营销模板1')),
                                  DropdownMenuItem(value: 'template2', child: Text('通知模板1')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTemplate = value ?? '';
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              // 邮件主题
                              TextFormField(
                                controller: _subjectController,
                                decoration: const InputDecoration(
                                  labelText: '邮件主题',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '请输入邮件主题';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // 邮件内容
                              Expanded(
                                child: TextFormField(
                                  controller: _contentController,
                                  maxLines: null,
                                  expands: true,
                                  decoration: const InputDecoration(
                                    labelText: '邮件内容',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入邮件内容';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 右侧设置区域
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '发送设置',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 发送时间设置
                              ListTile(
                                leading: const Icon(Icons.schedule),
                                title: const Text('立即发送'),
                                trailing: Radio<String>(
                                  value: 'now',
                                  groupValue: 'now',
                                  onChanged: (value) {},
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.schedule),
                                title: const Text('定时发送'),
                                trailing: Radio<String>(
                                  value: 'schedule',
                                  groupValue: 'now',
                                  onChanged: (value) {},
                                ),
                              ),
                              const Divider(),
                              // 发送选项
                              CheckboxListTile(
                                title: const Text('发送后生成报告'),
                                value: true,
                                onChanged: (value) {},
                              ),
                              CheckboxListTile(
                                title: const Text('启用点击跟踪'),
                                value: false,
                                onChanged: (value) {},
                              ),
                              CheckboxListTile(
                                title: const Text('启用退订链接'),
                                value: true,
                                onChanged: (value) {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendEmail() {
    if (_formKey.currentState!.validate()) {
      // TODO: 实现发送邮件功能
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('邮件发送功能开发中...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _saveDraft() {
    // TODO: 实现保存草稿功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('草稿保存功能开发中...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _previewEmail() {
    // TODO: 实现预览功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('邮件预览功能开发中...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
} 