import 'package:flutter/material.dart';

class TemplateManagementPage extends StatefulWidget {
  const TemplateManagementPage({super.key});

  @override
  State<TemplateManagementPage> createState() => _TemplateManagementPageState();
}

class _TemplateManagementPageState extends State<TemplateManagementPage> {
  // 模拟模板数据
  final List<Map<String, dynamic>> _templates = [
    {
      'id': '1',
      'name': '欢迎邮件模板',
      'subject': '欢迎加入我们！',
      'type': '欢迎类',
      'createTime': '2025-01-15 10:30:00',
      'status': '启用',
    },
    {
      'id': '2',
      'name': '营销推广模板',
      'subject': '限时优惠活动通知',
      'type': '营销类',
      'createTime': '2025-01-14 14:20:00',
      'status': '启用',
    },
    {
      'id': '3',
      'name': '系统通知模板',
      'subject': '系统维护通知',
      'type': '通知类',
      'createTime': '2025-01-13 09:15:00',
      'status': '禁用',
    },
  ];

  void _createTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建模板'),
        content: const SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: '模板名称',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: '邮件主题',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现创建模板功能
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _editTemplate(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑模板'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: '模板名称',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: template['name']),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: '邮件主题',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: template['subject']),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '邮件内容',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现更新模板功能
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(String templateId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个模板吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _templates.removeWhere((template) => template['id'] == templateId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模板管理'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: _createTemplate,
            icon: const Icon(Icons.add),
            label: const Text('新建模板'),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: 实现刷新功能
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Column(
            children: [
              // 搜索栏
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '搜索模板名称或主题',
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
                      hint: const Text('模板类型'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('全部')),
                        DropdownMenuItem(value: 'welcome', child: Text('欢迎类')),
                        DropdownMenuItem(value: 'marketing', child: Text('营销类')),
                        DropdownMenuItem(value: 'notification', child: Text('通知类')),
                      ],
                      onChanged: (value) {
                        // TODO: 实现筛选功能
                      },
                    ),
                  ],
                ),
              ),
              // 模板列表
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('模板名称')),
                      DataColumn(label: Text('邮件主题')),
                      DataColumn(label: Text('类型')),
                      DataColumn(label: Text('创建时间')),
                      DataColumn(label: Text('状态')),
                      DataColumn(label: Text('操作')),
                    ],
                    rows: _templates.map((template) {
                      return DataRow(
                        cells: [
                          DataCell(Text(template['name'] ?? '')),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                template['subject'] ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(template['type'] ?? '')),
                          DataCell(Text(template['createTime'] ?? '')),
                          DataCell(
                            Chip(
                              label: Text(template['status'] ?? ''),
                              backgroundColor: template['status'] == '启用'
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              labelStyle: TextStyle(
                                color: template['status'] == '启用'
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _editTemplate(template),
                                  child: const Text('编辑'),
                                ),
                                const Text(' | '),
                                TextButton(
                                  onPressed: () => _deleteTemplate(template['id']),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}