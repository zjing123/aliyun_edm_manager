import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/utils/dialog_util.dart';
import 'package:aliyun_edm_manager/providers/receiver/receiver_list_provider.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_list_model.dart';
import 'package:aliyun_edm_manager/pages/config/config_page.dart';
import 'receiver_detail_page.dart';
import 'batch_create_receiver_page.dart';
import 'forbidden_delete_settings_page.dart';
import 'package:flutter/services.dart'; // Added for FilteringTextInputFormatter

// 收件人列表状态封装类
class _ReceiverListState {
  final bool isLoading;
  final String? error;
  final bool receiversEmpty;
  final bool hasExistingReceivers;

  _ReceiverListState({
    required this.isLoading,
    required this.error,
    required this.receiversEmpty,
    required this.hasExistingReceivers,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ReceiverListState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.receiversEmpty == receiversEmpty &&
        other.hasExistingReceivers == hasExistingReceivers;
  }

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode ^ receiversEmpty.hashCode ^ hasExistingReceivers.hashCode;
}

class _CreateReceiverDialog extends StatefulWidget {
  final List<String> existingNames;
  const _CreateReceiverDialog({Key? key, required this.existingNames}) : super(key: key);

  @override
  State<_CreateReceiverDialog> createState() => _CreateReceiverDialogState();
}

class _CreateReceiverDialogState extends State<_CreateReceiverDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aliasController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  String? nameError;
  String? aliasError;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    aliasController.dispose();
    descController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final name = nameController.text.trim();
      final alias = aliasController.text.trim();
      final desc = descController.text.trim();
      Navigator.pop(context, {
        'name': name,
        'alias': alias,
        'desc': desc.isEmpty ? '新建收件人列表' : desc,
      });
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
                        child: Icon(Icons.list_alt, color: Colors.blue[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '收件人列表信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 列表名称输入框
                  Row(
                    children: [
                      Text(
                        '收件人列表名称',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "请输入收件人列表名称（1-30个字符）",
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
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.list_alt),
                      errorText: nameError,
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    enableIMEPersonalizedLearning: true,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        final trimmedValue = value.trim();
                        if (trimmedValue.isEmpty) {
                          nameError = '列表名称不能为空';
                        } else if (trimmedValue.length > 30) {
                          nameError = '列表名称长度不能超过30个字符';
                        } else if (widget.existingNames.contains(trimmedValue.toLowerCase())) {
                          nameError = '列表名称已存在，请使用其他名称';
                        } else {
                          nameError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1-30个字符，不能重复',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  // 列表别称输入框
                  Row(
                    children: [
                      Text(
                        '列表别称',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: aliasController,
                    decoration: InputDecoration(
                      hintText: "请输入Email地址格式的别称",
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
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.alternate_email),
                      errorText: aliasError,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enableIMEPersonalizedLearning: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._%+-@]')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        if (value.trim().isEmpty) {
                          aliasError = '列表别称不能为空';
                        } else if (value.trim().length >= 30) {
                          aliasError = '列表别称长度必须小于30个字符';
                        } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
                          aliasError = '请输入有效的Email地址格式';
                        } else {
                          aliasError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email地址格式，长度小于30个字符',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  // 列表描述输入框
                  Text(
                    '列表描述',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      hintText: "请输入列表描述（可选）",
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
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.description),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    enableIMEPersonalizedLearning: false,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '可选，最多100个字符',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  // 操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                        onPressed: _isLoading || nameError != null || aliasError != null || nameController.text.trim().isEmpty || aliasController.text.trim().isEmpty
                            ? null
                            : _handleCreate,
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
                                '创建',
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
    );
  }
}

class ReceiverListPage extends StatefulWidget {
  const ReceiverListPage({super.key});

  @override
  State<ReceiverListPage> createState() => _ReceiverListPageState();
}

class _ReceiverListPageState extends State<ReceiverListPage> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final provider = context.read<ReceiverListProvider>();
    final selectedReceivers = provider.selectedReceivers;
    
    if (selectedReceivers.isEmpty) {
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
      "确认删除选中的 ${selectedReceivers.length} 个收件人列表吗？\n\n删除后这些列表及其所有收件人数据将无法恢复。"
    );
    
    if (confirm) {
      try {
        await context.read<ReceiverListProvider>().deleteReceivers(selectedReceivers.toList());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功删除 ${selectedReceivers.length} 个收件人列表'),
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

  void _createReceiver() async {
    showCreateReceiverDialog();
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

  void _openForbiddenDeleteSettingsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForbiddenDeleteSettingsPage()),
    );
    
    // 返回时重新加载列表以更新数据
    _reloadList();
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

  void showCreateReceiverDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _CreateReceiverDialog(
        existingNames: context.read<ReceiverListProvider>().receivers.map((r) => r.receiversName.toLowerCase()).toList(),
      ),
    );

    if (result != null) {
      try {
        final receiver = ReceiverListModel(
          receiverId: '', // 创建时ID为空，服务端会生成
          receiversName: result['name']!,
          receiversAlias: result['alias']!,
          desc: result['desc']!,
          count: 0,
          createTime: DateTime.now().toIso8601String(),
          isDeletable: true, // 新创建的列表默认可删除
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
                    Selector<ReceiverListProvider, bool>(
                      selector: (context, provider) => provider.selectedReceivers.isNotEmpty,
                      builder: (context, hasSelected, child) {
                        if (!hasSelected) return const SizedBox.shrink();
                        return Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _deleteSelectedReceivers,
                              icon: Icon(Icons.delete, color: Colors.white),
                              label: Text('删除选中(${context.read<ReceiverListProvider>().selectedReceivers.length})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        );
                      },
                    ),
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
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openForbiddenDeleteSettingsPage,
                      icon: const Icon(Icons.settings_applications, color: Colors.white),
                      label: const Text('禁止删除设置'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
                  Text(
                    '4. 标记为"只读"的收件人列表无法删除，只能查看详情。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 收件人列表
            Expanded(
              child: _buildReceiverListSelector(),
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

  Widget _buildReceiverListSelector() {
    return Selector<ReceiverListProvider, _ReceiverListState>(
      selector: (context, provider) => _ReceiverListState(
        isLoading: provider.isLoading,
        error: provider.error,
        receiversEmpty: provider.receivers.isEmpty,
        hasExistingReceivers: provider.receivers.isNotEmpty,
      ),
      builder: (context, state, child) {
        // 首次加载时显示完整的加载指示器
        if (state.isLoading && !state.hasExistingReceivers) {
          return const Center(child: CircularProgressIndicator());
        }
                  
        if (state.error != null) {
          final error = state.error!;
          print('Provider错误: $error'); // 添加调试信息
                    
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
                const Text(
                  '加载失败',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _reloadList,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }
                  
        if (state.receiversEmpty) {
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
                  '点击"新建收件人列表"按钮开始创建',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
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
          );
        }
                  
        return _buildOptimizedReceiverList();
      },
    );
  }

  Widget _buildOptimizedReceiverList() {
    return Column(
      children: [
        // 表格头部
        _buildTableHeader(),
        const SizedBox(height: 10),
        // 表格内容
        Expanded(
          child: _buildTableContent(),
        ),
        // 选中记录统计
        _buildSelectionStats(),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Selector<ReceiverListProvider, bool>(
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
                    // 只全选可删除的
                    context.read<ReceiverListProvider>().toggleSelectAll();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    '列表名称',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '别称地址',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '描述',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '总数',
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
    return Selector<ReceiverListProvider, List<ReceiverListModel>>(
      selector: (context, provider) => provider.receivers,
      builder: (context, receivers, child) {
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
          child: Scrollbar(
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: receivers.length,
              itemBuilder: (context, index) {
                final receiver = receivers[index];
                return _buildReceiverRow(receiver, index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiverRow(ReceiverListModel receiver, int index) {
    return Selector<ReceiverListProvider, bool>(
      selector: (context, provider) => provider.isReceiverSelected(receiver.receiverId),
      builder: (context, isSelected, child) {
        final canSelect = receiver.isDeletable;
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
                if (canSelect)
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      context.read<ReceiverListProvider>().toggleReceiverSelection(receiver.receiverId);
                    },
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Text(
                      '只读',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          receiver.receiversName,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    receiver.receiversAlias,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    receiver.desc ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    receiver.count.toString(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    receiver.formattedCreateTime(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () => _openDetailPage(receiver.receiverId, receiver.receiversName),
                        tooltip: '查看详情',
                      ),
                      if (receiver.isDeletable)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _deleteReceiver(receiver.receiverId, receiver.receiversName),
                          tooltip: '删除',
                        )
                      else
                        const SizedBox(width: 40), // 占位符，保持对齐
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

  Widget _buildSelectionStats() {
    return Selector<ReceiverListProvider, Set<String>>(
      selector: (context, provider) => provider.selectedReceivers,
      builder: (context, selectedReceivers, child) {
        if (selectedReceivers.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '已选中 ${selectedReceivers.length} 个收件人列表',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}