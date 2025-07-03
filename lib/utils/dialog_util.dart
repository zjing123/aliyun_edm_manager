import 'package:flutter/material.dart';
import '../models/receiver_detail.dart';
import '../services/aliyun_edm_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class DialogUtil {
  static Future<bool> confirm(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("确认操作"),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("取消")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("确定")),
            ],
          ),
        ) ??
        false;
  }

  static void showDetailDialog(BuildContext context, String receiverId) {
    showDialog(
      context: context,
      builder: (context) => ReceiverDetailDialog(receiverId: receiverId)
    );
  }

  static Future<String?> inputReceiverName(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("新建收件人列表"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "收件人列表名称"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("创建")),
        ],
      ),
    );
  }

  static Future<Map<String, dynamic>?> inputReceiverDetail(BuildContext context) {
    final emailController = TextEditingController();
    final fields = ReceiverDetailParams.fields;
    final fieldControllers = fields.map((f) => TextEditingController()).toList();
    String? emailError;

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("添加收件人"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email输入框
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email地址 *',
                    border: OutlineInputBorder(),
                    errorText: emailError,
                    helperText: '请输入有效的邮箱地址',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      if (value.trim().isEmpty) {
                        emailError = null;
                      } else if (!_isValidEmailStatic(value.trim())) {
                        emailError = '请输入有效的Email格式';
                      } else {
                        emailError = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                // 其他字段
                ...fields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: fieldControllers[index],
                      decoration: InputDecoration(
                        labelText: field.label,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text.trim();
                
                if (email.isEmpty) {
                  setState(() {
                    emailError = '请输入Email地址';
                  });
                  return;
                }
                
                if (!_isValidEmailStatic(email)) {
                  setState(() {
                    emailError = '请输入有效的Email格式';
                  });
                  return;
                }
                
                // 构建关联数组，字段名作为key，用户输入作为value
                final dataMap = <String, String>{};
                for (int i = 0; i < fields.length && i < fieldControllers.length; i++) {
                  final field = fields[i];
                  final fieldValue = fieldControllers[i].text.trim();
                  if (fieldValue.isNotEmpty) {
                    dataMap[field.field] = fieldValue;
                  }
                }
                
                Navigator.pop(context, {
                  'email': email,
                  'data': dataMap,
                });
              },
              child: const Text("确定"),
            ),
          ],
        ),
      ),
    );
  }

  // 静态方法用于对话框中的email验证
  static bool _isValidEmailStatic(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}

class ReceiverDetailDialog extends StatefulWidget {
  final String receiverId;
  final VoidCallback? onClose;

  const ReceiverDetailDialog({
    super.key,
    required this.receiverId,
    this.onClose,
  });

  @override
  State<ReceiverDetailDialog> createState() => _ReceiverDetailDialogState();
}

class _ReceiverDetailDialogState extends State<ReceiverDetailDialog> {
  final AliyunEDMService _service = AliyunEDMService();
  final TextEditingController _searchController = TextEditingController();
  ReceiverDetail? _detail;
  List<MemberDetail> _allMembers = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  Timer? _debounce;
  String _lastSearchText = '';
  List<MemberDetail> _filteredMembers = [];
  String? _nextStart;

  @override
  void initState() {
    super.initState();
    _lastSearchText = '';
    _searchController.addListener(_onSearchTextChanged);
    _fetchDetail();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail({
    String keyWord = '', 
    String nextStart = '', 
    bool append = false
  }) async {
    setState(() {
      if (!append) {
         _loading = true;
      }

      _error = null;

      if (append) {
         _loadingMore = true;
      }
    });

    try {
      final detail = await _service.getReceiverDetail(
        widget.receiverId,
        keyWord: keyWord,
        nextStart: nextStart,
      );

      setState(() {
        if (detail != null) {
          if (detail.members.isNotEmpty) {
            _detail = detail;
          } else {
            _detail?.setNextStart(null);
          }

          _hasMore = detail.nextStart != null 
                    && detail.nextStart!.isNotEmpty
                    && detail.members.isNotEmpty;

          if (append) {
            _allMembers.addAll(detail.members);
          } else {
            _allMembers = detail.members;
          }
        }
      
        _loading = false;
        _loadingMore = false;
      });

      // 如果有搜索关键词，则过滤数据
      if (_searchController.text.isNotEmpty) {
        _filteredMembers = _allMembers.where((member) => 
          member.email?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false
        ).toList();
      } else {
        _filteredMembers = List.from(_allMembers);
      }
    } catch (e) {
      setState(() {
        _error = '获取失败: $e';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  String? _formatBeijingTime(String? utcString) {
    if (utcString == null || utcString.isEmpty) {
       return '';
    }

    try {
      final utc = DateTime.parse(utcString).toUtc();
      final beijing = utc.add(Duration(hours: 8));
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(beijing);
    } catch (e) {
      return utcString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 1200 ? 1000.0 : screenWidth * 0.9;
    
    final columnWidths = {
      0: const FlexColumnWidth(2.5), // 创建时间
      1: const FlexColumnWidth(3.0), // Email
      2: const FlexColumnWidth(3.0), // dataSchema合并列
      3: const FlexColumnWidth(1.5), // 操作
    };

    print(_detail?.dataSchema);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: dialogWidth,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '编辑收件人列表',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onClose?.call();
                    },
                  ),
                ],
              ),
            ),
            // 内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 搜索和新建
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Email地址',
                              hintText: '请输入Email地址进行搜索',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            onSubmitted: (value) => _onSearch(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _onSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text('查询'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _onCreate,
                          icon: const Icon(Icons.add),
                          label: const Text('新建'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 表格容器
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
                                  columnWidths: columnWidths,
                                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                  children: [
                                    TableRow(
                                      children: [
                                        _buildHeaderCell('创建时间'),
                                        _buildHeaderCell('Email'),
                                        _buildHeaderCell('{${_detail?.dataSchema.join('},{') ?? ''}}'),
                                        _buildHeaderCell('操作', isRight: true),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // 可滚动的表体
                              Expanded(
                                child: _loading
                                    ? const Center(child: CircularProgressIndicator())
                                    : _filteredMembers.isEmpty
                                        ? Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(32.0),
                                              child: Text(
                                                _error ?? '暂无数据',
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
                                                columnWidths: columnWidths,
                                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                                children: _filteredMembers.asMap().entries.map((entry) {
                                                  final index = entry.key;
                                                  final member = entry.value;
                                                  final isLastRow = index == _filteredMembers.length - 1;
                                                  
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
                                                      _buildDataCell(_formatBeijingTime(member.createTime) ?? ''),
                                                      _buildDataCell(member.email ?? '', isEmail: true),
                                                      _buildDataCell((member.data ?? '').split(',').join(', ')),
                                                      _buildActionCell(
                                                        onDelete: () => _onDelete(member.email ?? ''),
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
                      ),
                    ),
                    // 加载更多按钮
                    if (_hasMore) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: _loadingMore ? null : _onLoadMore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _loadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('加载更多'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildDataCell(String text, {bool isEmail = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isEmail
          ? Tooltip(
              message: text,
              child: SelectableText(
                text,
                maxLines: 1,
                showCursor: false,
                cursorWidth: 0,
                style: const TextStyle(
                  fontSize: 14,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
    );
  }

  Widget _buildActionCell({required VoidCallback onDelete}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onDelete,
        child: const Text('删除', style: TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          minimumSize: const Size(40, 30),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Future<void> _onLoadMore() async {
    if (_detail?.nextStart == null || _detail!.nextStart!.isEmpty) {
       return;
    }

    await _fetchDetail(nextStart: _detail!.nextStart!, append: true);
  }

  Future<void> _onSearch() async {
    await _fetchDetail(keyWord: _searchController.text);
  }

  Future<void> _onCreate() async {
    final result = await DialogUtil.inputReceiverDetail(context);
    if (result == null) return;

    final email = result['email'] as String;
    final dataMap = result['data'] as Map<String, String>;

    // 验证email格式
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入有效的Email地址'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 检查email是否已存在
    if (_allMembers.any((member) => member.email?.toLowerCase() == email.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('该Email地址已存在'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // 使用新的工厂方法创建参数对象
      final receiverParams = ReceiverDetailParams.fromMap(email, dataMap);
      
      final response = await _service.saveReceiverDetail(widget.receiverId, receiverParams);
      
      // 根据响应结果处理
      if (response.isSuccess) {
        // 创建成功，添加到本地列表
        final newMember = MemberDetail(
          email: email,
          data: dataMap.values.join(','), // 为了兼容现有的MemberDetail结构
          createTime: DateTime.now().toIso8601String(),
          utcCreateTime: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        
        setState(() {
          _allMembers.insert(0, newMember); // 插入到列表顶部
          
          // 同时更新过滤后的列表
          if (_searchController.text.isNotEmpty) {
            // 如果有搜索条件，检查新成员是否符合搜索条件
            if (email.toLowerCase().contains(_searchController.text.toLowerCase())) {
              _filteredMembers.insert(0, newMember);
            }
          } else {
            // 如果没有搜索条件，直接添加到过滤列表
            _filteredMembers.insert(0, newMember);
          }
        });
      }
      
      // 显示详细的状态信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.getStatusMessage()),
          backgroundColor: response.isSuccess ? Colors.green : Colors.orange,
        ),
      );
      
      // 如果有失败或已存在的记录，显示详细信息
      if (response.hasFailed || response.hasExisted) {
        String details = '';
        if (response.hasExisted) {
          details += '已存在: ${response.existList?.join(', ') ?? ''}';
        }
        if (response.hasFailed) {
          if (details.isNotEmpty) details += '\n';
          details += '失败: ${response.failList?.join(', ') ?? ''}';
        }
        
        if (details.isNotEmpty) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('详细信息'),
              content: Text(details),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('确定'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加收件人失败: $e')),
      );
    }
  }

  // 验证email格式的辅助方法
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _onDelete(String email) async {
    if (email.isEmpty) return;
    
    final confirm = await DialogUtil.confirm(context, "确认删除该收件人 $email 吗？");
    if (!confirm) return;

    try {
      await _service.deleteReceiverDetail(widget.receiverId, email);
      
      // 删除成功，从本地列表中移除该成员
      setState(() {
        _allMembers.removeWhere((member) => member.email == email);
        _filteredMembers.removeWhere((member) => member.email == email);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  void _onSearchTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_lastSearchText.isNotEmpty && _searchController.text.isEmpty) {
        _fetchDetail();
      }
      _lastSearchText = _searchController.text;
    });
  }

  Future<void> _loadData({bool isLoadMore = false}) async {
    if (_loading || _loadingMore) return;

    setState(() {
      if (isLoadMore) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = null;
      }
    });

    try {
      final detail = await _service.getReceiverDetail(
        widget.receiverId,
        keyWord: _searchController.text.trim(),
        pageSize: 50,
        nextStart: isLoadMore ? _nextStart ?? '' : '',
      );

      if (detail != null) {
        setState(() {
          if (isLoadMore) {
            _allMembers.addAll(detail.members);
          } else {
            _allMembers = detail.members;
          }
          _nextStart = detail.nextStart;
          _loading = false;
          _loadingMore = false;
        });

        // 如果有搜索关键词，则过滤数据
        if (_searchController.text.isNotEmpty) {
          _filteredMembers = _allMembers.where((member) => 
            member.email?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false
          ).toList();
        } else {
          _filteredMembers = List.from(_allMembers);
        }
      } else {
        setState(() {
          _error = '获取数据失败';
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '获取数据失败: $e';
        _loading = false;
        _loadingMore = false;
      });
    }
  }
}