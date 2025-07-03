import 'package:flutter/material.dart';
import '../services/aliyun_edm_service.dart';
import '../utils/dialog_util.dart';
import '../pages/config_page.dart';
import '../services/config_service.dart';

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
      await _service.createReceiver(name);
      _reloadList();
    }
  }

  void _openConfig() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConfigPage()));
    _reloadList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("阿里云 EDM 收件人列表"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createReceiver,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openConfig,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _receiverFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
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