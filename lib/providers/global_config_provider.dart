import 'package:flutter/foundation.dart';
import '../services/config_service.dart';

class GlobalConfigProvider with ChangeNotifier {
  ConfigService? _configService;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ConfigService? get configService => _configService;

  // 检查配置是否完整
  bool get isConfigured {
    return _configService?.isConfigured() ?? false;
  }

  // 获取Access Key ID
  String? get accessKeyId {
    return _configService?.getAccessKeyId();
  }

  // 获取Access Key Secret
  String? get accessKeySecret {
    return _configService?.getAccessKeySecret();
  }

  // 初始化全局配置
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _error = null;

    try {
      print('开始初始化全局配置...');
      _configService = await ConfigService.getInstance();
      
      // 验证配置是否完整
      if (!_configService!.isConfigured()) {
        _error = '阿里云AccessKey未配置，请先配置';
        print('全局配置初始化失败: $_error');
      } else {
        print('全局配置初始化成功');
        print('AccessKey ID: ${_configService!.getAccessKeyId()}');
        print('AccessKey Secret: ${_configService!.getAccessKeySecret() != null ? '已配置' : '未配置'}');
      }
      
      _isInitialized = true;
    } catch (e) {
      _error = '配置初始化失败: $e';
      print('全局配置初始化异常: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // 保存配置
  Future<bool> saveConfig(String accessKeyId, String accessKeySecret) async {
    if (_configService == null) {
      await initialize();
    }

    try {
      final success = await _configService!.saveConfig(accessKeyId, accessKeySecret);
      if (success) {
        _error = null; // 清除之前的错误
        print('配置保存成功');
        Future.microtask(() => notifyListeners());
      }
      return success;
    } catch (e) {
      _error = '配置保存失败: $e';
      print('配置保存异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  // 清除配置
  Future<bool> clearConfig() async {
    if (_configService == null) {
      await initialize();
    }

    try {
      final success = await _configService!.clearConfig();
      if (success) {
        _error = '阿里云AccessKey未配置，请先配置';
        print('配置清除成功');
        Future.microtask(() => notifyListeners());
      }
      return success;
    } catch (e) {
      _error = '配置清除失败: $e';
      print('配置清除异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  // 重新初始化
  Future<void> reinitialize() async {
    _isInitialized = false;
    await initialize();
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    Future.microtask(() => notifyListeners());
  }

  // 清除错误
  void clearError() {
    _error = null;
    Future.microtask(() => notifyListeners());
  }
} 