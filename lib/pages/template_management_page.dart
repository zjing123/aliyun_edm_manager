import 'package:flutter/material.dart';

class TemplateManagementPage extends StatefulWidget {
  const TemplateManagementPage({super.key});

  @override
  State<TemplateManagementPage> createState() => _TemplateManagementPageState();
}

class _TemplateManagementPageState extends State<TemplateManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 操作按钮区域
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 实现新建模板功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('新建模板功能开发中...')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新建模板'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 实现导入模板功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('导入模板功能开发中...')),
                    );
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('导入模板'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 模板列表
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '邮件模板列表',
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
                                Icons.description_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无邮件模板',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '点击"新建模板"开始创建您的第一个邮件模板',
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
} 