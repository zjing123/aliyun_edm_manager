import 'package:flutter/foundation.dart';
import 'package:aliyun_edm_manager/models/tag/email_tag_model.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';

/// 缓存数据类
class _CachedPageData {
  final List<EmailTagModel> tags;
  final int totalCount;
  final int totalPages;
  final DateTime cacheTime;
  
  _CachedPageData({
    required this.tags,
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
  
  _CacheKey({
    required this.page,
    this.keyWord,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _CacheKey &&
        other.page == page &&
        other.keyWord == keyWord;
  }
  
  @override
  int get hashCode => page.hashCode ^ (keyWord?.hashCode ?? 0);
}

/// 标签管理Provider
/// 提供标签的增删改查功能
class TagProvider extends ChangeNotifier {
  // 服务管理器
  late final AliyunServiceManager _serviceManager;
  
  // 全局配置Provider
  GlobalConfigProvider? _globalConfigProvider;
  
  // 标签列表数据
  List<EmailTagModel> _tags = [];
  
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
  
  // 批量选择相关
  Set<String> _selectedTagIds = {};
  bool _selectAll = false;
  
  // 缓存相关
  final Map<_CacheKey, _CachedPageData> _cache = {};
  
  // 构造函数
  TagProvider(AliyunServiceManager serviceManager) {
    _serviceManager = serviceManager;
  }
  
  // Getters
  List<EmailTagModel> get tags => _tags;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  String? get keyWord => _keyWord;
  
  // 批量选择相关getters
  Set<String> get selectedTagIds => _selectedTagIds;
  bool get selectAll => _selectAll;
  int get selectedCount => _selectedTagIds.length;
  bool get hasSelection => _selectedTagIds.isNotEmpty;
  
  // 设置全局配置Provider
  void setGlobalConfigProvider(GlobalConfigProvider provider) {
    _globalConfigProvider = provider;
    _serviceManager.initialize(provider);
  }
  
  // 设置搜索参数
  void setSearchParams({
    String? keyWord,
  }) {
    _keyWord = keyWord;
    _currentPage = 1; // 重置到第一页
    // 搜索参数改变时清理缓存
    _clearCache();
  }
  
  // 加载标签列表
  Future<void> loadTags({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    // 清理过期缓存
    _clearExpiredCache();
    
    // 创建缓存键
    final cacheKey = _CacheKey(
      page: _currentPage,
      keyWord: _keyWord,
    );
    
    // 检查缓存
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cachedData = _cache[cacheKey]!;
      if (!cachedData.isExpired) {
        // 使用缓存数据
        setState(() {
          _tags = cachedData.tags;
          _totalCount = cachedData.totalCount;
          _totalPages = cachedData.totalPages;
          _isLoading = false;
          _error = null;
        });
        print('使用缓存数据，页码: $_currentPage，共${_tags.length}条记录');
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
      
      final response = await _serviceManager.emailTagService.queryTagByParam(
        pageNo: _currentPage,
        pageSize: _pageSize,
        keyWord: _keyWord,
      );
      
      // 计算总页数
      final totalPages = (response.totalCount / _pageSize).ceil();
      
      // 缓存数据
      final cachedData = _CachedPageData(
        tags: response.tags,
        totalCount: response.totalCount,
        totalPages: totalPages,
        cacheTime: DateTime.now(),
      );
      _cache[cacheKey] = cachedData;
      
      setState(() {
        _tags = response.tags;
        _totalCount = response.totalCount;
        _totalPages = totalPages;
        _isLoading = false;
      });
      
      print('标签列表加载成功，页码: $_currentPage，共${_tags.length}条记录，已缓存');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('加载标签列表失败: $e');
    }
  }
  
  // 刷新标签列表
  Future<void> refresh() async {
    await loadTags(forceRefresh: true);
  }
  
  // 清空缓存并回到第一页
  Future<void> refreshAndClearCache() async {
    _clearCache();
    _currentPage = 1;
    await loadTags(forceRefresh: true);
  }
  
  // 下一页
  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await loadTags();
    }
  }
  
  // 上一页
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      await loadTags();
    }
  }
  
  // 首页
  Future<void> firstPage() async {
    if (_currentPage != 1) {
      _currentPage = 1;
      await loadTags();
    }
  }
  
  // 末页
  Future<void> lastPage() async {
    if (_currentPage != _totalPages) {
      _currentPage = _totalPages;
      await loadTags();
    }
  }
  
  // 跳转到指定页
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      await loadTags();
    }
  }
  
  // 创建标签
  Future<bool> createTag({
    required String tagName,
    String? tagDescription,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final tagId = await _serviceManager.emailTagService.createTag(
        tagName: tagName,
        tagDescription: tagDescription,
      );
      
      print('标签创建成功，TagId: $tagId');
      
      // 清理缓存并刷新列表
      _clearCache();
      await refresh();
      
      return true;
    } catch (e) {
      print('创建标签失败: $e');
      return false;
    }
  }
  
  // 修改标签
  Future<bool> modifyTag({
    required String tagId,
    String? tagName,
    String? tagDescription,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final success = await _serviceManager.emailTagService.modifyTag(
        tagId: tagId,
        tagName: tagName,
        tagDescription: tagDescription,
      );
      
      if (success) {
        print('标签修改成功，TagId: $tagId');
        
        // 清理缓存并刷新列表
        _clearCache();
        await refresh();
      }
      
      return success;
    } catch (e) {
      print('修改标签失败: $e');
      return false;
    }
  }
  
  // 删除标签
  Future<bool> deleteTag({
    required String tagId,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final success = await _serviceManager.emailTagService.deleteTag(
        tagId: tagId,
      );
      
      if (success) {
        print('标签删除成功，TagId: $tagId');
        
        // 清理缓存并刷新列表
        _clearCache();
        await refresh();
      }
      
      return success;
    } catch (e) {
      print('删除标签失败: $e');
      return false;
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
  
  // 切换单个标签的选择状态
  void toggleTagSelection(String tagId) {
    if (_selectedTagIds.contains(tagId)) {
      _selectedTagIds.remove(tagId);
    } else {
      _selectedTagIds.add(tagId);
    }
    
    // 更新全选状态
    _updateSelectAllState();
    notifyListeners();
  }
  
  // 切换全选状态
  void toggleSelectAll() {
    _selectAll = !_selectAll;
    
    if (_selectAll) {
      // 全选：添加所有标签ID
      _selectedTagIds = _tags.map((tag) => tag.tagId).toSet();
    } else {
      // 取消全选：清空选择
      _selectedTagIds.clear();
    }
    
    notifyListeners();
  }
  
  // 检查指定标签是否被选中
  bool isTagSelected(String tagId) {
    return _selectedTagIds.contains(tagId);
  }
  
  // 清空所有选择
  void clearSelection() {
    _selectedTagIds.clear();
    _selectAll = false;
    notifyListeners();
  }
  
  // 更新全选状态
  void _updateSelectAllState() {
    if (_tags.isEmpty) {
      _selectAll = false;
    } else {
      _selectAll = _selectedTagIds.length == _tags.length;
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
  
  // 批量删除标签
  Future<bool> deleteSelectedTags() async {
    if (_selectedTagIds.isEmpty) {
      return false;
    }
    
    try {
      print('开始批量删除 ${_selectedTagIds.length} 个标签');
      
      final results = await _serviceManager.emailTagService.batchDeleteTags(
        tagIds: _selectedTagIds.toList(),
      );
      
      // 统计成功和失败的数量
      final successCount = results.values.where((success) => success).length;
      final failCount = results.values.where((success) => !success).length;
      
      print('批量删除完成: 成功 $successCount 个，失败 $failCount 个');
      
      // 检查是否全部成功
      bool allSuccess = results.values.every((success) => success);
      
      // 清空选择
      clearSelection();
      
      // 刷新列表
      await refresh();
      
      return allSuccess;
    } catch (e) {
      print('批量删除标签失败: $e');
      return false;
    }
  }
}