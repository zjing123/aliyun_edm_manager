import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/providers/config/page_config_provider.dart';
import 'package:aliyun_edm_manager/providers/receiver/receiver_list_provider.dart';
import 'package:aliyun_edm_manager/providers/task/scheduled_email_task_provider.dart';
import 'package:aliyun_edm_manager/providers/task/mail_task_provider.dart';
import 'package:aliyun_edm_manager/providers/template/template_provider.dart';
import 'package:aliyun_edm_manager/providers/sender/sender_address_provider.dart';
import 'package:aliyun_edm_manager/providers/sender/sender_name_provider.dart';
import 'package:aliyun_edm_manager/providers/sender_statistics/sender_statistics_provider.dart';
import 'package:aliyun_edm_manager/providers/tag/tag_provider.dart';
import 'package:aliyun_edm_manager/providers/track/track_provider.dart';

/// 服务定位器 - 统一管理所有服务的依赖注入
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // 核心服务
  AliyunServiceManager? _aliyunServiceManager;
  GlobalConfigProvider? _globalConfigProvider;
  PageConfigProvider? _pageConfigProvider;

  // Provider 实例
  ReceiverListProvider? _receiverListProvider;
  ScheduledEmailTaskProvider? _scheduledEmailTaskProvider;
  MailTaskProvider? _mailTaskProvider;
  TemplateProvider? _templateProvider;
  SenderAddressProvider? _senderAddressProvider;
  SenderNameProvider? _senderNameProvider;
  SenderStatisticsProvider? _senderStatisticsProvider;
  TagProvider? _tagProvider;
  TrackProvider? _trackProvider;

  // 初始化标志
  bool _isInitialized = false;

  /// 初始化服务定位器
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 初始化全局配置Provider
    _globalConfigProvider = GlobalConfigProvider();
    await _globalConfigProvider!.initialize();

    // 2. 初始化页面配置Provider
    _pageConfigProvider = PageConfigProvider();
    if (_globalConfigProvider!.isInitialized && _globalConfigProvider!.configService != null) {
      _pageConfigProvider!.initialize(_globalConfigProvider!.configService!);
    }

    // 3. 初始化阿里云服务管理器
    _aliyunServiceManager = AliyunServiceManager();
    _aliyunServiceManager!.initialize(_globalConfigProvider!);

    // 4. 初始化所有Provider
    _initializeProviders();

    _isInitialized = true;
  }

  /// 初始化所有Provider
  void _initializeProviders() {
    // 收件人列表Provider
    _receiverListProvider = ReceiverListProvider();
    _receiverListProvider!.setDependencies(_globalConfigProvider!, _pageConfigProvider!);

    // 定时邮件任务Provider
    _scheduledEmailTaskProvider = ScheduledEmailTaskProvider(_aliyunServiceManager!, _globalConfigProvider!);

    // 邮件任务Provider
    _mailTaskProvider = MailTaskProvider(_aliyunServiceManager!);

    // 模板Provider
    _templateProvider = TemplateProvider(_aliyunServiceManager!);
    _templateProvider!.setGlobalConfigProvider(_globalConfigProvider!);

    // 发信地址Provider
    _senderAddressProvider = SenderAddressProvider(_aliyunServiceManager!);
    _senderAddressProvider!.setGlobalConfigProvider(_globalConfigProvider!);

    // 发信人名称Provider
    _senderNameProvider = SenderNameProvider();

    // 发信统计Provider
    _senderStatisticsProvider = SenderStatisticsProvider(_globalConfigProvider!);

    // 标签Provider
    _tagProvider = TagProvider(_aliyunServiceManager!);
    _tagProvider!.setGlobalConfigProvider(_globalConfigProvider!);

    // 跟踪数据Provider
    _trackProvider = TrackProvider(_aliyunServiceManager!);
  }

  /// 获取阿里云服务管理器
  AliyunServiceManager get aliyunServiceManager {
    _checkInitialized();
    return _aliyunServiceManager!;
  }

  /// 获取全局配置Provider
  GlobalConfigProvider get globalConfigProvider {
    _checkInitialized();
    return _globalConfigProvider!;
  }

  /// 获取页面配置Provider
  PageConfigProvider get pageConfigProvider {
    _checkInitialized();
    return _pageConfigProvider!;
  }

  /// 获取收件人列表Provider
  ReceiverListProvider get receiverListProvider {
    _checkInitialized();
    return _receiverListProvider!;
  }

  /// 获取定时邮件任务Provider
  ScheduledEmailTaskProvider get scheduledEmailTaskProvider {
    _checkInitialized();
    return _scheduledEmailTaskProvider!;
  }

  /// 获取邮件任务Provider
  MailTaskProvider get mailTaskProvider {
    _checkInitialized();
    return _mailTaskProvider!;
  }

  /// 获取模板Provider
  TemplateProvider get templateProvider {
    _checkInitialized();
    return _templateProvider!;
  }

  /// 获取发信地址Provider
  SenderAddressProvider get senderAddressProvider {
    _checkInitialized();
    return _senderAddressProvider!;
  }

  /// 获取发信人名称Provider
  SenderNameProvider get senderNameProvider {
    _checkInitialized();
    return _senderNameProvider!;
  }

  /// 获取发信统计Provider
  SenderStatisticsProvider get senderStatisticsProvider {
    _checkInitialized();
    return _senderStatisticsProvider!;
  }

  /// 获取标签Provider
  TagProvider get tagProvider {
    _checkInitialized();
    return _tagProvider!;
  }

  /// 获取跟踪数据Provider
  TrackProvider get trackProvider {
    _checkInitialized();
    return _trackProvider!;
  }

  /// 检查是否已初始化
  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('ServiceLocator未初始化，请先调用initialize()方法');
    }
  }

  /// 重新初始化（用于配置更新后）
  Future<void> reinitialize() async {
    _isInitialized = false;
    await initialize();
  }

  /// 清理资源
  void dispose() {
    _isInitialized = false;
    _aliyunServiceManager = null;
    _globalConfigProvider = null;
    _pageConfigProvider = null;
    _receiverListProvider = null;
    _scheduledEmailTaskProvider = null;
    _mailTaskProvider = null;
    _templateProvider = null;
    _senderAddressProvider = null;
    _senderNameProvider = null;
    _senderStatisticsProvider = null;
    _tagProvider = null;
    _trackProvider = null;
  }
} 