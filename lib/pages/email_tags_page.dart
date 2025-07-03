import 'package:flutter/material.dart';

class EmailTagsPage extends StatefulWidget {
  const EmailTagsPage({super.key});

  @override
  State<EmailTagsPage> createState() => _EmailTagsPageState();
}

class _EmailTagsPageState extends State<EmailTagsPage> {
  final List<String> _tags = ['营销邮件', '系统通知', '账单提醒', '客户关怀'];

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
                  '邮件标签',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddTagDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新建标签'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
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
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _tags.remove(tag);
                              });
                            },
                            backgroundColor: Colors.blue[50],
                            labelStyle: TextStyle(color: Colors.blue[700]),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTagDialog() {
    String newTag = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建标签'),
        content: TextField(
          onChanged: (value) => newTag = value,
          decoration: const InputDecoration(
            labelText: '标签名称',
            hintText: '请输入标签名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newTag.isNotEmpty) {
                setState(() {
                  _tags.add(newTag);
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}