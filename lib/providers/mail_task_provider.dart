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
  
  MailTaskProvider(this._edmService);
  
  List<MailTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 分页getter
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  
  // 加载邮件任务列表
  Future<void> loadTasks({
    String? keyWord,
    String? status,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
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
    await loadTasks(
      keyWord: keyWord,
      status: status,
      pageNo: pageNo,
      pageSize: pageSize,
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
} 