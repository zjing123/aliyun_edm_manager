import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_services.dart';
import 'package:aliyun_edm_manager/providers/global_config_provider.dart';

void main() {
  group('阿里云服务架构测试', () {
    late AliyunServiceManager serviceManager;
    late GlobalConfigProvider globalConfigProvider;

    setUp(() {
      serviceManager = AliyunServiceManager();
      globalConfigProvider = GlobalConfigProvider();
    });

    test('服务管理器初始化测试', () {
      expect(serviceManager.isInitialized, false);
      
      serviceManager.initialize(globalConfigProvider);
      
      expect(serviceManager.isInitialized, true);
    });

    test('服务管理器实例创建测试', () {
      final instance1 = AliyunServiceManager();
      final instance2 = AliyunServiceManager();
      
      // 现在可以创建多个实例
      expect(instance1, isA<AliyunServiceManager>());
      expect(instance2, isA<AliyunServiceManager>());
    });

    test('服务访问测试', () {
      serviceManager.initialize(globalConfigProvider);
      
      expect(serviceManager.receiverService, isA<ReceiverService>());
      expect(serviceManager.templateService, isA<TemplateService>());
      expect(serviceManager.senderAddressService, isA<SenderAddressService>());
      expect(serviceManager.emailTagService, isA<EmailTagService>());
      expect(serviceManager.emailTaskService, isA<EmailTaskService>());
      expect(serviceManager.scheduledEmailService, isA<ScheduledEmailService>());
    });

    test('未初始化时访问服务应该抛出异常', () {
      // 创建一个新的未初始化的服务管理器实例
      final uninitializedManager = AliyunServiceManager();
      
      expect(() => uninitializedManager.receiverService, throwsException);
      expect(() => uninitializedManager.templateService, throwsException);
      expect(() => uninitializedManager.senderAddressService, throwsException);
      expect(() => uninitializedManager.emailTagService, throwsException);
      expect(() => uninitializedManager.emailTaskService, throwsException);
      expect(() => uninitializedManager.scheduledEmailService, throwsException);
    });

    test('配置检查测试', () {
      expect(serviceManager.isConfigured(), false);
      
      serviceManager.initialize(globalConfigProvider);
      
      // 由于没有配置AccessKey，应该返回false
      expect(serviceManager.isConfigured(), false);
    });

    test('更新全局配置Provider测试', () {
      serviceManager.initialize(globalConfigProvider);
      
      final newProvider = GlobalConfigProvider();
      serviceManager.updateGlobalConfigProvider(newProvider);
      
      // 应该不会抛出异常
      expect(serviceManager.isInitialized, true);
    });
  });

  group('基础服务类测试', () {
    late TestService testService;
    late GlobalConfigProvider globalConfigProvider;

    setUp(() {
      testService = TestService();
      globalConfigProvider = GlobalConfigProvider();
    });

    test('参数验证测试', () {
      // 分页参数验证
      expect(() => testService.testValidatePagination(0, 10), throwsArgumentError);
      expect(() => testService.testValidatePagination(1, 0), throwsArgumentError);
      expect(() => testService.testValidatePagination(1, 100), throwsArgumentError);
      expect(() => testService.testValidatePagination(1, 10), returnsNormally);

      // 字符串长度验证
      expect(() => testService.testValidateStringLength('test', 'TestField', 3), throwsArgumentError);
      expect(() => testService.testValidateStringLength('test', 'TestField', 10), returnsNormally);
    });
  });
}

/// 测试用的服务类，继承自BaseAliyunService
class TestService extends BaseAliyunService {
  void testValidatePagination(int pageNo, int pageSize) {
    validatePagination(pageNo, pageSize);
  }

  void testValidateStringLength(String value, String fieldName, int maxLength) {
    validateStringLength(value, fieldName, maxLength);
  }
} 