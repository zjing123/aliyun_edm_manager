import 'package:flutter/material.dart';
import '../services/aliyun_edm_service.dart';
import '../utils/dialog_util.dart';
import '../widgets/app_drawer.dart';

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
    final result = await Navigator.pushNamed<bool>(context, '/config');
    
    // 如果配置有更新，重新加载列表
    if (result == true) {
      _reloadList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("阿里云 EDM 收件人列表"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openConfigPage,
            tooltip: '配置',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createReceiver,
            tooltip: '新建收件人列表',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/receivers'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
          return DataTable(
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
                DataCell(Row(
                  children: [
                    TextButton(onPressed: () => DialogUtil.showDetailDialog(context, item['ReceiverId'] ?? ''), child: Text('详情')),
                    Text(' | '),
                    TextButton(onPressed: () => _deleteReceiver(item['ReceiverId'] ?? ''), child: Text('删除')),
                  ],
                )),
              ]);
            }).toList(),
          );
        },
      ),
    );
  }
}