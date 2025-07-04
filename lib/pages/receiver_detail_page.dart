import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/receiver_detail.dart';
import '../services/aliyun_edm_service.dart';
import '../providers/global_config_provider.dart';
import '../utils/dialog_util.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ReceiverDetailPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ReceiverDetailPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ReceiverDetailPage> createState() => _ReceiverDetailPageState();
}

class _ReceiverDetailPageState extends State<ReceiverDetailPage> {
  AliyunEdmService? _service;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
    _scrollController.addListener(_onScroll);
    _fetchDetail();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      if (_hasMore && !_loadingMore && !_loading) {
        _onLoadMore();
      }
    }
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
      // 初始化服务
      if (_service == null) {
        final globalConfig = context.read<GlobalConfigProvider>();
        if (!globalConfig.isConfigured) {
          setState(() {
            _error = '阿里云AccessKey未配置，请先配置';
            _loading = false;
            _loadingMore = false;
          });
          return;
        }
        
        _service = AliyunEdmService();
        _service!.setGlobalConfigProvider(globalConfig);
      }

      final detail = await _service!.getReceiverDetail(
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
      0: const FlexColumnWidth(2.5),
      1: const FlexColumnWidth(3.0),
      2: const FlexColumnWidth(3.0),
      3: const FlexColumnWidth(1.5),
    };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('收件人详情 - ${widget.receiverName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '编辑收件人列表',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('新建收件人'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // 进一步减少垂直内边距
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
              ],
            ),
            const SizedBox(height: 24),
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
                                    controller: _scrollController,
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      child: Column(
                                        children: [
                                          if (_filteredMembers.isNotEmpty)
                                            Table(
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
                                          if (_loadingMore)
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    '加载更多数据...',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (!_hasMore && _filteredMembers.isNotEmpty && !_loading)
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              child: Text(
                                                '已加载全部数据',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                        ],
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
    if (!_hasMore || _loadingMore || _loading) {
      return;
    }
    
    if (_detail?.nextStart == null || _detail!.nextStart!.isEmpty) {
       return;
    }

    await _fetchDetail(nextStart: _detail!.nextStart!, append: true);
  }

  Future<void> _onSearch() async {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    await _fetchDetail(keyWord: _searchController.text);
  }

  Future<void> _onCreate() async {
    final result = await DialogUtil.inputReceiverDetail(context);
    if (result == null) return;

    final email = result['email'] as String;
    final dataMap = result['data'] as Map<String, String>;

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入有效的Email地址'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      // 确保服务已初始化
      if (_service == null) {
        final globalConfig = context.read<GlobalConfigProvider>();
        if (!globalConfig.isConfigured) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('阿里云AccessKey未配置，请先配置'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        _service = AliyunEdmService();
        _service!.setGlobalConfigProvider(globalConfig);
      }

      final receiverParams = ReceiverDetailParams.fromMap(email, dataMap);
      final response = await _service!.saveReceiverDetail(widget.receiverId, receiverParams);
      
      if (response.isSuccess) {
        final newMember = MemberDetail(
          email: email,
          data: dataMap.values.join(','),
          createTime: DateTime.now().toIso8601String(),
          utcCreateTime: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        
        setState(() {
          _allMembers.insert(0, newMember);
          
          if (_searchController.text.isNotEmpty) {
            if (email.toLowerCase().contains(_searchController.text.toLowerCase())) {
              _filteredMembers.insert(0, newMember);
            }
          } else {
            _filteredMembers.insert(0, newMember);
          }
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.getStatusMessage()),
          backgroundColor: response.isSuccess ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加收件人失败: $e')),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _onDelete(String email) async {
    if (email.isEmpty) return;
    
    final confirm = await DialogUtil.confirm(context, "确认删除该收件人 $email 吗？");
    if (!confirm) return;

    try {
      // 确保服务已初始化
      if (_service == null) {
        final globalConfig = context.read<GlobalConfigProvider>();
        if (!globalConfig.isConfigured) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('阿里云AccessKey未配置，请先配置'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        _service = AliyunEdmService();
        _service!.setGlobalConfigProvider(globalConfig);
      }

      await _service!.deleteReceiverDetail(widget.receiverId, email);
      
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
}
 