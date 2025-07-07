import 'package:flutter/material.dart';

class SendingAddressPage extends StatefulWidget {
  const SendingAddressPage({super.key});

  @override
  State<SendingAddressPage> createState() => _SendingAddressPageState();
}

class _SendingAddressPageState extends State<SendingAddressPage> {
  final List<Map<String, dynamic>> _addresses = [
    {
      'name': '收件人列表5',
      'email': '2025062705@nexperia.com',
      'description': '收件人列表5',
      'count': 457,
      'createTime': '2025-06-27 09:50:40',
    },
    {
      'name': '收件人列表4',
      'email': '2025062704@nexperia.com',
      'description': '收件人列表4',
      'count': 3000,
      'createTime': '2025-06-27 09:50:15',
    },
    {
      'name': '收件人列表3',
      'email': '2025062703@nexperia.com',
      'description': '收件人列表3',
      'count': 3000,
      'createTime': '2025-06-27 09:49:46',
    },
    {
      'name': '收件人列表2',
      'email': '2025062702@nexperia.com',
      'description': '收件人列表2',
      'count': 3000,
      'createTime': '2025-06-27 09:49:16',
    },
    {
      'name': '收件人列表1',
      'email': '2025062701@nexperia.com',
      'description': '收件人列表1',
      'count': 3000,
      'createTime': '2025-06-27 09:48:48',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                  '发信地址',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddAddressDialog();
                  },
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
                    '1. 最多支持添加10个收件人列表，单个列表的邮件地址数目最高支持10000个。最高支持数量问题取决于日额度。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '2. 列表名称和用来通知列表，因此不可重复。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '3. 支持txt、（示例）、csv （示例）格式文件,不同字段间收支持英文逗号分隔。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 数据表格
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
                      rows: _addresses
                          .map(
                            (address) => DataRow(
                              cells: [
                                DataCell(Text(address['name'])),
                                DataCell(Text(address['email'])),
                                DataCell(Text(address['description'])),
                                DataCell(Text(address['count'].toString())),
                                DataCell(Text(address['createTime'])),
                                DataCell(
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text('详情'),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text('删除'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建收件人列表'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: '列表名称',
                  hintText: '请输入列表名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: '别称地址',
                  hintText: '请输入别称地址',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: '描述',
                  hintText: '请输入描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file),
                label: const Text('上传收件人文件'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 添加列表逻辑
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}