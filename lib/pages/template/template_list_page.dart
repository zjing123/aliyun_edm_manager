import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/template/template_provider.dart';
import 'package:aliyun_edm_manager/models/template/template_model.dart';
import 'package:aliyun_edm_manager/pages/config/config_page.dart';
import 'package:aliyun_edm_manager/pages/template/template_create_page.dart';
import 'package:aliyun_edm_manager/pages/template/template_edit_page.dart';
import 'package:aliyun_edm_manager/utils/dialog_util.dart';

// 模板列表状态封装类
class _TemplateListState {
  final bool isLoading;
  final String? error;
  final bool templatesEmpty;
  final bool hasExistingTemplates;

  _TemplateListState({
    required this.isLoading,
    required this.error,
    required this.templatesEmpty,
    required this.hasExistingTemplates,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TemplateListState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.templatesEmpty == templatesEmpty &&
        other.hasExistingTemplates == hasExistingTemplates;
  }

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode ^ templatesEmpty.hashCode ^ hasExistingTemplates.hashCode;
}

class TemplateListPage extends StatefulWidget {
  const TemplateListPage({super.key});

  @override
  State<TemplateListPage> createState() => _TemplateListPageState();
}

class _TemplateListPageState extends State<TemplateListPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().refresh();
    });
  }

  void _reloadList() {
    context.read<TemplateProvider>().refresh();
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TemplateCreatePage()),
    ).then((_) {
      // 返回时刷新列表
      _reloadList();
    });
  }

  void _showEditDialog(TemplateModel template) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TemplateEditPage(template: template)),
    ).then((_) {
      // 返回时刷新列表
      _reloadList();
    });
  }

  Future<void> _showDeleteDialog(TemplateModel template) async {
    final confirmed = await DialogUtil.confirm(
      context,
      '确定要删除模板"${template.templateName}"吗？此操作不可恢复。',
    );

    if (confirmed == true) {
      final success = await context.read<TemplateProvider>().deleteTemplate(
        templateId: int.parse(template.templateId),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模板删除成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模板删除失败')),
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
        title: const Text("邮件模板管理"),
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
                  '邮件模板管理',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 批量操作和新建按钮
                Row(
                  children: [
                    // 批量删除按钮
                    Selector<TemplateProvider, bool>(
                      selector: (context, provider) => provider.hasSelection,
                      builder: (context, hasSelection, child) {
                        if (!hasSelection) return SizedBox.shrink();
                        
                        return Row(
                          children: [
                            Text(
                              '已选择 ${context.watch<TemplateProvider>().selectedCount} 项',
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
                      label: const Text('新建模板'),
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
                    '1. 此页面显示所有邮件模板，支持创建、编辑、删除操作。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '2. 点击"新建模板"按钮可以创建新的邮件模板。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '3. 模板创建后需要等待审核通过才能使用。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 模板列表
            Expanded(
              child: _buildTemplateListSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateListSelector() {
    return Selector<TemplateProvider, _TemplateListState>(
      selector: (context, provider) => _TemplateListState(
        isLoading: provider.isLoading,
        error: provider.error,
        templatesEmpty: provider.templates.isEmpty,
        hasExistingTemplates: provider.templates.isNotEmpty,
      ),
      builder: (context, state, child) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

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

        if (state.templatesEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无模板',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击"新建模板"按钮创建第一个模板',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showCreateDialog,
                  child: const Text('新建模板'),
                ),
              ],
            ),
          );
        }

        return _buildTemplateList();
      },
    );
  }

  Widget _buildTemplateList() {
    return Selector<TemplateProvider, List<TemplateModel>>(
      selector: (context, provider) => provider.templates,
      builder: (context, templates, child) {
        return Column(
          children: [
            // 模板列表表格
            Expanded(
              child: Column(
                children: [
                  // 表格头部
                  _buildTableHeader(),
                  const SizedBox(height: 10),
                  // 表格内容
                  Expanded(
                    child: _buildTableContent(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 分页控件
            _buildPagination(),
          ],
        );
      },
    );
  }

  Widget _buildPagination() {
    return Selector<TemplateProvider, Map<String, dynamic>>(
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
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
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
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 1
                        ? () => context.read<TemplateProvider>().previousPage()
                        : null,
                  ),
                  Text('$currentPage'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: currentPage < totalPages
                        ? () => context.read<TemplateProvider>().nextPage()
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '0': // 审核中
        return Colors.orange;
      case '1': // 审核通过
        return Colors.green;
      case '2': // 审核未通过
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTableHeader() {
    return Selector<TemplateProvider, bool>(
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
                    context.read<TemplateProvider>().toggleSelectAll();
                  },
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    '模板类型',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '模板名称',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '审核状态',
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
    return Selector<TemplateProvider, List<TemplateModel>>(
      selector: (context, provider) => provider.templates,
      builder: (context, templates, child) {
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
          child: ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateRow(template, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildTemplateRow(TemplateModel template, int index) {
    return Selector<TemplateProvider, bool>(
      selector: (context, provider) => provider.isTemplateSelected(template.templateId),
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
                    context.read<TemplateProvider>().toggleTemplateSelection(template.templateId);
                  },
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    '邮件',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    template.templateName,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildStatusChip(template),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    template.createTime,
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
                        onPressed: () => _showEditDialog(template),
                        tooltip: '编辑',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _showDeleteDialog(template),
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

  Widget _buildStatusChip(TemplateModel template) {
    Color chipColor = _getStatusColor(template.templateStatus);
    
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        template.statusDescription,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  // 显示批量删除确认对话框
  void _showBatchDeleteDialog() {
    final provider = context.read<TemplateProvider>();
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
            '确定要删除选中的 $selectedCount 个模板吗？\n\n此操作不可恢复，请谨慎操作。',
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
    final provider = context.read<TemplateProvider>();
    
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
                Text('正在删除模板...'),
              ],
            ),
          );
        },
      );
      
      // 执行批量删除
      final success = await provider.deleteSelectedTemplates();
      
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