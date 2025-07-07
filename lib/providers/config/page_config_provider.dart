import 'package:flutter/foundation.dart';
import '../services/config_service.dart';

class PageConfigProvider with ChangeNotifier {
  ConfigService? _configService;
  bool _isLoading = false;
  String? _error;

  // 邮件过滤相关
  List<String> _filterEmails = [];
  
  // 禁止删除的收件人列表ID
  Set<String> _forbiddenDeleteReceiverIds = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get filterEmails => _filterEmails;
  Set<String> get forbiddenDeleteReceiverIds => _forbiddenDeleteReceiverIds;

  // 初始化页面配置
  Future<void> initialize(ConfigService configService) async {
    _configService = configService;
    await _loadAllConfigs();
  }

  // 加载所有配置
  Future<void> _loadAllConfigs() async {
    if (_configService == null) return;

    _setLoading(true);
    _error = null;

    try {
      print('开始加载页面配置...');
      
      // 加载邮件过滤配置
      _filterEmails = _configService!.getFilterEmails();
      print('邮件过滤配置: ${_filterEmails.length} 条');
      
      // 加载禁止删除配置
      _forbiddenDeleteReceiverIds = await _configService!.getForbiddenDeleteReceiverIds();
      print('禁止删除配置: ${_forbiddenDeleteReceiverIds.length} 条');
      
      print('页面配置加载完成');
    } catch (e) {
      _error = '页面配置加载失败: $e';
      print('页面配置加载异常: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // 邮件过滤配置相关方法
  Future<bool> setFilterEmails(List<String> emails) async {
    if (_configService == null) return false;

    try {
      final success = await _configService!.setFilterEmails(emails);
      if (success) {
        _filterEmails = emails;
        print('邮件过滤配置保存成功: ${emails.length} 条');
        Future.microtask(() => notifyListeners());
      }
      return success;
    } catch (e) {
      _error = '邮件过滤配置保存失败: $e';
      print('邮件过滤配置保存异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  Future<bool> addFilterEmail(String email) async {
    if (_configService == null) return false;

    try {
      final success = await _configService!.addFilterEmail(email);
      if (success) {
        await _loadAllConfigs(); // 重新加载配置
      }
      return success;
    } catch (e) {
      _error = '添加过滤邮箱失败: $e';
      print('添加过滤邮箱异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  Future<bool> removeFilterEmail(String email) async {
    if (_configService == null) return false;

    try {
      final success = await _configService!.removeFilterEmail(email);
      if (success) {
        await _loadAllConfigs(); // 重新加载配置
      }
      return success;
    } catch (e) {
      _error = '移除过滤邮箱失败: $e';
      print('移除过滤邮箱异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  Future<bool> clearFilterEmails() async {
    if (_configService == null) return false;

    try {
      final success = await _configService!.clearFilterEmails();
      if (success) {
        await _loadAllConfigs(); // 重新加载配置
      }
      return success;
    } catch (e) {
      _error = '清空过滤邮箱失败: $e';
      print('清空过滤邮箱异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  // 禁止删除配置相关方法
  Future<bool> setForbiddenDeleteReceiverIds(Set<String> ids) async {
    if (_configService == null) return false;

    try {
      final success = await _configService!.setForbiddenDeleteReceiverIds(ids);
      if (success) {
        _forbiddenDeleteReceiverIds = ids;
        print('禁止删除配置保存成功: ${ids.length} 条');
        Future.microtask(() => notifyListeners());
      }
      return success;
    } catch (e) {
      _error = '禁止删除配置保存失败: $e';
      print('禁止删除配置保存异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  Future<bool> addForbiddenDeleteReceiverId(String id) async {
    if (_configService == null) return false;

    try {
      final success = await _configService!.addForbiddenDeleteReceiverId(id);
      if (success) {
        await _loadAllConfigs(); // 重新加载配置
      }
      return success;
    } catch (e) {
      _error = '添加禁止删除ID失败: $e';
      print('添加禁止删除ID异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  Future<bool> removeForbiddenDeleteReceiverId(String id) async {
    if (_configService == null) return false;

    try {
      final success = await _configService!.removeForbiddenDeleteReceiverId(id);
      if (success) {
        await _loadAllConfigs(); // 重新加载配置
      }
      return success;
    } catch (e) {
      _error = '移除禁止删除ID失败: $e';
      print('移除禁止删除ID异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  Future<bool> cleanNonExistentReceiverIds(List<String> existingIds) async {
    if (_configService == null) return false;

    try {
      final success = await _configService!.cleanNonExistentReceiverIds(existingIds);
      if (success) {
        await _loadAllConfigs(); // 重新加载配置
      }
      return success;
    } catch (e) {
      _error = '清理不存在ID失败: $e';
      print('清理不存在ID异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  Future<bool> clearForbiddenDeleteReceiverIds() async {
    if (_configService == null) return false;

    try {
      final success = await _configService!.clearForbiddenDeleteReceiverIds();
      if (success) {
        await _loadAllConfigs(); // 重新加载配置
      }
      return success;
    } catch (e) {
      _error = '清空禁止删除配置失败: $e';
      print('清空禁止删除配置异常: $_error');
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  // 刷新所有配置
  Future<void> refresh() async {
    await _loadAllConfigs();
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