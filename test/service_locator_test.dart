import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/services/di/service_locator.dart';
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

void main() {
  group('ServiceLocator 测试', () {
    late ServiceLocator serviceLocator;

    setUp(() {
      // 确保Flutter绑定已初始化
      TestWidgetsFlutterBinding.ensureInitialized();
      serviceLocator = ServiceLocator();
    });

    tearDown(() {
      serviceLocator.dispose();
    });

    test('ServiceLocator 应该是单例模式', () {
      final instance1 = ServiceLocator();
      final instance2 = ServiceLocator();
      expect(identical(instance1, instance2), isTrue);
    });

    test('初始化前访问服务应该抛出异常', () {
      expect(
        () => serviceLocator.aliyunServiceManager,
        throwsA(isA<Exception>()),
      );

      expect(
        () => serviceLocator.globalConfigProvider,
        throwsA(isA<Exception>()),
      );

      expect(
        () => serviceLocator.receiverListProvider,
        throwsA(isA<Exception>()),
      );
    });

    test('应该能够成功初始化所有服务', () async {
      await serviceLocator.initialize();

      // 验证核心服务已初始化
      expect(serviceLocator.aliyunServiceManager, isNotNull);
      expect(serviceLocator.globalConfigProvider, isNotNull);
      expect(serviceLocator.pageConfigProvider, isNotNull);

      // 验证所有Provider已初始化
      expect(serviceLocator.receiverListProvider, isNotNull);
      expect(serviceLocator.scheduledEmailTaskProvider, isNotNull);
      expect(serviceLocator.mailTaskProvider, isNotNull);
      expect(serviceLocator.templateProvider, isNotNull);
      expect(serviceLocator.senderAddressProvider, isNotNull);
      expect(serviceLocator.senderNameProvider, isNotNull);
      expect(serviceLocator.senderStatisticsProvider, isNotNull);
      expect(serviceLocator.tagProvider, isNotNull);
      expect(serviceLocator.trackProvider, isNotNull);
    });

    test('重复初始化应该不会重复创建实例', () async {
      await serviceLocator.initialize();
      final firstManager = serviceLocator.aliyunServiceManager;
      final firstConfig = serviceLocator.globalConfigProvider;

      await serviceLocator.initialize();
      final secondManager = serviceLocator.aliyunServiceManager;
      final secondConfig = serviceLocator.globalConfigProvider;

      expect(identical(firstManager, secondManager), isTrue);
      expect(identical(firstConfig, secondConfig), isTrue);
    });

    test('应该能够重新初始化服务', () async {
      await serviceLocator.initialize();
      final firstManager = serviceLocator.aliyunServiceManager;

      await serviceLocator.reinitialize();
      final secondManager = serviceLocator.aliyunServiceManager;

      // 重新初始化后应该创建新的实例
      expect(identical(firstManager, secondManager), isFalse);
    });

    test('dispose 应该清理所有服务实例', () async {
      await serviceLocator.initialize();
      
      // 验证服务已初始化
      expect(serviceLocator.aliyunServiceManager, isNotNull);
      
      serviceLocator.dispose();
      
      // 验证服务已清理
      expect(
        () => serviceLocator.aliyunServiceManager,
        throwsA(isA<Exception>()),
      );
    });

    test('AliyunServiceManager 应该正确初始化', () async {
      await serviceLocator.initialize();
      
      final serviceManager = serviceLocator.aliyunServiceManager;
      expect(serviceManager, isA<AliyunServiceManager>());
      expect(serviceManager.isInitialized, isTrue);
    });

    test('GlobalConfigProvider 应该正确初始化', () async {
      await serviceLocator.initialize();
      
      final globalConfig = serviceLocator.globalConfigProvider;
      expect(globalConfig, isA<GlobalConfigProvider>());
      expect(globalConfig.isInitialized, isTrue);
    });

    test('所有Provider应该正确设置依赖', () async {
      await serviceLocator.initialize();
      
      // 验证ReceiverListProvider设置了依赖
      final receiverProvider = serviceLocator.receiverListProvider;
      expect(receiverProvider, isA<ReceiverListProvider>());
      
      // 验证ScheduledEmailTaskProvider设置了依赖
      final scheduledProvider = serviceLocator.scheduledEmailTaskProvider;
      expect(scheduledProvider, isA<ScheduledEmailTaskProvider>());
      
      // 验证MailTaskProvider设置了依赖
      final mailTaskProvider = serviceLocator.mailTaskProvider;
      expect(mailTaskProvider, isA<MailTaskProvider>());
      
      // 验证TemplateProvider设置了依赖
      final templateProvider = serviceLocator.templateProvider;
      expect(templateProvider, isA<TemplateProvider>());
      
      // 验证SenderAddressProvider设置了依赖
      final senderAddressProvider = serviceLocator.senderAddressProvider;
      expect(senderAddressProvider, isA<SenderAddressProvider>());
      
      // 验证SenderNameProvider设置了依赖
      final senderNameProvider = serviceLocator.senderNameProvider;
      expect(senderNameProvider, isA<SenderNameProvider>());
      
      // 验证SenderStatisticsProvider设置了依赖
      final senderStatisticsProvider = serviceLocator.senderStatisticsProvider;
      expect(senderStatisticsProvider, isA<SenderStatisticsProvider>());
      
      // 验证TagProvider设置了依赖
      final tagProvider = serviceLocator.tagProvider;
      expect(tagProvider, isA<TagProvider>());
      
      // 验证TrackProvider设置了依赖
      final trackProvider = serviceLocator.trackProvider;
      expect(trackProvider, isA<TrackProvider>());
    });
  });
} 