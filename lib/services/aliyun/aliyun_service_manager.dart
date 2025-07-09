import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/services/aliyun/receiver/receiver_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/template/template_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/sender_address/sender_address_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/email_tag/email_tag_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/email_task/email_task_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/scheduled_email/scheduled_email_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/track/track_service.dart';

/// 阿里云服务管理器
/// 统一管理所有阿里云子服务，提供便捷的访问接口
class AliyunServiceManager {
  // 移除单例模式，允许创建多个实例用于测试
  AliyunServiceManager();

  late final ReceiverService _receiverService;
  late final TemplateService _templateService;
  late final SenderAddressService _senderAddressService;
  late final EmailTagService _emailTagService;
  late final EmailTaskService _emailTaskService;
  late final ScheduledEmailService _scheduledEmailService;
  late final TrackService _trackService;

  bool _initialized = false;

  /// 初始化服务管理器
  void initialize(GlobalConfigProvider globalConfigProvider) {
    if (_initialized) return;

    _receiverService = ReceiverService();
    _templateService = TemplateService();
    _senderAddressService = SenderAddressService();
    _emailTagService = EmailTagService();
    _emailTaskService = EmailTaskService();
    _scheduledEmailService = ScheduledEmailService();
    _trackService = TrackService();

    // 设置全局配置Provider
    _setGlobalConfigProvider(globalConfigProvider);

    _initialized = true;
  }

  /// 设置全局配置Provider到所有服务
  void _setGlobalConfigProvider(GlobalConfigProvider provider) {
    _receiverService.setGlobalConfigProvider(provider);
    _templateService.setGlobalConfigProvider(provider);
    _senderAddressService.setGlobalConfigProvider(provider);
    _emailTagService.setGlobalConfigProvider(provider);
    _emailTaskService.setGlobalConfigProvider(provider);
    _scheduledEmailService.setGlobalConfigProvider(provider);
    _trackService.setGlobalConfigProvider(provider);
  }

  /// 检查是否已初始化
  bool get isInitialized => _initialized;

  /// 收件人管理服务
  ReceiverService get receiverService {
    if (!_initialized) {
      throw Exception('AliyunServiceManager未初始化，请先调用initialize方法');
    }
    return _receiverService;
  }

  /// 模板管理服务
  TemplateService get templateService {
    if (!_initialized) {
      throw Exception('AliyunServiceManager未初始化，请先调用initialize方法');
    }
    return _templateService;
  }

  /// 发信地址管理服务
  SenderAddressService get senderAddressService {
    if (!_initialized) {
      throw Exception('AliyunServiceManager未初始化，请先调用initialize方法');
    }
    return _senderAddressService;
  }

  /// 邮件标签管理服务
  EmailTagService get emailTagService {
    if (!_initialized) {
      throw Exception('AliyunServiceManager未初始化，请先调用initialize方法');
    }
    return _emailTagService;
  }

  /// 邮件任务管理服务
  EmailTaskService get emailTaskService {
    if (!_initialized) {
      throw Exception('AliyunServiceManager未初始化，请先调用initialize方法');
    }
    return _emailTaskService;
  }

  /// 定时发送邮件服务
  ScheduledEmailService get scheduledEmailService {
    if (!_initialized) {
      throw Exception('AliyunServiceManager未初始化，请先调用initialize方法');
    }
    return _scheduledEmailService;
  }

  /// 跟踪数据管理服务
  TrackService get trackService {
    if (!_initialized) {
      throw Exception('AliyunServiceManager未初始化，请先调用initialize方法');
    }
    return _trackService;
  }

  /// 检查配置是否完整
  bool isConfigured() {
    if (!_initialized) return false;
    return _receiverService.isConfigured();
  }

  /// 检查是否已初始化
  void _checkInitialized() {
    if (!_initialized) {
      throw Exception('AliyunServiceManager未初始化，请先调用initialize方法');
    }
  }

  /// 更新全局配置Provider
  void updateGlobalConfigProvider(GlobalConfigProvider provider) {
    _setGlobalConfigProvider(provider);
  }
} 