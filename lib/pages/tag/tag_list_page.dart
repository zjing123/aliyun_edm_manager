import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/tag/tag_provider.dart';
import 'package:aliyun_edm_manager/models/tag/email_tag_model.dart';
import 'package:aliyun_edm_manager/pages/config/config_page.dart';
import 'package:aliyun_edm_manager/utils/dialog_util.dart';

// 标签列表状态封装类
class _TagListState {
  final bool isLoading;
  final String? error;
  final bool tagsEmpty;
  final bool hasExistingTags;

  _TagListState({
    required this.isLoading,
    required this.error,
    required this.tagsEmpty,
    required this.hasExistingTags,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TagListState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.tagsEmpty == tagsEmpty &&
        other.hasExistingTags == hasExistingTags;
  }

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode ^ tagsEmpty.hashCode ^ hasExistingTags.hashCode;
}

class TagListPage extends StatefulWidget {
  const TagListPage({super.key});

  @override
  State<TagListPage> createState() => _TagListPageState();
}

class _TagListPageState extends State<TagListPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TagProvider>().refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TagProvider>().refresh();
    });
  }

  void _reloadList() {
    context.read<TagProvider>().refreshAndClearCache();
  }

  void _openConfigPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ConfigPage()),
    );
    
    if (result == true) {
      _reloadList();
    }
  }

  void _showCreateDialog() {
    _showTagDialog();
  }

  void _showEditDialog(EmailTagModel tag) {
    _showTagDialog(tag: tag);
  }

  void _showTagDialog({EmailTagModel? tag}) {
    final isEdit = tag != null;
    final provider = context.read<TagProvider>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _TagDialog(
          title: isEdit ? '编辑标签' : '新建标签',
          initialTagName: tag?.tagName,
          initialDescription: tag?.description,
          isEdit: isEdit,
          tagId: tag?.tagId,
          onSave: (tagName, description) async {
            bool success;
            if (isEdit) {
              success = await provider.modifyTag(
                tagId: tag.tagId,
                tagName: tagName,
                tagDescription: description.isEmpty ? null : description,
              );
            } else {
              success = await provider.createTag(
                tagName: tagName,
                tagDescription: description.isEmpty ? null : description,
              );
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success 
                      ? (isEdit ? '邮件标签修改成功' : '邮件标签创建成功')
                      : (isEdit ? '邮件标签修改失败' : '邮件标签创建失败')),
                ),
              );
            }
          },
          provider: provider,
        );
      },
    );
  }

  Future<void> _showDeleteDialog(EmailTagModel tag) async {
    final confirmed = await DialogUtil.confirm(
      context,
      '确定要删除邮件标签"${tag.tagName}"吗？此操作不可恢复。',
    );

    if (confirmed == true) {
      final success = await context.read<TagProvider>().deleteTag(
        tagId: tag.tagId,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('邮件标签"${tag.tagName}"删除成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('邮件标签"${tag.tagName}"删除失败'),
              backgroundColor: Colors.red,
            ),
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
        title: const Text("邮件标签管理"),
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
                  '邮件标签管理',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 批量操作和新建按钮
                Row(
                  children: [
                    // 批量删除按钮
                    Selector<TagProvider, bool>(
                      selector: (context, provider) => provider.hasSelection,
                      builder: (context, hasSelection, child) {
                        if (!hasSelection) return SizedBox.shrink();
                        
                        return Row(
                          children: [
                            Text(
                              '已选择 ${context.watch<TagProvider>().selectedCount} 项',
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
                      label: const Text('新建标签'),
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
                    '1. 此页面显示所有邮件标签，支持创建、编辑、删除操作。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '2. 点击"新建邮件标签"按钮可以创建新的邮件标签。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '3. 邮件标签用于对邮件内容进行分类和管理。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 邮件标签列表
            Expanded(
              child: _buildTagListSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagListSelector() {
    return Selector<TagProvider, _TagListState>(
      selector: (context, provider) => _TagListState(
        isLoading: provider.isLoading,
        error: provider.error,
        tagsEmpty: provider.tags.isEmpty,
        hasExistingTags: provider.tags.isNotEmpty,
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

        if (state.tagsEmpty && !state.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.label, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无邮件标签',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击"新建邮件标签"按钮创建第一个邮件标签',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showCreateDialog,
                  child: const Text('新建邮件标签'),
                ),
              ],
            ),
          );
        }

        return _buildTagList();
      },
    );
  }

  Widget _buildTagList() {
    return Selector<TagProvider, List<EmailTagModel>>(
      selector: (context, provider) => provider.tags,
      builder: (context, tags, child) {
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
    return Selector<TagProvider, Map<String, dynamic>>(
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
                        ? () => context.read<TagProvider>().firstPage()
                        : null,
                    tooltip: '首页',
                  ),
                  // 上一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 1
                        ? () => context.read<TagProvider>().previousPage()
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
                                context.read<TagProvider>().goToPage(page);
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
                        ? () => context.read<TagProvider>().nextPage()
                        : null,
                    tooltip: '下一页',
                  ),
                  // 末页按钮
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: currentPage < totalPages
                        ? () => context.read<TagProvider>().lastPage()
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
    return Selector<TagProvider, bool>(
      selector: (context, provider) => provider.selectAll,
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
                    context.read<TagProvider>().toggleSelectAll();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    '标签名称',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    '标签说明',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
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
    return Selector<TagProvider, Map<String, dynamic>>(
      selector: (context, provider) => {
        'tags': provider.tags,
        'isLoading': provider.isLoading,
      },
      builder: (context, data, child) {
        final tags = data['tags'] as List<EmailTagModel>;
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
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  return _buildTagRow(tag, index);
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

  Widget _buildTagRow(EmailTagModel tag, int index) {
    return Selector<TagProvider, bool>(
      selector: (context, provider) => provider.isTagSelected(tag.tagId),
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
                    context.read<TagProvider>().toggleTagSelection(tag.tagId);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    tag.tagName,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    tag.description ?? '暂无说明',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showEditDialog(tag),
                        tooltip: '编辑',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _showDeleteDialog(tag),
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
    final provider = context.read<TagProvider>();
    final selectedCount = provider.selectedCount;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        "批量删除确认",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // 内容区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Text(
                    '确定要删除选中的 $selectedCount 个邮件标签吗？\n\n此操作不可恢复，请谨慎操作。',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                // 操作按钮
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          "取消",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _performBatchDelete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "确认删除",
                          style: TextStyle(fontSize: 16),
                        ),
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
  
  // 执行批量删除
  Future<void> _performBatchDelete() async {
    final provider = context.read<TagProvider>();
    final selectedCount = provider.selectedCount; // 保存删除前的数量
    BuildContext? dialogContext; // 保存弹窗context

    try {
      // 显示加载对话框，并保存弹窗context
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          dialogContext = ctx;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '正在删除邮件标签...\n请稍候，不要关闭应用',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      );
      
      // 执行批量删除
      final success = await provider.deleteSelectedTags();
      
      // 用弹窗的context关闭加载对话框
      if (dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }
      
      if (success) {
        // 显示成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('批量删除成功，共删除 $selectedCount 个邮件标签'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 显示错误消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('批量删除失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 用弹窗的context关闭加载对话框
      if (dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }
      
      // 显示错误消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批量删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _TagDialog extends StatefulWidget {
  final String title;
  final String? initialTagName;
  final String? initialDescription;
  final bool isEdit;
  final String? tagId;
  final Function(String tagName, String description) onSave;
  final TagProvider provider;

  const _TagDialog({
    required this.title,
    this.initialTagName,
    this.initialDescription,
    required this.isEdit,
    this.tagId,
    required this.onSave,
    required this.provider,
  });

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tagNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tagNameController.text = widget.initialTagName ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
  }

  @override
  void dispose() {
    _tagNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final tagName = _tagNameController.text.trim();
    final description = _descriptionController.text.trim();

    // 检查是否有实际修改
    if (widget.isEdit) {
      final originalTagName = widget.initialTagName ?? '';
      final originalDescription = widget.initialDescription ?? '';
      
      if (tagName == originalTagName && description == originalDescription) {
        // 没有修改任何信息，只显示提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未修改任何信息'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSave(tagName, description);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
      backgroundColor: Colors.transparent,
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                          child: Icon(Icons.label, color: Colors.blue[600], size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '标签信息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 标签名称输入框
                    Text(
                      '标签名称',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tagNameController,
                      decoration: InputDecoration(
                        hintText: '请输入标签名称',
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
                          return '请输入标签名称';
                        }
                        final trimmedValue = value.trim();
                        if (trimmedValue.length < 1) {
                          return '标签名称至少1个字符';
                        }
                        if (trimmedValue.length > 50) {
                          return '标签名称不能超过50个字符';
                        }
                        // 检查字符格式：只允许英文字母、数字、_、-
                        final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
                        if (!validPattern.hasMatch(trimmedValue)) {
                          return '标签名称只能包含英文字母、数字、下划线(_)、连字符(-)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '标签名称要求：1-50个字符，仅限英文字母、数字、下划线(_)、连字符(-)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 标签说明输入框
                    Text(
                      '标签说明',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: '请输入标签说明（可选）',
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
                      maxLines: 3,
                      validator: (value) {
                        if (value != null && value.length > 100) {
                          return '标签说明不能超过100个字符';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '标签说明：可选，最多100个字符',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
                                  widget.isEdit ? '保存' : '创建',
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