import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receiver_list_provider.dart';
import '../providers/page_config_provider.dart';
import '../utils/dialog_util.dart';

class ForbiddenDeleteSettingsPage extends StatefulWidget {
  const ForbiddenDeleteSettingsPage({super.key});

  @override
  State<ForbiddenDeleteSettingsPage> createState() => _ForbiddenDeleteSettingsPageState();
}

class _ForbiddenDeleteSettingsPageState extends State<ForbiddenDeleteSettingsPage> {
  final Set<String> _selectedForbiddenIds = <String>{};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 强制刷新收件人列表
      await context.read<ReceiverListProvider>().forceRefresh();
      
      // 获取当前禁止删除的ID
      final pageConfig = context.read<PageConfigProvider>();
      final forbiddenIds = pageConfig.forbiddenDeleteReceiverIds;
      
      setState(() {
        _selectedForbiddenIds.clear();
        _selectedForbiddenIds.addAll(forbiddenIds);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final pageConfig = context.read<PageConfigProvider>();
      await pageConfig.setForbiddenDeleteReceiverIds(_selectedForbiddenIds);
      
      // 刷新收件人列表以更新isDeletable状态
      await context.read<ReceiverListProvider>().forceRefresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设置已保存'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllSettings() async {
    final confirm = await DialogUtil.confirm(
      context, 
      '确认清空所有禁止删除设置吗？\n\n清空后所有收件人列表都将可以删除。'
    );
    
    if (confirm) {
      try {
        final pageConfig = context.read<PageConfigProvider>();
        await pageConfig.clearForbiddenDeleteReceiverIds();
        
        setState(() {
          _selectedForbiddenIds.clear();
        });
        
        // 刷新收件人列表
        await context.read<ReceiverListProvider>().forceRefresh();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已清空所有设置'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('清空失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _toggleReceiverSelection(String receiverId) {
    setState(() {
      if (_selectedForbiddenIds.contains(receiverId)) {
        _selectedForbiddenIds.remove(receiverId);
      } else {
        _selectedForbiddenIds.add(receiverId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('禁止删除设置'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<ReceiverListProvider>(
      builder: (context, provider, child) {
        final receivers = provider.receivers;
        
        if (receivers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.list_alt_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  '暂无收件人列表',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '请先创建一些收件人列表',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面标题和操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '禁止删除设置',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _clearAllSettings,
                        icon: const Icon(Icons.clear_all, color: Colors.white),
                        label: const Text('清空设置'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('保存设置'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 说明信息
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
                      '1. 勾选下方的收件人列表，这些列表将被标记为"只读"，无法删除。',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    Text(
                      '2. 取消勾选后，对应的收件人列表将可以正常删除。',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    Text(
                      '3. 设置会立即生效，请谨慎操作。',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 统计信息
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      '当前已设置 ${_selectedForbiddenIds.length} 个收件人列表为只读',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 收件人列表
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: [
                        // 表头
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
                            columnWidths: const {
                              0: FlexColumnWidth(0.8),  // 复选框
                              1: FlexColumnWidth(3.0),  // 列表名称
                              2: FlexColumnWidth(2.5),  // 别称地址
                              3: FlexColumnWidth(1.0),  // 总数
                              4: FlexColumnWidth(2.0),  // 创建时间
                            },
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(
                                children: [
                                  _buildHeaderCell(''),
                                  _buildHeaderCell('列表名称'),
                                  _buildHeaderCell('别称地址'),
                                  _buildHeaderCell('总数'),
                                  _buildHeaderCell('创建时间'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 列表内容
                        Expanded(
                          child: receivers.isEmpty
                              ? const Center(child: Text('暂无数据'))
                              : Scrollbar(
                                  child: SingleChildScrollView(
                                    child: Table(
                                      columnWidths: const {
                                        0: FlexColumnWidth(0.8),
                                        1: FlexColumnWidth(3.0),
                                        2: FlexColumnWidth(2.5),
                                        3: FlexColumnWidth(1.0),
                                        4: FlexColumnWidth(2.0),
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
                                            _buildDataCell(item.count.toString()),
                                            _buildDataCell(item.createTime),
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCheckboxCell(String receiverId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Checkbox(
        value: _selectedForbiddenIds.contains(receiverId),
        onChanged: (value) => _toggleReceiverSelection(receiverId),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
} 