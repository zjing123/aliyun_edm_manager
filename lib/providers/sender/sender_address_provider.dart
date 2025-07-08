import 'package:flutter/foundation.dart';
import 'package:aliyun_edm_manager/models/sender/sender_address_model.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';

/// 缓存数据类
class _CachedPageData {
  final List<SenderAddressModel> addresses;
  final int totalCount;
  final int totalPages;
  final DateTime cacheTime;
  
  _CachedPageData({
    required this.addresses,
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
  final String? sendType;
  
  _CacheKey({
    required this.page,
    this.keyWord,
    this.sendType,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _CacheKey &&
        other.page == page &&
        other.keyWord == keyWord &&
        other.sendType == sendType;
  }
  
  @override
  int get hashCode => page.hashCode ^ 
      (keyWord?.hashCode ?? 0) ^ 
      (sendType?.hashCode ?? 0);
}

/// 发信地址管理Provider
/// 提供发信地址的增删改查功能
class SenderAddressProvider extends ChangeNotifier {
  // 服务管理器
  late final AliyunServiceManager _serviceManager;
  
  // 全局配置Provider
  GlobalConfigProvider? _globalConfigProvider;
  
  // 发信地址列表数据
  List<SenderAddressModel> _addresses = [];
  
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
  String? _sendType;
  
  // 批量选择相关
  Set<String> _selectedAddressIds = {};
  bool _selectAll = false;
  
  // 缓存相关
  final Map<_CacheKey, _CachedPageData> _cache = {};
  
  // 构造函数
  SenderAddressProvider(AliyunServiceManager serviceManager) {
    _serviceManager = serviceManager;
  }
  
  // Getters
  List<SenderAddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  String? get keyWord => _keyWord;
  String? get sendType => _sendType;
  
  // 批量选择相关getters
  Set<String> get selectedAddressIds => _selectedAddressIds;
  bool get selectAll => _selectAll;
  int get selectedCount => _selectedAddressIds.length;
  bool get hasSelection => _selectedAddressIds.isNotEmpty;
  
  // 设置全局配置Provider
  void setGlobalConfigProvider(GlobalConfigProvider provider) {
    _globalConfigProvider = provider;
    _serviceManager.initialize(provider);
  }
  
  // 设置搜索参数
  void setSearchParams({
    String? keyWord,
    String? sendType,
  }) {
    _keyWord = keyWord;
    _sendType = sendType;
    _currentPage = 1; // 重置到第一页
    // 搜索参数改变时清理缓存
    _clearCache();
  }
  
  // 加载发信地址列表
  Future<void> loadAddresses({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    // 清理过期缓存
    _clearExpiredCache();
    
    // 创建缓存键
    final cacheKey = _CacheKey(
      page: _currentPage,
      keyWord: _keyWord,
      sendType: _sendType,
    );
    
    // 检查缓存
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cachedData = _cache[cacheKey]!;
      if (!cachedData.isExpired) {
        // 使用缓存数据
        setState(() {
          _addresses = cachedData.addresses;
          _totalCount = cachedData.totalCount;
          _totalPages = cachedData.totalPages;
          _isLoading = false;
          _error = null;
        });
        print('使用缓存数据，页码: $_currentPage，共${_addresses.length}条记录');
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
      
      final response = await _serviceManager.senderAddressService.queryMailAddressByParam(
        keyWord: _keyWord,
        sendType: _sendType,
        pageNo: _currentPage,
        pageSize: _pageSize,
      );
      
      // 缓存数据
      final cachedData = _CachedPageData(
        addresses: response.addresses,
        totalCount: response.totalCount,
        totalPages: response.totalPages,
        cacheTime: DateTime.now(),
      );
      _cache[cacheKey] = cachedData;
      
      setState(() {
        _addresses = response.addresses;
        _totalCount = response.totalCount;
        _totalPages = response.totalPages;
        _isLoading = false;
        _error = null;
      });
      
      print('加载发信地址成功，页码: $_currentPage，共${_addresses.length}条记录');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      print('加载发信地址失败: $e');
    }
  }
  
  // 刷新列表
  Future<void> refresh() async {
    await loadAddresses(forceRefresh: true);
  }
  
  // 刷新并清理缓存
  Future<void> refreshAndClearCache() async {
    _clearCache();
    await loadAddresses(forceRefresh: true);
  }
  
  // 分页操作
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    await loadAddresses();
  }
  
  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      await goToPage(_currentPage + 1);
    }
  }
  
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await goToPage(_currentPage - 1);
    }
  }
  
  Future<void> firstPage() async {
    await goToPage(1);
  }
  
  Future<void> lastPage() async {
    await goToPage(_totalPages);
  }
  
  // 创建发信地址
  Future<bool> createAddress({
    required String accountName,
    String? replyAddress,
    required String sendType,
    String? password,
  }) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final response = await _serviceManager.senderAddressService.createMailAddress(
        accountName: accountName,
        replyAddress: replyAddress,
        sendType: sendType,
        password: password,
      );
      
      if (response.isSuccess) {
        // 创建成功后刷新列表
        await refresh();
        return true;
      } else {
        throw Exception(response.errorMessage ?? '创建发信地址失败');
      }
    } catch (e) {
      print('创建发信地址失败: $e');
      return false;
    }
  }
  
  // 删除发信地址
  Future<bool> deleteAddress({required int mailAddressId}) async {
    try {
      if (!_serviceManager.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }
      
      final response = await _serviceManager.senderAddressService.deleteMailAddress(
        mailAddressId: mailAddressId,
      );
      
      if (response.isSuccess) {
        // 删除成功后刷新列表
        await refresh();
        return true;
      } else {
        throw Exception(response.errorMessage ?? '删除发信地址失败');
      }
    } catch (e) {
      print('删除发信地址失败: $e');
      return false;
    }
  }
  
  // 批量删除发信地址
  Future<bool> deleteSelectedAddresses() async {
    try {
      if (_selectedAddressIds.isEmpty) return false;
      
      bool allSuccess = true;
      for (final addressId in _selectedAddressIds) {
        final success = await deleteAddress(mailAddressId: int.parse(addressId));
        if (!success) {
          allSuccess = false;
        }
      }
      
      // 清空选择
      _clearSelection();
      
      return allSuccess;
    } catch (e) {
      print('批量删除发信地址失败: $e');
      return false;
    }
  }
  
  // 批量选择相关方法
  void toggleAddressSelection(String addressId) {
    if (_selectedAddressIds.contains(addressId)) {
      _selectedAddressIds.remove(addressId);
    } else {
      _selectedAddressIds.add(addressId);
    }
    _updateSelectAll();
    notifyListeners();
  }
  
  void toggleSelectAll() {
    if (_selectAll) {
      _selectedAddressIds.clear();
    } else {
      _selectedAddressIds.addAll(_addresses.map((address) => address.mailAddressId));
    }
    _selectAll = !_selectAll;
    notifyListeners();
  }
  
  bool isAddressSelected(String addressId) {
    return _selectedAddressIds.contains(addressId);
  }
  
  void _updateSelectAll() {
    _selectAll = _selectedAddressIds.length == _addresses.length && _addresses.isNotEmpty;
  }
  
  void _clearSelection() {
    _selectedAddressIds.clear();
    _selectAll = false;
    notifyListeners();
  }
  
  // 缓存相关方法
  void _clearCache() {
    _cache.clear();
  }
  
  void _clearExpiredCache() {
    _cache.removeWhere((key, value) => value.isExpired);
  }
  
  // 状态更新方法
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}