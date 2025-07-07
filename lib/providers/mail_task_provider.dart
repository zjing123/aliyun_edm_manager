import 'package:flutter/foundation.dart';
import '../models/mail_task_model.dart';
import '../services/aliyun_edm_service.dart';
import 'global_config_provider.dart';

class MailTaskProvider with ChangeNotifier {
  final AliyunEdmService _edmService;
  
  List<MailTaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;
  
  // 分页相关
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalCount = 0;
  int _totalPages = 0;
  
  // 选择相关
  Set<String> _selectedTaskIds = {};
  bool _selectAll = false;
  
  // 页面数据缓存 - 使用Map存储已加载的页面数据
  Map<String, List<MailTaskModel>> _pageCache = {};
  
  MailTaskProvider(this._edmService);
  
  List<MailTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 分页getter
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  
  // 选择getter
  Set<String> get selectedTaskIds => _selectedTaskIds;
  bool get selectAll => _selectAll;
  int get selectedCount => _selectedTaskIds.length;
  
  // 计算选中项目的请求数量总和
  int get selectedRequestCount {
    int total = 0;
    for (String taskId in _selectedTaskIds) {
      final task = _tasks.firstWhere((t) => t.taskId == taskId, orElse: () => MailTaskModel(
        taskId: '', taskName: '', addressType: '', tagName: '', receiversName: '', 
        templateName: '', requestCount: '0', successCount: '0', createTime: '', taskStatus: ''));
      if (task.taskId.isNotEmpty) {
        total += int.tryParse(task.requestCount) ?? 0;
      }
    }
    return total;
  }
  
  // 生成缓存键
  String _generateCacheKey({
    String? keyWord,
    String? status,
    int pageNo = 1,
    int pageSize = 20,
  }) {
    return '${keyWord ?? ''}_${status ?? ''}_${pageNo}_$pageSize';
  }
  
  // 检查缓存中是否有指定页面的数据
  bool _hasCachedData({
    String? keyWord,
    String? status,
    int pageNo = 1,
    int pageSize = 20,
  }) {
    final cacheKey = _generateCacheKey(
      keyWord: keyWord,
      status: status,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    return _pageCache.containsKey(cacheKey);
  }
  
  // 从缓存获取数据
  List<MailTaskModel>? _getCachedData({
    String? keyWord,
    String? status,
    int pageNo = 1,
    int pageSize = 20,
  }) {
    final cacheKey = _generateCacheKey(
      keyWord: keyWord,
      status: status,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    return _pageCache[cacheKey];
  }
  
  // 保存数据到缓存
  void _saveToCache({
    String? keyWord,
    String? status,
    int pageNo = 1,
    int pageSize = 20,
    required List<MailTaskModel> tasks,
  }) {
    final cacheKey = _generateCacheKey(
      keyWord: keyWord,
      status: status,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    _pageCache[cacheKey] = List.from(tasks);
  }
  
  // 清除缓存
  void _clearCache() {
    _pageCache.clear();
  }
  
  // 加载邮件任务列表
  Future<void> loadTasks({
    String? keyWord,
    String? status,
    int pageNo = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    // 检查缓存，如果存在且不强制刷新，直接使用缓存数据
    if (!forceRefresh && _hasCachedData(
      keyWord: keyWord,
      status: status,
      pageNo: pageNo,
      pageSize: pageSize,
    )) {
      final cachedTasks = _getCachedData(
        keyWord: keyWord,
        status: status,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      if (cachedTasks != null) {
        _tasks = cachedTasks;
        _currentPage = pageNo;
        _pageSize = pageSize;
        // 保持原有的总数和总页数
        notifyListeners();
        return;
      }
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _edmService.queryTaskByParam(
        keyWord: keyWord,
        status: status,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      _tasks = response.tasks;
      _currentPage = response.pageNumber;
      _pageSize = response.pageSize;
      _totalCount = response.totalCount;
      _totalPages = (_totalCount / _pageSize).ceil();
      _error = null;
      
      // 保存到缓存
      _saveToCache(
        keyWord: keyWord,
        status: status,
        pageNo: pageNo,
        pageSize: pageSize,
        tasks: _tasks,
      );
      
      // 清空选择状态
      _selectedTaskIds.clear();
      _selectAll = false;
    } catch (e) {
      _error = e.toString();
      _tasks = [];
      _totalCount = 0;
      _totalPages = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 强制刷新任务列表
  Future<void> forceRefresh({
    String? keyWord,
    String? status,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    _tasks.clear();
    // 清除缓存，强制重新加载
    _clearCache();
    await loadTasks(
      keyWord: keyWord,
      status: status,
      pageNo: pageNo,
      pageSize: pageSize,
      forceRefresh: true,
    );
  }
  
  // 跳转到指定页面
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    await loadTasks(pageNo: page, pageSize: _pageSize);
  }
  
  // 上一页
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await goToPage(_currentPage - 1);
    }
  }
  
  // 下一页
  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      await goToPage(_currentPage + 1);
    }
  }
  
  // 第一页
  Future<void> firstPage() async {
    if (_currentPage != 1) {
      await goToPage(1);
    }
  }
  
  // 最后一页
  Future<void> lastPage() async {
    if (_currentPage != _totalPages && _totalPages > 0) {
      await goToPage(_totalPages);
    }
  }
  
  // 选择操作
  void toggleTaskSelection(String taskId) {
    if (_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.remove(taskId);
    } else {
      _selectedTaskIds.add(taskId);
    }
    _updateSelectAllState();
    notifyListeners();
  }
  
  void toggleSelectAll() {
    if (_selectAll) {
      _selectedTaskIds.clear();
    } else {
      _selectedTaskIds.addAll(_tasks.map((task) => task.taskId));
    }
    _updateSelectAllState();
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedTaskIds.clear();
    _selectAll = false;
    notifyListeners();
  }
  
  bool isTaskSelected(String taskId) {
    return _selectedTaskIds.contains(taskId);
  }
  
  void _updateSelectAllState() {
    _selectAll = _tasks.isNotEmpty && _selectedTaskIds.length == _tasks.length;
  }
  
  // 发送邮件
  Future<bool> sendMail(BatchSendMailRequest request) async {
    try {
      final success = await _edmService.batchSendMail(request);
      if (success) {
        // 发送成功后刷新任务列表
        await forceRefresh();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // 设置全局配置
  void setGlobalConfigProvider(GlobalConfigProvider globalConfig) {
    _edmService.setGlobalConfigProvider(globalConfig);
  }
  
  // 获取缓存统计信息（用于调试）
  Map<String, dynamic> getCacheInfo() {
    return {
      'cacheSize': _pageCache.length,
      'cachedPages': _pageCache.keys.toList(),
      'currentPage': _currentPage,
      'totalPages': _totalPages,
    };
  }
} 