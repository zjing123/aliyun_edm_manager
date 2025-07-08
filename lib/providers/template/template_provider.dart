import 'package:flutter/foundation.dart';
import 'package:aliyun_edm_manager/models/template/template_model.dart';
import 'package:aliyun_edm_manager/models/template/template_request_response.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';

/// 缓存数据类
class _CachedPageData {
  final List<TemplateModel> templates;
  final int totalCount;
  final int totalPages;
  final DateTime cacheTime;
  
  _CachedPageData({
    required this.templates,
    required this.totalCount,
    required this.totalPages,
    required this.cacheTime,
  });
  
  /// 检查缓存是否过期（30分钟）
  bool get isExpired {
    return DateTime.now().difference(cacheTime).inMinutes > 30;
  }
}

/// 缓存键类
class _CacheKey {
  final int page;
  final String? keyWord;
  final int? status;
  final int? fromType;
  
  _CacheKey({
    required this.page,
    this.keyWord,
    this.status,
    this.fromType,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _CacheKey &&
        other.page == page &&
        other.keyWord == keyWord &&
        other.status == status &&
        other.fromType == fromType;
  }
  
  @override
  int get hashCode => page.hashCode ^ 
      (keyWord?.hashCode ?? 0) ^ 
      (status?.hashCode ?? 0) ^ 
      (fromType?.hashCode ?? 0);
}

/// 模板管理Provider
/// 提供模板的增删改查功能
class TemplateProvider extends ChangeNotifier {
  // 服务管理器
  late final AliyunServiceManager _serviceManager;
  
  // 全局配置Provider
  GlobalConfigProvider? _globalConfigProvider;
  
  // 模板列表数据
  List<TemplateModel> _templates = [];
  
  // 加载状态
  bool _isLoading = false;
  
  // 错误信息
  String? _error;
  
  // 分页信息
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 0;
  
  // 搜索参数
  String? _keyWord;
  int? _status;
  int? _fromType;
  
  // 批量选择相关
  Set<String> _selectedTemplateIds = {};
  bool _selectAll = false;
  
  // 缓存相关
  final Map<_CacheKey, _CachedPageData> _cache = {};
  
  // 构造函数
  TemplateProvider(AliyunServiceManager serviceManager) {
    _serviceManager = serviceManager;
  }
  
  // Getters
  List<TemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  String? get keyWord => _keyWord;
  int? get status => _status;
  int? get fromType => _fromType;
  
  // 批量选择相关getters
  Set<String> get selectedTemplateIds => _selectedTemplateIds;
  bool get selectAll => _selectAll;
  int get selectedCount => _selectedTemplateIds.length;
  bool get hasSelection => _selectedTemplateIds.isNotEmpty;
  
  // 设置全局配置Provider
  void setGlobalConfigProvider(GlobalConfigProvider provider) {
    _globalConfigProvider = provider;
    _serviceManager.initialize(provider);
  }
  
  // 设置搜索参数
  void setSearchParams({
    String? keyWord,
    int? status,
    int? fromType,
  }) {
    _keyWord = keyWord;
    _status = status;
    _fromType = fromType;
    _currentPage = 1; // 重置到第一页
    // 搜索参数改变时清理缓存
    _clearCache();
  }
  
  // 加载模板列表
  Future<void> loadTemplates({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    // 清理过期缓存
    _clearExpiredCache();
    
    // 创建缓存键
    final cacheKey = _CacheKey(
      page: _currentPage,
      keyWord: _keyWord,
      status: _status,
      fromType: _fromType,
    );
    
    // 检查缓存
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cachedData = _cache[cacheKey]!;
      if (!cachedData.isExpired) {
        // 使用缓存数据
        setState(() {
          _templates = cachedData.templates;
          _totalCount = cachedData.totalCount;
          _totalPages = cachedData.totalPages;
          _isLoading = false;
          _error = null;
        });
        print('使用缓存数据，页码: $_currentPage，共${_templates.length}条记录');
        return;
      } else {
        // 缓存过期，移除
        _cache.remove(cacheKey);
      }
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = QueryTemplateByParamRequest(
        pageNo: _currentPage,
        pageSize: _pageSize,
        keyWord: _keyWord,
        status: _status,
        fromType: _fromType,
      );
      
      final response = await _serviceManager.templateService.queryTemplateByParamWithRequest(request);
      
      // 缓存数据
      final cachedData = _CachedPageData(
        templates: response.templates,
        totalCount: response.totalCount,
        totalPages: response.totalPages,
        cacheTime: DateTime.now(),
      );
      _cache[cacheKey] = cachedData;
      
      setState(() {
        _templates = response.templates;
        _totalCount = response.totalCount;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
      
      print('模板列表加载成功，页码: $_currentPage，共${_templates.length}条记录，已缓存');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('加载模板列表失败: $e');
    }
  }
  
  // 刷新模板列表
  Future<void> refresh() async {
    await loadTemplates(forceRefresh: true);
  }
  
  // 清空缓存并回到第一页
  Future<void> refreshAndClearCache() async {
    _clearCache();
    _currentPage = 1;
    await loadTemplates(forceRefresh: true);
  }
  
  // 下一页
  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await loadTemplates();
    }
  }
  
  // 上一页
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      await loadTemplates();
    }
  }
  
  // 首页
  Future<void> firstPage() async {
    if (_currentPage != 1) {
      _currentPage = 1;
      await loadTemplates();
    }
  }
  
  // 末页
  Future<void> lastPage() async {
    if (_currentPage != _totalPages) {
      _currentPage = _totalPages;
      await loadTemplates();
    }
  }
  
  // 跳转到指定页
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      await loadTemplates();
    }
  }
  
  // 创建模板
  Future<bool> createTemplate({
    required int templateType,
    required String templateName,
    String? templateSubject,
    String? templateNickName,
    String? templateText,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = CreateTemplateRequest(
        templateType: templateType,
        templateName: templateName,
        templateSubject: templateSubject,
        templateNickName: templateNickName,
        templateText: templateText,
      );
      
      final response = await _serviceManager.templateService.createTemplate(request);
      
      print('模板创建成功，TemplateId: ${response.templateId}');
      
      // 清理缓存并刷新列表
      _clearCache();
      await refresh();
      
      return true;
    } catch (e) {
      print('创建模板失败: $e');
      return false;
    }
  }
  
  // 修改模板
  Future<bool> modifyTemplate({
    required int templateId,
    required String templateName,
    String? templateSubject,
    String? templateNickName,
    String? templateText,
    int? fromType,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = ModifyTemplateRequest(
        templateId: templateId,
        templateName: templateName,
        templateSubject: templateSubject,
        templateNickName: templateNickName,
        templateText: templateText,
        fromType: fromType,
      );
      
      final response = await _serviceManager.templateService.modifyTemplate(request);
      
      print('模板修改成功，RequestId: ${response.requestId}');
      
      // 清理缓存并刷新列表
      _clearCache();
      await refresh();
      
      return true;
    } catch (e) {
      print('修改模板失败: $e');
      return false;
    }
  }
  
  // 删除模板
  Future<bool> deleteTemplate({
    required int templateId,
    int? fromType,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = DeleteTemplateRequest(
        templateId: templateId,
        fromType: fromType,
      );
      
      final response = await _serviceManager.templateService.deleteTemplate(request);
      
      print('模板删除成功，RequestId: ${response.requestId}');
      
      // 清理缓存并刷新列表
      _clearCache();
      await refresh();
      
      return true;
    } catch (e) {
      print('删除模板失败: $e');
      return false;
    }
  }
  
  // 获取模板详情
  Future<DescTemplateResponse?> getTemplateDetail({
    required int templateId,
    int? fromType,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final request = DescTemplateRequest(
        templateId: templateId,
        fromType: fromType,
      );
      
      final response = await _serviceManager.templateService.descTemplate(request);
      
      print('获取模板详情成功，TemplateName: ${response.templateName}');
      
      return response;
    } catch (e) {
      print('获取模板详情失败: $e');
      return null;
    }
  }
  
  // 设置状态
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
  
  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // 批量选择相关方法
  
  // 切换单个模板的选择状态
  void toggleTemplateSelection(String templateId) {
    if (_selectedTemplateIds.contains(templateId)) {
      _selectedTemplateIds.remove(templateId);
    } else {
      _selectedTemplateIds.add(templateId);
    }
    
    // 更新全选状态
    _updateSelectAllState();
    notifyListeners();
  }
  
  // 切换全选状态
  void toggleSelectAll() {
    _selectAll = !_selectAll;
    
    if (_selectAll) {
      // 全选：添加所有模板ID
      _selectedTemplateIds = _templates.map((template) => template.templateId).toSet();
    } else {
      // 取消全选：清空选择
      _selectedTemplateIds.clear();
    }
    
    notifyListeners();
  }
  
  // 检查指定模板是否被选中
  bool isTemplateSelected(String templateId) {
    return _selectedTemplateIds.contains(templateId);
  }
  
  // 清空所有选择
  void clearSelection() {
    _selectedTemplateIds.clear();
    _selectAll = false;
    notifyListeners();
  }
  
  // 更新全选状态
  void _updateSelectAllState() {
    if (_templates.isEmpty) {
      _selectAll = false;
    } else {
      _selectAll = _selectedTemplateIds.length == _templates.length;
    }
  }
  
  // 清理过期缓存
  void _clearExpiredCache() {
    final expiredKeys = _cache.keys.where((key) => _cache[key]!.isExpired).toList();
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    if (expiredKeys.isNotEmpty) {
      print('清理了 ${expiredKeys.length} 个过期缓存');
    }
  }
  
  // 清理所有缓存
  void _clearCache() {
    _cache.clear();
    print('已清理所有缓存');
  }
  
  // 批量删除模板
  Future<bool> deleteSelectedTemplates() async {
    if (_selectedTemplateIds.isEmpty) {
      return false;
    }
    
    try {
      bool allSuccess = true;
      
      for (String templateId in _selectedTemplateIds) {
        final success = await deleteTemplate(templateId: int.parse(templateId));
        if (!success) {
          allSuccess = false;
        }
      }
      
      // 清空选择
      clearSelection();
      
      return allSuccess;
    } catch (e) {
      print('批量删除模板失败: $e');
      return false;
    }
  }
} 