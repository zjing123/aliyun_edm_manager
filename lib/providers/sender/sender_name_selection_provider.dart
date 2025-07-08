import 'package:flutter/foundation.dart';
import 'package:aliyun_edm_manager/services/aliyun/sender_name/sender_name_service.dart';
import 'package:aliyun_edm_manager/models/sender/sender_name_model.dart';

class SenderNameSelectionProvider extends ChangeNotifier {
  final SenderNameService _senderNameService = SenderNameService();

  List<SenderNameModel> _senderNames = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<SenderNameModel> get senderNames => _senderNames;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 加载所有发送人名称
  Future<void> loadSenderNames() async {
    _setLoading(true);
    _clearError();
    
    try {
      _senderNames = await _senderNameService.getAllSenderNames();
      notifyListeners();
    } catch (e) {
      _setError('加载发送人名称失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 根据名称获取发送人名称
  SenderNameModel? getSenderNameByName(String name) {
    try {
      return _senderNames.firstWhere((e) => e.name == name);
    } catch (e) {
      return null;
    }
  }

  /// 根据ID获取发送人名称
  SenderNameModel? getSenderNameById(String id) {
    try {
      return _senderNames.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取发送人名称列表（用于下拉选择）
  List<MapEntry<String, String>> get senderNameOptions {
    return _senderNames.map((e) => MapEntry(e.id, e.name)).toList();
  }

  /// 清除错误信息
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
} 