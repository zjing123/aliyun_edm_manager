import 'package:flutter/foundation.dart';
import '../models/receiver_list_model.dart';
import '../services/aliyun_edm_service.dart';

class ReceiverListProvider with ChangeNotifier {
  final AliyunEDMService _service = AliyunEDMService();
  
  List<ReceiverListModel> _receivers = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

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

    _setLoading(true);
    _error = null;

    try {
      final data = await _service.queryReceivers();
      _receivers = data.map((map) => ReceiverListModel.fromMap(map)).toList();
      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
    try {
      final response = await _service.createReceiver(
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
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // 删除收件人列表
  Future<void> deleteReceiver(String receiverId) async {
    try {
      await _service.deleteReceiver(receiverId);
      
      // 从本地列表移除
      _receivers.removeWhere((r) => r.receiverId == receiverId);
      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // 批量删除收件人列表
  Future<void> deleteReceivers(List<String> receiverIds) async {
    try {
      for (final receiverId in receiverIds) {
        await _service.deleteReceiver(receiverId);
      }
      
      // 从本地列表移除
      _receivers.removeWhere((r) => receiverIds.contains(r.receiverId));
      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
    notifyListeners();
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 