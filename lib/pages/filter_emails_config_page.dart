import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/page_config_provider.dart';
import '../utils/dialog_util.dart';

class FilterEmailsConfigPage extends StatefulWidget {
  const FilterEmailsConfigPage({super.key});

  @override
  State<FilterEmailsConfigPage> createState() => _FilterEmailsConfigPageState();
}

class _FilterEmailsConfigPageState extends State<FilterEmailsConfigPage> {
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterEmails = [];
  String _searchText = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFilterEmails();
  }

  @override
  void dispose() {
    _batchController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterEmails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pageConfig = context.read<PageConfigProvider>();
      final emails = pageConfig.filterEmails;
      setState(() {
        _filterEmails.clear();
        _filterEmails.addAll(emails);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载配置失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveFilterEmails() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final pageConfig = context.read<PageConfigProvider>();
      await pageConfig.setFilterEmails(_filterEmails);
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _batchAddEmails() {
    final input = _batchController.text;
    if (input.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入要批量添加的邮箱，每行一个'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final lines = input.split('\n');
    int added = 0, invalid = 0, duplicate = 0;
    for (final line in lines) {
      final email = line.trim();
      if (email.isEmpty) continue;
      if (!_isValidEmail(email)) {
        invalid++;
        continue;
      }
      if (_filterEmails.contains(email)) {
        duplicate++;
        continue;
      }
      _filterEmails.add(email);
      added++;
    }
    setState(() {});
    _batchController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('成功添加$added 个邮箱，$duplicate 个重复，$invalid 个无效'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeEmail(String email) {
    setState(() {
      _filterEmails.remove(email);
    });
  }

  void _clearAllEmails() async {
    final confirm = await DialogUtil.confirm(
      context,
      '确认清空所有过滤邮箱吗？\n\n此操作不可恢复。',
    );
    if (confirm) {
      setState(() {
        _filterEmails.clear();
      });
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  List<String> get _filteredEmails {
    if (_searchText.trim().isEmpty) return _filterEmails;
    return _filterEmails.where((e) => e.toLowerCase().contains(_searchText.trim().toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('过滤邮箱配置'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveFilterEmails,
              tooltip: '保存配置',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 页面标题
                  const Text(
                    '默认过滤邮箱配置',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              '功能说明',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• 配置的邮箱地址将在批量创建收件人列表时自动过滤\n'
                          '• 支持添加多个邮箱地址，每行一个\n'
                          '• 过滤邮箱不会出现在最终的收件人列表中\n'
                          '• 配置会持久化保存，下次使用时自动加载',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 添加邮箱区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.green[600], size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              '添加过滤邮箱',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _batchController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: '请输入要过滤的邮箱地址',
                                  hintText: '每行一个邮箱地址，可粘贴多行',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.list),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _batchAddEmails,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('添加'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 过滤邮箱列表
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.filter_list, color: Colors.orange[600], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '过滤邮箱列表 (${_filterEmails.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              if (_filterEmails.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _clearAllEmails,
                                  icon: const Icon(Icons.clear_all, color: Colors.red),
                                  label: const Text('清空全部', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: '搜索邮箱地址',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              setState(() {
                                _searchText = v;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_filteredEmails.isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.filter_list_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchText.trim().isEmpty ? '暂无过滤邮箱' : '无匹配结果',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchText.trim().isEmpty ? '请在上方添加需要过滤的邮箱地址' : '请修改搜索条件',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _filteredEmails.map((email) => Chip(
                                  label: Text(email),
                                  avatar: const Icon(Icons.email, size: 18, color: Colors.blue),
                                  backgroundColor: Colors.blue[50],
                                  labelStyle: const TextStyle(color: Colors.black87),
                                  deleteIcon: const Icon(Icons.close, color: Colors.blue),
                                  onDeleted: () => _removeEmail(email),
                                )).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 