import 'package:flutter/foundation.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_list_model.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/providers/config/page_config_provider.dart';

class ReceiverListProvider with ChangeNotifier {
  AliyunServiceManager? _serviceManager;
  
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
    
    // 创建并配置AliyunServiceManager
    _serviceManager = AliyunServiceManager();
    _serviceManager!.initialize(globalConfig);
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
  Future<void> loadReceivers() async {
    if (_serviceManager == null) {
      throw Exception('服务未初始化');
    }
    
    _setLoading(true);
    _error = null;
    
    try {
      final receiverService = _serviceManager!.receiverService;
      final receiversData = await receiverService.queryReceivers();
      
      _receivers = receiversData.map((data) => ReceiverListModel.fromMap(data)).toList();
      _lastUpdated = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _receivers = [];
    } finally {
      _setLoading(false);
    }
  }

  // 添加收件人列表
  Future<void> addReceiver(ReceiverListModel receiver) async {
    if (_serviceManager == null) {
      throw Exception('服务未初始化');
    }
    
    try {
      final receiverService = _serviceManager!.receiverService;
      final response = await receiverService.createReceiver(
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
    if (_serviceManager == null) {
      throw Exception('服务未初始化');
    }
    
    try {
      final receiverService = _serviceManager!.receiverService;
      await receiverService.deleteReceiver(receiverId);
      
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
    if (_serviceManager == null) {
      throw Exception('服务未初始化');
    }
    
    try {
      final receiverService = _serviceManager!.receiverService;
      for (final receiverId in receiverIds) {
        await receiverService.deleteReceiver(receiverId);
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

  // 强制刷新收件人列表
  Future<void> forceRefresh() async {
    _receivers.clear();
    _lastUpdated = null;
    _error = null;
    await loadReceivers();
  }
} 