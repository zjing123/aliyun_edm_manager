import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/services/aliyun/receiver/receiver_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/template/template_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/sender_address/sender_address_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/email_tag/email_tag_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/email_task/email_task_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/scheduled_email/scheduled_email_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/track/track_service.dart';

void main() {
  group('AliyunServiceManager 测试', () {
    late AliyunServiceManager serviceManager;
    late GlobalConfigProvider globalConfigProvider;

    setUp(() {
      // 确保Flutter绑定已初始化
      TestWidgetsFlutterBinding.ensureInitialized();
      serviceManager = AliyunServiceManager();
      globalConfigProvider = GlobalConfigProvider();
    });

    test('应该能够创建AliyunServiceManager实例', () {
      expect(serviceManager, isA<AliyunServiceManager>());
    });

    test('初始化前isInitialized应该为false', () {
      expect(serviceManager.isInitialized, isFalse);
    });

    test('应该能够成功初始化服务管理器', () {
      serviceManager.initialize(globalConfigProvider);
      
      expect(serviceManager.isInitialized, isTrue);
    });

    test('重复初始化应该不会出错', () {
      serviceManager.initialize(globalConfigProvider);
      serviceManager.initialize(globalConfigProvider);
      
      expect(serviceManager.isInitialized, isTrue);
    });

    test('初始化后应该能够访问所有子服务', () {
      serviceManager.initialize(globalConfigProvider);
      
      // 验证所有子服务都可以访问
      expect(serviceManager.receiverService, isA<ReceiverService>());
      expect(serviceManager.templateService, isA<TemplateService>());
      expect(serviceManager.senderAddressService, isA<SenderAddressService>());
      expect(serviceManager.emailTagService, isA<EmailTagService>());
      expect(serviceManager.emailTaskService, isA<EmailTaskService>());
      expect(serviceManager.scheduledEmailService, isA<ScheduledEmailService>());
      expect(serviceManager.trackService, isA<TrackService>());
    });

    test('未初始化时访问服务应该抛出异常', () {
      expect(
        () => serviceManager.receiverService,
        throwsA(isA<Exception>()),
      );

      expect(
        () => serviceManager.templateService,
        throwsA(isA<Exception>()),
      );

      expect(
        () => serviceManager.senderAddressService,
        throwsA(isA<Exception>()),
      );

      expect(
        () => serviceManager.emailTagService,
        throwsA(isA<Exception>()),
      );

      expect(
        () => serviceManager.emailTaskService,
        throwsA(isA<Exception>()),
      );

      expect(
        () => serviceManager.scheduledEmailService,
        throwsA(isA<Exception>()),
      );

      expect(
        () => serviceManager.trackService,
        throwsA(isA<Exception>()),
      );
    });

    test('未配置时isConfigured应该返回false', () {
      serviceManager.initialize(globalConfigProvider);
      expect(serviceManager.isConfigured(), isFalse);
    });

    test('配置后isConfigured应该返回true', () async {
      // 模拟配置已设置
      await globalConfigProvider.saveConfig('test-key-id', 'test-key-secret');
      
      serviceManager.initialize(globalConfigProvider);
      expect(serviceManager.isConfigured(), isTrue);
    });

    test('所有子服务都应该正确设置全局配置Provider', () {
      serviceManager.initialize(globalConfigProvider);
      
      // 验证所有子服务都设置了全局配置Provider
      expect(serviceManager.receiverService.isConfigured(), isFalse);
      expect(serviceManager.templateService.isConfigured(), isFalse);
      expect(serviceManager.senderAddressService.isConfigured(), isFalse);
      expect(serviceManager.emailTagService.isConfigured(), isFalse);
      expect(serviceManager.emailTaskService.isConfigured(), isFalse);
      expect(serviceManager.scheduledEmailService.isConfigured(), isFalse);
      expect(serviceManager.trackService.isConfigured(), isFalse);
    });

    test('配置后所有子服务都应该返回正确的配置状态', () async {
      // 模拟配置已设置
      await globalConfigProvider.saveConfig('test-key-id', 'test-key-secret');
      
      serviceManager.initialize(globalConfigProvider);
      
      // 验证所有子服务都返回正确的配置状态
      expect(serviceManager.receiverService.isConfigured(), isTrue);
      expect(serviceManager.templateService.isConfigured(), isTrue);
      expect(serviceManager.senderAddressService.isConfigured(), isTrue);
      expect(serviceManager.emailTagService.isConfigured(), isTrue);
      expect(serviceManager.emailTaskService.isConfigured(), isTrue);
      expect(serviceManager.scheduledEmailService.isConfigured(), isTrue);
      expect(serviceManager.trackService.isConfigured(), isTrue);
    });

    test('服务管理器应该支持多个实例', () {
      final manager1 = AliyunServiceManager();
      final manager2 = AliyunServiceManager();
      
      expect(identical(manager1, manager2), isFalse);
      
      manager1.initialize(globalConfigProvider);
      manager2.initialize(globalConfigProvider);
      
      expect(manager1.isInitialized, isTrue);
      expect(manager2.isInitialized, isTrue);
    });

    test('子服务应该是不同的实例', () {
      serviceManager.initialize(globalConfigProvider);
      
      final receiver1 = serviceManager.receiverService;
      final receiver2 = serviceManager.receiverService;
      
      // 每次访问应该返回相同的实例
      expect(identical(receiver1, receiver2), isTrue);
    });

    test('不同服务管理器中的子服务应该是不同实例', () {
      final manager1 = AliyunServiceManager();
      final manager2 = AliyunServiceManager();
      
      manager1.initialize(globalConfigProvider);
      manager2.initialize(globalConfigProvider);
      
      final receiver1 = manager1.receiverService;
      final receiver2 = manager2.receiverService;
      
      // 不同管理器中的服务应该是不同实例
      expect(identical(receiver1, receiver2), isFalse);
    });
  });
} 