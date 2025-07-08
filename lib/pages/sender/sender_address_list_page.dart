import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/sender/sender_address_provider.dart';
import 'package:aliyun_edm_manager/models/sender/sender_address_model.dart';
import 'package:aliyun_edm_manager/pages/config/config_page.dart';
import 'package:aliyun_edm_manager/pages/sender/sender_address_create_page.dart';
import 'package:aliyun_edm_manager/utils/dialog_util.dart';

// 发信地址列表状态封装类
class _SenderAddressListState {
  final bool isLoading;
  final String? error;
  final bool addressesEmpty;
  final bool hasExistingAddresses;

  _SenderAddressListState({
    required this.isLoading,
    required this.error,
    required this.addressesEmpty,
    required this.hasExistingAddresses,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SenderAddressListState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.addressesEmpty == addressesEmpty &&
        other.hasExistingAddresses == hasExistingAddresses;
  }

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode ^ addressesEmpty.hashCode ^ hasExistingAddresses.hashCode;
}

class SenderAddressListPage extends StatefulWidget {
  const SenderAddressListPage({super.key});

  @override
  State<SenderAddressListPage> createState() => _SenderAddressListPageState();
}

class _SenderAddressListPageState extends State<SenderAddressListPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SenderAddressProvider>().refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SenderAddressProvider>().refresh();
    });
  }

  void _reloadList() {
    context.read<SenderAddressProvider>().refreshAndClearCache();
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
      MaterialPageRoute(
        builder: (context) => const SenderAddressCreatePage(),
      ),
    ).then((_) {
      // 返回时刷新列表
      _reloadList();
    });
  }

  Future<void> _showDeleteDialog(SenderAddressModel address) async {
    final confirmed = await DialogUtil.confirm(
      context,
      '确定要删除发信地址"${address.accountName}"吗？此操作不可恢复。',
    );

    if (confirmed == true) {
      final success = await context.read<SenderAddressProvider>().deleteAddress(
        mailAddressId: int.parse(address.mailAddressId),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发信地址删除成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发信地址删除失败')),
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
        title: const Text("发信地址管理"),
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
                  '发信地址管理',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 批量操作和新建按钮
                Row(
                  children: [
                    // 批量删除按钮
                    Selector<SenderAddressProvider, bool>(
                      selector: (context, provider) => provider.hasSelection,
                      builder: (context, hasSelection, child) {
                        if (!hasSelection) return SizedBox.shrink();
                        
                        return Row(
                          children: [
                            Text(
                              '已选择 ${context.watch<SenderAddressProvider>().selectedCount} 项',
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
                      label: const Text('新建发信地址'),
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
                    '1. 此页面显示所有发信地址，支持创建、删除操作。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '2. 点击"新建发信地址"按钮可以创建新的发信地址。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '3. 发信地址创建后需要等待审核通过才能使用。',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 发信地址列表
            Expanded(
              child: _buildAddressListSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressListSelector() {
    return Selector<SenderAddressProvider, _SenderAddressListState>(
      selector: (context, provider) => _SenderAddressListState(
        isLoading: provider.isLoading,
        error: provider.error,
        addressesEmpty: provider.addresses.isEmpty,
        hasExistingAddresses: provider.addresses.isNotEmpty,
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

        if (state.addressesEmpty && !state.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无发信地址',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击"新建发信地址"按钮创建第一个发信地址',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showCreateDialog,
                  child: const Text('新建发信地址'),
                ),
              ],
            ),
          );
        }

        return _buildAddressList();
      },
    );
  }

  Widget _buildAddressList() {
    return Selector<SenderAddressProvider, List<SenderAddressModel>>(
      selector: (context, provider) => provider.addresses,
      builder: (context, addresses, child) {
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
    return Selector<SenderAddressProvider, Map<String, dynamic>>(
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
                        ? () => context.read<SenderAddressProvider>().firstPage()
                        : null,
                    tooltip: '首页',
                  ),
                  // 上一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 1
                        ? () => context.read<SenderAddressProvider>().previousPage()
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
                                context.read<SenderAddressProvider>().goToPage(page);
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
                        ? () => context.read<SenderAddressProvider>().nextPage()
                        : null,
                    tooltip: '下一页',
                  ),
                  // 末页按钮
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: currentPage < totalPages
                        ? () => context.read<SenderAddressProvider>().lastPage()
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
    return Selector<SenderAddressProvider, bool>(
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
                    context.read<SenderAddressProvider>().toggleSelectAll();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    '发信邮箱地址',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '回信地址',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '发信类型',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '账号状态',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '额度限制',
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
    return Selector<SenderAddressProvider, Map<String, dynamic>>(
      selector: (context, provider) => {
        'addresses': provider.addresses,
        'isLoading': provider.isLoading,
      },
      builder: (context, data, child) {
        final addresses = data['addresses'] as List<SenderAddressModel>;
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
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return _buildAddressRow(address, index);
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

  Widget _buildAddressRow(SenderAddressModel address, int index) {
    return Selector<SenderAddressProvider, bool>(
      selector: (context, provider) => provider.isAddressSelected(address.mailAddressId),
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
                    context.read<SenderAddressProvider>().toggleAddressSelection(address.mailAddressId);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    address.accountName,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    address.replyAddress,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: _buildSendTypeChip(address),
                ),
                SizedBox(
                  width: 80,
                  child: _buildStatusChip(address),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    address.quotaDescription,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _showDeleteDialog(address),
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

  Widget _buildSendTypeChip(SenderAddressModel address) {
    Color chipColor = _getSendTypeColor(address.sendType);
    
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        address.sendTypeDescription,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(SenderAddressModel address) {
    Color chipColor = _getStatusColor(address.accountStatus);
    
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        address.accountStatusDescription,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getSendTypeColor(String sendType) {
    switch (sendType) {
      case 'batch':
        return Colors.blue;
      case 'trigger':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '0': // 正常
        return Colors.green;
      case '1': // 冻结
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
  
  // 显示批量删除确认对话框
  void _showBatchDeleteDialog() {
    final provider = context.read<SenderAddressProvider>();
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
            '确定要删除选中的 $selectedCount 个发信地址吗？\n\n此操作不可恢复，请谨慎操作。',
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
    final provider = context.read<SenderAddressProvider>();
    
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
                Text('正在删除发信地址...'),
              ],
            ),
          );
        },
      );
      
      // 执行批量删除
      final success = await provider.deleteSelectedAddresses();
      
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