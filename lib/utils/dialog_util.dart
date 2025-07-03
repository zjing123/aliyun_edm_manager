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
    final columnWidths = {
      0: FlexColumnWidth(3), // 创建时间
      1: FlexColumnWidth(5), // Email
      2: FlexColumnWidth(4), // dataSchema合并列
      3: FixedColumnWidth(100), // 操作
    };

    print(_detail?.dataSchema);
    return AlertDialog(
      title: Text('编辑收件人列表'),
      content: SizedBox(
        width: 700,
        height: 500,
        child: Column(
            children: [
              // 搜索和新建
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Email地址',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                      onSubmitted: (value) => _onSearch(),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _onSearch,
                    child: Text('查询'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _onCreate,
                    child: Text('新建'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // 固定表头
              Container(
                color: Colors.grey[200],
                child: Table(
                  columnWidths: columnWidths,
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('创建时间', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            '{${_detail?.dataSchema.join('},{')}}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('操作', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 滚动内容
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredMembers.isEmpty
                        ? Center(child: Text(_error ?? '暂无数据'))
                        : SingleChildScrollView(
                            child: Table(
                              columnWidths: columnWidths,
                              border: TableBorder(
                                bottom: BorderSide(color: Colors.grey.shade300),
                                horizontalInside: BorderSide(color: Colors.grey.shade300),
                              ),
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                ..._filteredMembers.map((member) {
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(_formatBeijingTime(member.createTime) ?? '', overflow: TextOverflow.ellipsis),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Tooltip(
                                          message: member.email ?? '',
                                          child: SelectableText(
                                            member.email ?? '',
                                            maxLines: 1,
                                            showCursor: false,
                                            cursorWidth: 0,
                                            style: TextStyle(overflow: TextOverflow.ellipsis),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(
                                          (member.data ?? '').split(',').join(', '),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: TextButton(
                                          onPressed: () => _onDelete(member.email ?? ''),
                                          child: Text('删除'),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
              ),
              SizedBox(height: 8),
              // 加载更多
              if (_hasMore) 
                ElevatedButton(
                  onPressed: _loadingMore ? null : _onLoadMore,
                  child: _loadingMore
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('加载更多'),
                ),
            ],
          ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onClose?.call();
          },
          child: Text('关闭'),
        ),
      ],
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