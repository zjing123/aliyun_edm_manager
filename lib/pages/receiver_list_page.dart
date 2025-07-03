import 'package:flutter/material.dart';
import '../services/aliyun_edm_service.dart';
import '../utils/dialog_util.dart';
import 'config_page.dart';

class ReceiverListPage extends StatefulWidget {
  const ReceiverListPage({super.key});

  @override
  State<ReceiverListPage> createState() => _ReceiverListPageState();
}

class _ReceiverListPageState extends State<ReceiverListPage> {
  final AliyunEDMService _service = AliyunEDMService();
  late Future<List<Map<String, dynamic>>> _receiverFuture;

  @override
  void initState() {
    super.initState();
    _reloadList();
  }

  void _reloadList() {
    setState(() {
      _receiverFuture = _service.queryReceivers();
    });
  }

  void _deleteReceiver(String name) async {
    final confirm = await DialogUtil.confirm(context, "确认删除该收件人列表？");
    if (confirm) {
      await _service.deleteReceiver(name);
      _reloadList();
    }
  }

  void _createReceiver() async {
    final name = await DialogUtil.inputReceiverName(context);
    if (name != null && name.isNotEmpty) {
      try {
        await _service.createReceiver(name);
        _reloadList();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _openConfigPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ConfigPage()),
    );
    
    // 如果配置有更新，重新加载列表
    if (result == true) {
      _reloadList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("阿里云 EDM 收件人列表"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openConfigPage,
            tooltip: '配置',
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
                  '收件人列表',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _createReceiver,
                  icon: const Icon(Icons.add),
                  label: const Text('新建收件人列表'),
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
                    '1. 最多支持添加10个收件人列表，单个列表的邮件地址数目最高支持10000个。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '2. 列表名称用来标识列表，因此不可重复。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '3. 支持txt、csv格式文件，不同字段间支持英文逗号分隔。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 数据表格
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _receiverFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error.toString();
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
                            ),
                          ],
                        ),
                      );
                    }
                    return Center(child: Text("加载失败: ${snapshot.error}"));
                  }
                  final receivers = snapshot.data!;
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                          columns: const [
                            DataColumn(label: Text('列表名称')),
                            DataColumn(label: Text('别称地址')),
                            DataColumn(label: Text('描述')),
                            DataColumn(label: Text('总数')),
                            DataColumn(label: Text('创建时间')),
                            DataColumn(label: Text('操作')),
                          ],
                          rows: receivers.map((item) {
                            return DataRow(cells: [
                              DataCell(Text(item['ReceiversName'] ?? '')),
                              DataCell(Text(item['ReceiversAlias'] ?? '')),
                              DataCell(Text(item['Desc'] ?? '')),
                              DataCell(Text(item['Count']?.toString() ?? '')),
                              DataCell(Text(item['CreateTime'] ?? '')),
                              DataCell(
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => DialogUtil.showDetailDialog(context, item['ReceiverId'] ?? ''), 
                                      child: const Text('详情'),
                                    ),
                                    TextButton(
                                      onPressed: () => _deleteReceiver(item['ReceiverId'] ?? ''), 
                                      child: const Text('删除'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '菜单',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('收件人列表'),
              selected: true,
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('系统配置'),
              onTap: _openConfigPage,
            ),
          ],
        ),
      ),
    );
  }
}