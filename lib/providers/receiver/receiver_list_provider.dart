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

  // 选择相关状态
  final Set<String> _selectedReceivers = <String>{};
  bool _selectAll = false;

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
  
  // 选择相关的 getters
  Set<String> get selectedReceivers => _selectedReceivers;
  bool get selectAll => _selectAll;
  int get selectedCount => _selectedReceivers.length;
  
  // 获取所有收件人列表名称（用于重复检查）
  Set<String> get receiverNames => _receivers
      .map((r) => r.receiversName.toLowerCase().trim())
      .where((name) => name.isNotEmpty)
      .toSet();

  // 检查名称是否重复
  bool isNameDuplicate(String name) {
    return receiverNames.contains(name.toLowerCase().trim());
  }

  // 选择相关方法
  bool isReceiverSelected(String receiverId) {
    return _selectedReceivers.contains(receiverId);
  }

  void toggleReceiverSelection(String receiverId) {
    if (_selectedReceivers.contains(receiverId)) {
      _selectedReceivers.remove(receiverId);
    } else {
      _selectedReceivers.add(receiverId);
    }
    _updateSelectAllState();
    notifyListeners();
  }

  void toggleSelectAll() {
    if (_selectAll) {
      _selectedReceivers.clear();
      _selectAll = false;
    } else {
      // 只选择可删除的收件人列表
      final deletableReceiverIds = _receivers
          .where((item) => item.isDeletable)
          .map((item) => item.receiverId)
          .toSet();
      _selectedReceivers.addAll(deletableReceiverIds);
      _selectAll = _selectedReceivers.length == deletableReceiverIds.length;
    }
    notifyListeners();
  }

  void _updateSelectAllState() {
    final deletableReceivers = _receivers.where((item) => item.isDeletable);
    final deletableReceiverIds = deletableReceivers.map((item) => item.receiverId).toSet();
    _selectAll = deletableReceiverIds.isNotEmpty && 
                 _selectedReceivers.length == deletableReceiverIds.length;
  }

  void clearSelection() {
    _selectedReceivers.clear();
    _selectAll = false;
    notifyListeners();
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
      
      // 获取禁止删除的ID列表
      final forbiddenIds = _pageConfigProvider?.forbiddenDeleteReceiverIds ?? {};
      
      // 设置isDeletable字段
      _receivers = receiversData.map((data) {
        final receiver = ReceiverListModel.fromMap(data);
        final isDeletable = !forbiddenIds.contains(receiver.receiverId);
        return receiver.copyWith(isDeletable: isDeletable);
      }).toList();
      
      _lastUpdated = DateTime.now();
      _error = null;
      
      // 更新选择状态
      _updateSelectAllState();
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
        isDeletable: true, // 新创建的列表默认可删除
      );
      
      // 添加到本地列表
      _receivers.add(newReceiver);
      _lastUpdated = DateTime.now();
      _updateSelectAllState();
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
      // 从选择列表中移除
      _selectedReceivers.remove(receiverId);
      _lastUpdated = DateTime.now();
      _updateSelectAllState();
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
      // 从选择列表中移除
      _selectedReceivers.removeAll(receiverIds);
      _lastUpdated = DateTime.now();
      _updateSelectAllState();
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
    _selectedReceivers.clear();
    _selectAll = false;
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
    _selectedReceivers.clear();
    _selectAll = false;
    _lastUpdated = null;
    _error = null;
    await loadReceivers();
  }
} 