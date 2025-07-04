import 'package:flutter/foundation.dart';
import '../models/receiver_list_model.dart';
import '../services/aliyun_edm_service.dart';
import 'global_config_provider.dart';
import 'page_config_provider.dart';

class ReceiverListProvider with ChangeNotifier {
  AliyunEDMService? _service;
  
  List<ReceiverListModel> _receivers = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  // 依赖注入的配置Provider
  GlobalConfigProvider? _globalConfigProvider;
  PageConfigProvider? _pageConfigProvider;

  // 设置依赖
  void setDependencies(GlobalConfigProvider globalConfig, PageConfigProvider pageConfig) {
    _globalConfigProvider = globalConfig;
    _pageConfigProvider = pageConfig;
    
    // 创建并配置AliyunEDMService
    _service = AliyunEDMService();
    _service!.setGlobalConfigProvider(globalConfig);
  }

  // Getters
  List<ReceiverListModel> get receivers => _receivers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  
  // 获取所有收件人列表名称（用于重复检查）
  Set<String> get receiverNames => _receivers
      .map((r) => r.receiversName.toLowerCase().trim())
      .where((name) => name.isNotEmpty)
      .toSet();

  // 检查名称是否重复
  bool isNameDuplicate(String name) {
    return receiverNames.contains(name.toLowerCase().trim());
  }

  // 加载收件人列表
  Future<void> loadReceivers({bool forceRefresh = false}) async {
    // 如果不是强制刷新且数据不为空且更新时间在1分钟内，直接返回缓存
    // 减少缓存时间以确保数据实时性
    if (!forceRefresh && 
        _receivers.isNotEmpty && 
        _lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!).inMinutes < 1) {
      return;
    }

    if (_service == null) {
      _error = '服务未初始化';
      _setLoading(false);
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      print('开始加载收件人列表...');
      final data = await _service!.queryReceivers();
      print('API返回数据: ${data.length} 条记录');
      
      // 清除之前的错误状态
      _error = null;
      
      // 使用页面配置Provider获取禁止删除的ID
      final forbiddenIds = _pageConfigProvider?.forbiddenDeleteReceiverIds ?? {};
      print('禁止删除的ID: $forbiddenIds');
      
      // 清理不存在的收件人列表ID
      final existingIds = data.map((map) => map['ReceiverId']?.toString() ?? '').toList();
      await _pageConfigProvider?.cleanNonExistentReceiverIds(existingIds);
      
      // 设置isDeletable字段
      _receivers = data.map((map) {
        final receiver = ReceiverListModel.fromMap(map);
        final isDeletable = !forbiddenIds.contains(receiver.receiverId);
        return receiver.copyWith(isDeletable: isDeletable);
      }).toList();
      
      print('处理后的收件人列表: ${_receivers.length} 条记录');
      _lastUpdated = DateTime.now();
      Future.microtask(() => notifyListeners());
    } catch (e) {
      print('加载收件人列表失败: $e');
      _error = e.toString();
      Future.microtask(() => notifyListeners());
    } finally {
      _setLoading(false);
    }
  }

  // 强制刷新数据（忽略缓存）
  Future<void> forceRefresh() async {
    await loadReceivers(forceRefresh: true);
  }

  // 添加收件人列表
  Future<void> addReceiver(ReceiverListModel receiver) async {
    if (_service == null) {
      throw Exception('服务未初始化');
    }
    
    try {
      final response = await _service!.createReceiver(
        receiver.receiversName,
        alias: receiver.receiversAlias,
        desc: receiver.desc,
      );
      
      // 创建新的实例，使用返回的ReceiverId
      final newReceiver = ReceiverListModel(
        receiverId: response.receiverId,
        receiversName: receiver.receiversName,
        receiversAlias: receiver.receiversAlias,
        desc: receiver.desc,
        count: receiver.count,
        createTime: receiver.createTime,
      );
      
      // 添加到本地列表
      _receivers.add(newReceiver);
      _lastUpdated = DateTime.now();
      Future.microtask(() => notifyListeners());
    } catch (e) {
      _error = e.toString();
      Future.microtask(() => notifyListeners());
      rethrow;
    }
  }

  // 删除收件人列表
  Future<void> deleteReceiver(String receiverId) async {
    if (_service == null) {
      throw Exception('服务未初始化');
    }
    
    try {
      await _service!.deleteReceiver(receiverId);
      
      // 从本地列表移除
      _receivers.removeWhere((r) => r.receiverId == receiverId);
      _lastUpdated = DateTime.now();
      Future.microtask(() => notifyListeners());
    } catch (e) {
      _error = e.toString();
      Future.microtask(() => notifyListeners());
      rethrow;
    }
  }

  // 批量删除收件人列表
  Future<void> deleteReceivers(List<String> receiverIds) async {
    if (_service == null) {
      throw Exception('服务未初始化');
    }
    
    try {
      for (final receiverId in receiverIds) {
        await _service!.deleteReceiver(receiverId);
      }
      
      // 从本地列表移除
      _receivers.removeWhere((r) => receiverIds.contains(r.receiverId));
      _lastUpdated = DateTime.now();
      Future.microtask(() => notifyListeners());
    } catch (e) {
      _error = e.toString();
      Future.microtask(() => notifyListeners());
      rethrow;
    }
  }

  // 根据ID查找收件人列表
  ReceiverListModel? findReceiverById(String receiverId) {
    try {
      return _receivers.firstWhere((r) => r.receiverId == receiverId);
    } catch (e) {
      return null;
    }
  }

  // 根据名称查找收件人列表
  ReceiverListModel? findReceiverByName(String name) {
    try {
      return _receivers.firstWhere(
        (r) => r.receiversName.toLowerCase().trim() == name.toLowerCase().trim()
      );
    } catch (e) {
      return null;
    }
  }

  // 清空缓存
  void clearCache() {
    _receivers.clear();
    _lastUpdated = null;
    _error = null;
    Future.microtask(() => notifyListeners());
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    // 使用 Future.microtask 来避免在构建过程中调用 notifyListeners
    Future.microtask(() => notifyListeners());
  }

  // 清除错误
  void clearError() {
    _error = null;
    Future.microtask(() => notifyListeners());
  }
} 