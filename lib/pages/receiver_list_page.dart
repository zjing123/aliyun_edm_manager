import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/aliyun_edm_service.dart';
import '../utils/dialog_util.dart';
import '../providers/receiver_list_provider.dart';
import '../models/receiver_list_model.dart';
import 'config_page.dart';
import 'receiver_detail_page.dart';
import 'batch_create_receiver_page.dart';

class ReceiverListPage extends StatefulWidget {
  const ReceiverListPage({super.key});

  @override
  State<ReceiverListPage> createState() => _ReceiverListPageState();
}

class _ReceiverListPageState extends State<ReceiverListPage> with AutomaticKeepAliveClientMixin {
  final Set<String> _selectedReceivers = <String>{};
  bool _selectAll = false;

  @override
  bool get wantKeepAlive => false; // 不保持页面状态，每次都会重新创建

  @override
  void initState() {
    super.initState();
    // 在页面初始化时强制刷新数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiverListProvider>().forceRefresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当依赖项改变时（比如从其他页面返回），强制刷新数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiverListProvider>().forceRefresh();
    });
  }

  void _reloadList() {
    context.read<ReceiverListProvider>().forceRefresh();
  }

  void _deleteReceiver(String receiverId, String receiverName) async {
    final confirm = await DialogUtil.confirm(context, "确认删除收件人列表 \"$receiverName\" 吗？\n\n删除后该列表及其所有收件人数据将无法恢复。");
    if (confirm) {
      try {
        await context.read<ReceiverListProvider>().deleteReceiver(receiverId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除成功'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteSelectedReceivers() async {
    if (_selectedReceivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择要删除的收件人列表'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await DialogUtil.confirm(
      context, 
      "确认删除选中的 ${_selectedReceivers.length} 个收件人列表吗？\n\n删除后这些列表及其所有收件人数据将无法恢复。"
    );
    
    if (confirm) {
      try {
        await context.read<ReceiverListProvider>().deleteReceivers(_selectedReceivers.toList());
        _selectedReceivers.clear();
        _selectAll = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功删除 ${_selectedReceivers.length} 个收件人列表'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelectAll() {
    final provider = context.read<ReceiverListProvider>();
    if (_selectAll) {
      setState(() {
        _selectedReceivers.clear();
        _selectAll = false;
      });
    } else {
      // 获取所有receiverId并选中
      final receiverIds = provider.receivers.map((item) => item.receiverId).toSet();
      setState(() {
        _selectedReceivers.addAll(receiverIds);
        _selectAll = true;
      });
    }
  }

  void _toggleReceiverSelection(String receiverId) {
    final provider = context.read<ReceiverListProvider>();
    if (_selectedReceivers.contains(receiverId)) {
      setState(() {
        _selectedReceivers.remove(receiverId);
        _selectAll = false;
      });
    } else {
      setState(() {
        _selectedReceivers.add(receiverId);
      });
      // 检查是否所有项目都被选中
      if (_selectedReceivers.length == provider.receivers.length) {
        setState(() {
          _selectAll = true;
        });
      }
    }
  }

  void _createReceiver() async {
    final result = await DialogUtil.inputReceiverName(context);
    if (result != null) {
      try {
        final receiver = ReceiverListModel(
          receiverId: '', // 创建时ID为空，服务端会生成
          receiversName: result['name']!,
          receiversAlias: result['alias']!,
          desc: result['desc']!,
          count: 0,
          createTime: DateTime.now().toIso8601String(),
        );
        
        await context.read<ReceiverListProvider>().addReceiver(receiver);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('创建成功'),
            backgroundColor: Colors.green,
          ),
        );
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

  void _openDetailPage(String receiverId, String receiverName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiverDetailPage(
          receiverId: receiverId,
          receiverName: receiverName,
        ),
      ),
    );
    
    // 返回时重新加载列表以更新数据
    _reloadList();
  }

  void _openBatchCreatePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BatchCreateReceiverPage(),
      ),
    );
    
    // 返回时重新加载列表以更新数据
    _reloadList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用super.build
    return _buildPage();
  }

  Widget _buildPage() {
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadList,
            tooltip: '刷新列表',
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
                Row(
                  children: [
                    if (_selectedReceivers.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _deleteSelectedReceivers,
                        icon: Icon(Icons.delete, color: Colors.white),
                        label: Text('删除选中(${_selectedReceivers.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (_selectedReceivers.isNotEmpty) const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _createReceiver,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('新建收件人列表'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openBatchCreatePage,
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: const Text('批量创建收件人列表'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
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
              child: Consumer<ReceiverListProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (provider.error != null) {
                    final error = provider.error!;
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
                    return Center(child: Text("加载失败: $error"));
                  }
                  
                  final receivers = provider.receivers;
                  final screenWidth = MediaQuery.of(context).size.width;
                  final showDescription = screenWidth >= 1000;
                  
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: [
                          // 固定表头
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Table(
                              columnWidths: showDescription ? {
                                0: const FlexColumnWidth(0.8),  // 复选框
                                1: const FlexColumnWidth(2.0),  // 列表名称
                                2: const FlexColumnWidth(2.5),  // 别称地址
                                3: const FlexColumnWidth(2.0),  // 描述
                                4: const FlexColumnWidth(1.0),  // 总数
                                5: const FlexColumnWidth(2.0),  // 创建时间
                                6: const FlexColumnWidth(1.5),  // 操作
                              } : {
                                0: const FlexColumnWidth(0.8),  // 复选框
                                1: const FlexColumnWidth(2.5),  // 列表名称
                                2: const FlexColumnWidth(3.0),  // 别称地址
                                3: const FlexColumnWidth(1.2),  // 总数
                                4: const FlexColumnWidth(2.5),  // 创建时间
                                5: const FlexColumnWidth(1.8),  // 操作
                              },
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                TableRow(
                                  children: [
                                    _buildCheckboxHeaderCell(),
                                    _buildHeaderCell('列表名称'),
                                    _buildHeaderCell('别称地址'),
                                    if (showDescription) _buildHeaderCell('描述'),
                                    _buildHeaderCell('总数'),
                                    _buildHeaderCell('创建时间'),
                                    _buildHeaderCell('操作', isRight: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // 可滚动的表体
                          Expanded(
                            child: receivers.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Text(
                                        '暂无数据',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  )
                                : Scrollbar(
                                    child: SingleChildScrollView(
                                      child: Table(
                                        columnWidths: showDescription ? {
                                          0: const FlexColumnWidth(0.8),
                                          1: const FlexColumnWidth(2.0),
                                          2: const FlexColumnWidth(2.5),
                                          3: const FlexColumnWidth(2.0),
                                          4: const FlexColumnWidth(1.0),
                                          5: const FlexColumnWidth(2.0),
                                          6: const FlexColumnWidth(1.5),
                                        } : {
                                          0: const FlexColumnWidth(0.8),
                                          1: const FlexColumnWidth(2.5),
                                          2: const FlexColumnWidth(3.0),
                                          3: const FlexColumnWidth(1.2),
                                          4: const FlexColumnWidth(2.5),
                                          5: const FlexColumnWidth(1.8),
                                        },
                                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                        children: receivers.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          final isLastRow = index == receivers.length - 1;
                                          
                                          return TableRow(
                                            decoration: BoxDecoration(
                                              color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                              border: isLastRow ? null : Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            children: [
                                              _buildCheckboxCell(item.receiverId),
                                              _buildDataCell(item.receiversName),
                                              _buildDataCell(item.receiversAlias),
                                              if (showDescription) _buildDataCell(item.desc ?? ''),
                                              _buildDataCell(item.count.toString()),
                                              _buildDataCell(item.createTime),
                                              _buildActionCell(
                                                onDetail: () => _openDetailPage(item.receiverId, item.receiversName),
                                                onDelete: () => _deleteReceiver(item.receiverId, item.receiversName),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
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

  Widget _buildCheckboxHeaderCell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Checkbox(
        value: _selectAll,
        onChanged: (value) => _toggleSelectAll(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildCheckboxCell(String receiverId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Checkbox(
        value: _selectedReceivers.contains(receiverId),
        onChanged: (value) => _toggleReceiverSelection(receiverId),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool isRight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
        textAlign: isRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionCell({
    required VoidCallback onDetail,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onDetail,
            child: const Text('详情', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
              minimumSize: const Size(32, 28),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          const SizedBox(width: 2),
          TextButton(
            onPressed: onDelete,
            child: const Text('删除', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size(32, 28),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ],
      ),
    );
  }
}