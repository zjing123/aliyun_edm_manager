import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/sender/sender_name_provider.dart';
import 'package:aliyun_edm_manager/models/sender/sender_name_model.dart';
import 'package:aliyun_edm_manager/pages/sender/sender_name_create_page.dart';
import 'package:aliyun_edm_manager/pages/sender/sender_name_edit_page.dart';
import 'package:aliyun_edm_manager/utils/dialog_util.dart';

// 发送人名称列表状态封装类
class _SenderNameListState {
  final bool isLoading;
  final String? error;
  final bool senderNamesEmpty;
  final bool hasExistingSenderNames;

  _SenderNameListState({
    required this.isLoading,
    required this.error,
    required this.senderNamesEmpty,
    required this.hasExistingSenderNames,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SenderNameListState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.senderNamesEmpty == senderNamesEmpty &&
        other.hasExistingSenderNames == hasExistingSenderNames;
  }

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode ^ senderNamesEmpty.hashCode ^ hasExistingSenderNames.hashCode;
}

class SenderNameListPage extends StatefulWidget {
  const SenderNameListPage({super.key});

  @override
  State<SenderNameListPage> createState() => _SenderNameListPageState();
}

class _SenderNameListPageState extends State<SenderNameListPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  void _reloadList() {
    context.read<SenderNameProvider>().refreshAndClearCache();
  }

  void _showCreateDialog() {
    final provider = context.read<SenderNameProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _SenderNameDialog(
          title: '新建发送人名称',
          provider: provider,
          onSave: (name, isDefault) async {
            final success = await provider.createSenderName(
              name, 
              isDefault: isDefault ? 1 : 0
            );
            if (success && mounted) {
              // 如果设置为默认，需保证唯一性
              if (isDefault) {
                try {
                  final list = provider.senderNames;
                  final created = list.firstWhere((e) => e.name == name);
                  await provider.setDefaultSenderName(created.id);
                } catch (_) {}
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('发送人名称创建成功')),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage ?? '创建失败'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _showEditDialog(SenderNameModel senderName) {
    final provider = context.read<SenderNameProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _SenderNameDialog(
          title: '编辑发送人名称',
          provider: provider,
          initialName: senderName.name,
          initialIsDefault: senderName.isDefault == 1,
          onSave: (name, isDefault) async {
            final success = await provider.updateSenderName(
              senderName.id,
              name,
              isDefault: isDefault ? 1 : 0
            );
            if (success && mounted) {
              // 如果设置为默认，需保证唯一性
              if (isDefault) {
                await provider.setDefaultSenderName(senderName.id);
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('发送人名称更新成功')),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage ?? '更新失败'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(SenderNameModel senderName) async {
    final confirmed = await DialogUtil.confirm(
      context,
      '确定要删除发送人名称"${senderName.name}"吗？此操作不可恢复。',
    );

    if (confirmed == true) {
      final success = await context.read<SenderNameProvider>().deleteSenderName(senderName.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发送人名称删除成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发送人名称删除失败')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildPage();
  }

  Widget _buildPage() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("发送人名称管理"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
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
                  '发送人名称管理',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 批量操作和新建按钮
                Row(
                  children: [
                    // 批量删除按钮
                    Selector<SenderNameProvider, bool>(
                      selector: (context, provider) => provider.hasSelection,
                      builder: (context, hasSelection, child) {
                        if (!hasSelection) return SizedBox.shrink();
                        
                        return Row(
                          children: [
                            Text(
                              '已选择 ${context.watch<SenderNameProvider>().selectedCount} 项',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _showBatchDeleteDialog,
                              icon: Icon(Icons.delete, size: 16),
                              label: Text('批量删除'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        );
                      },
                    ),
                    // 新建按钮
                    ElevatedButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('新建发送人名称'),
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
                    '1. 此页面显示所有发送人名称，支持创建、编辑、删除操作。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '2. 点击"新建发送人名称"按钮可以创建新的发送人名称。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '3. 发送人名称用于邮件发送时的发送人显示。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 发送人名称列表
            Expanded(
              child: _buildSenderNameListSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderNameListSelector() {
    return Selector<SenderNameProvider, _SenderNameListState>(
      selector: (context, provider) => _SenderNameListState(
        isLoading: provider.isLoading,
        error: provider.errorMessage,
        senderNamesEmpty: provider.senderNames.isEmpty,
        hasExistingSenderNames: provider.senderNames.isNotEmpty,
      ),
      builder: (context, state, child) {
        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _reloadList,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (state.senderNamesEmpty && !state.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无发送人名称',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击"新建发送人名称"按钮创建第一个发送人名称',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showCreateDialog,
                  child: const Text('新建发送人名称'),
                ),
              ],
            ),
          );
        }

        return _buildSenderNameList();
      },
    );
  }

  Widget _buildSenderNameList() {
    return Selector<SenderNameProvider, List<SenderNameModel>>(
      selector: (context, provider) => provider.senderNames,
      builder: (context, senderNames, child) {
        return Column(
          children: [
            // 表格头部
            _buildTableHeader(),
            const SizedBox(height: 10),
            // 表格内容
            Expanded(
              child: _buildTableContent(),
            ),
            // 分页控件
            _buildPagination(),
          ],
        );
      },
    );
  }

  Widget _buildPagination() {
    return Selector<SenderNameProvider, Map<String, dynamic>>(
      selector: (context, provider) => {
        'currentPage': provider.currentPage,
        'totalPages': provider.totalPages,
        'totalCount': provider.totalCount,
        'pageSize': provider.pageSize,
      },
      builder: (context, pagination, child) {
        final currentPage = pagination['currentPage'] as int;
        final totalPages = pagination['totalPages'] as int;
        final totalCount = pagination['totalCount'] as int;

        if (totalPages <= 1) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '共 $totalCount 条记录，第 $currentPage/$totalPages 页',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Row(
                children: [
                  // 首页按钮
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: currentPage > 1
                        ? () => context.read<SenderNameProvider>().firstPage()
                        : null,
                    tooltip: '首页',
                  ),
                  // 上一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 1
                        ? () => context.read<SenderNameProvider>().previousPage()
                        : null,
                    tooltip: '上一页',
                  ),
                  // 页码显示和输入
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Text(
                          '第 ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: TextEditingController(text: '$currentPage'),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              final page = int.tryParse(value);
                              if (page != null && page >= 1 && page <= totalPages) {
                                context.read<SenderNameProvider>().goToPage(page);
                              } else {
                                // 如果输入的页码无效，显示提示并重置输入框
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('请输入有效的页码（1-$totalPages）'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                // 重置输入框为当前页码
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        Text(
                          ' 页，共 $totalPages 页',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // 下一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: currentPage < totalPages
                        ? () => context.read<SenderNameProvider>().nextPage()
                        : null,
                    tooltip: '下一页',
                  ),
                  // 末页按钮
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: currentPage < totalPages
                        ? () => context.read<SenderNameProvider>().lastPage()
                        : null,
                    tooltip: '末页',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Selector<SenderNameProvider, bool>(
      selector: (context, provider) => provider.isAllSelected,
      builder: (context, isAllSelected, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: isAllSelected,
                  onChanged: (value) {
                    context.read<SenderNameProvider>().toggleSelectAll();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    '发送人名称',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '默认',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    '创建时间',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    '操作',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableContent() {
    return Selector<SenderNameProvider, Map<String, dynamic>>(
      selector: (context, provider) => {
        'senderNames': provider.senderNames,
        'isLoading': provider.isLoading,
      },
      builder: (context, data, child) {
        final senderNames = data['senderNames'] as List<SenderNameModel>;
        final isLoading = data['isLoading'] as bool;
        
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                itemCount: senderNames.length,
                itemBuilder: (context, index) {
                  final senderName = senderNames[index];
                  return _buildSenderNameRow(senderName, index);
                },
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSenderNameRow(SenderNameModel senderName, int index) {
    return Selector<SenderNameProvider, bool>(
      selector: (context, provider) => provider.isSenderNameSelected(senderName.id),
      builder: (context, isSelected, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    context.read<SenderNameProvider>().toggleSenderNameSelection(senderName.id);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    senderName.name,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    senderName.isDefault == 1 ? 'Yes' : 'No',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    senderName.formattedCreateTime(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 设为默认/取消默认Icon
                      IconButton(
                        icon: Icon(
                          Icons.star,
                          size: 20,
                          color: senderName.isDefault == 1 ? Colors.amber : Colors.grey[400],
                        ),
                        tooltip: senderName.isDefault == 1 ? '取消默认发送人' : '设为默认发送人',
                        onPressed: () async {
                          final provider = context.read<SenderNameProvider>();
                          bool success = false;
                          if (senderName.isDefault == 1) {
                            success = await provider.unsetDefaultSenderName(senderName.id);
                          } else {
                            success = await provider.setDefaultSenderName(senderName.id);
                          }
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(senderName.isDefault == 1 ? '已取消默认发送人' : '已设为默认发送人名称')),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.errorMessage ?? '操作失败'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showEditDialog(senderName),
                        tooltip: '编辑',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _showDeleteDialog(senderName),
                        tooltip: '删除',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 显示批量删除确认对话框
  void _showBatchDeleteDialog() {
    final provider = context.read<SenderNameProvider>();
    final selectedCount = provider.selectedCount;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text('批量删除确认'),
            ],
          ),
          content: Text(
            '确定要删除选中的 $selectedCount 个发送人名称吗？\n\n此操作不可恢复，请谨慎操作。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performBatchDelete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('确认删除'),
            ),
          ],
        );
      },
    );
  }
  
  // 执行批量删除
  Future<void> _performBatchDelete() async {
    final provider = context.read<SenderNameProvider>();
    
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text('正在删除发送人名称...'),
              ],
            ),
          );
        },
      );
      
      // 执行批量删除
      final success = await provider.deleteSelectedSenderNames();
      
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      if (success) {
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批量删除成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批量删除失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('批量删除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// 发送人名称弹窗组件
class _SenderNameDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final bool? initialIsDefault;
  final Function(String name, bool isDefault) onSave;
  final SenderNameProvider provider;

  const _SenderNameDialog({
    required this.title,
    this.initialName,
    this.initialIsDefault,
    required this.onSave,
    required this.provider,
  });

  @override
  State<_SenderNameDialog> createState() => _SenderNameDialogState();
}

class _SenderNameDialogState extends State<_SenderNameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _isDefault = widget.initialIsDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSave(_nameController.text.trim(), _isDefault);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 卡片标题
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person, color: Colors.blue[600], size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '发送人信息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 发送人名称输入框
                    Text(
                      '发送人名称',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: '请输入发送人名称',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入发送人名称';
                        }
                        if (value.trim().length < 2) {
                          return '发送人名称至少2个字符';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // 默认设置
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '设为默认发送人',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '将此发送人名称设为默认发送人',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isDefault,
                            onChanged: (value) {
                              setState(() {
                                _isDefault = value;
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 操作按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  '保存',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 