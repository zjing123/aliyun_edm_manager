import 'package:flutter/material.dart';

class SendEmailPage extends StatefulWidget {
  const SendEmailPage({super.key});

  @override
  State<SendEmailPage> createState() => _SendEmailPageState();
}

class _SendEmailPageState extends State<SendEmailPage> {
  String? _selectedRecipientList;
  String? _selectedTemplate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '发送邮件',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '收件人列表',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedRecipientList,
                        items: const [
                          DropdownMenuItem(
                            value: 'list1',
                            child: Text('收件人列表1'),
                          ),
                          DropdownMenuItem(
                            value: 'list2',
                            child: Text('收件人列表2'),
                          ),
                          DropdownMenuItem(
                            value: 'list3',
                            child: Text('收件人列表3'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRecipientList = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '发件人名称',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '邮件主题',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '邮件模板',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedTemplate,
                        items: const [
                          DropdownMenuItem(
                            value: 'template1',
                            child: Text('欢迎邮件模板'),
                          ),
                          DropdownMenuItem(
                            value: 'template2',
                            child: Text('密码重置模板'),
                          ),
                          DropdownMenuItem(
                            value: 'template3',
                            child: Text('订单确认模板'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTemplate = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '邮件内容',
                          hintText: '如果选择了模板，此处可留空',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 10,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.send),
                            label: const Text('立即发送'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.schedule),
                            label: const Text('定时发送'),
                          ),
                        ],
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
}