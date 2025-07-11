import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/services/config/config_service.dart';

void main() {
  group('ConfigService 测试', () {
    late ConfigService configService;

    setUp(() async {
      // 确保Flutter绑定已初始化
      TestWidgetsFlutterBinding.ensureInitialized();
      configService = await ConfigService.getInstance();
    });

    test('应该能够创建ConfigService实例', () {
      expect(configService, isA<ConfigService>());
    });

    test('应该能够保存和读取Access Key ID', () async {
      const testKeyId = 'test-access-key-id';
      
      // 保存Access Key ID
      final saveResult = await configService.setAccessKeyId(testKeyId);
      expect(saveResult, isTrue);
      
      // 读取Access Key ID
      final retrievedKeyId = configService.getAccessKeyId();
      expect(retrievedKeyId, equals(testKeyId));
    });

    test('应该能够保存和读取Access Key Secret', () async {
      const testKeySecret = 'test-access-key-secret';
      
      // 保存Access Key Secret
      final saveResult = await configService.setAccessKeySecret(testKeySecret);
      expect(saveResult, isTrue);
      
      // 读取Access Key Secret
      final retrievedKeySecret = configService.getAccessKeySecret();
      expect(retrievedKeySecret, equals(testKeySecret));
    });

    test('应该能够同时保存两个密钥', () async {
      const testKeyId = 'test-access-key-id';
      const testKeySecret = 'test-access-key-secret';
      
      // 同时保存两个密钥
      final saveResult = await configService.saveConfig(testKeyId, testKeySecret);
      expect(saveResult, isTrue);
      
      // 验证两个密钥都保存成功
      final retrievedKeyId = configService.getAccessKeyId();
      final retrievedKeySecret = configService.getAccessKeySecret();
      
      expect(retrievedKeyId, equals(testKeyId));
      expect(retrievedKeySecret, equals(testKeySecret));
    });

    test('未配置时isConfigured应该返回false', () {
      final isConfigured = configService.isConfigured();
      expect(isConfigured, isFalse);
    });

    test('配置完整时isConfigured应该返回true', () async {
      // 保存配置
      await configService.saveConfig('test-key-id', 'test-key-secret');
      
      // 验证配置状态
      final isConfigured = configService.isConfigured();
      expect(isConfigured, isTrue);
    });

    test('只配置一个密钥时isConfigured应该返回false', () async {
      // 只保存Access Key ID
      await configService.setAccessKeyId('test-key-id');
      
      // 验证配置状态
      final isConfigured = configService.isConfigured();
      expect(isConfigured, isFalse);
    });

    test('应该能够清除配置', () async {
      // 先保存配置
      await configService.saveConfig('test-key-id', 'test-key-secret');
      expect(configService.isConfigured(), isTrue);
      
      // 清除配置
      final clearResult = await configService.clearConfig();
      expect(clearResult, isTrue);
      
      // 验证配置已清除
      expect(configService.isConfigured(), isFalse);
      expect(configService.getAccessKeyId(), isNull);
      expect(configService.getAccessKeySecret(), isNull);
    });

    test('应该能够获取默认过滤邮箱列表', () {
      final filterEmails = configService.getFilterEmails();
      expect(filterEmails, isA<List<String>>());
    });

    test('应该能够保存和读取过滤邮箱列表', () async {
      final testFilterEmails = ['test1@example.com', 'test2@example.com'];
      
      // 保存过滤邮箱列表
      final saveResult = await configService.setFilterEmails(testFilterEmails);
      expect(saveResult, isTrue);
      
      // 读取过滤邮箱列表
      final retrievedFilterEmails = configService.getFilterEmails();
      expect(retrievedFilterEmails, equals(testFilterEmails));
    });

    test('应该能够处理空字符串的密钥', () async {
      // 保存空字符串
      await configService.setAccessKeyId('');
      await configService.setAccessKeySecret('');
      
      // 验证配置状态
      expect(configService.isConfigured(), isFalse);
      expect(configService.getAccessKeyId(), equals(''));
      expect(configService.getAccessKeySecret(), equals(''));
    });

    test('应该能够处理特殊字符的密钥', () async {
      const specialKeyId = 'test-key-id@#\$%^&*()';
      const specialKeySecret = 'test-key-secret@#\$%^&*()';
      
      // 保存包含特殊字符的密钥
      await configService.saveConfig(specialKeyId, specialKeySecret);
      
      // 验证保存成功
      expect(configService.getAccessKeyId(), equals(specialKeyId));
      expect(configService.getAccessKeySecret(), equals(specialKeySecret));
      expect(configService.isConfigured(), isTrue);
    });

    test('应该能够处理长密钥', () async {
      final longKeyId = 'a' * 1000; // 1000个字符
      final longKeySecret = 'b' * 1000; // 1000个字符
      
      // 保存长密钥
      await configService.saveConfig(longKeyId, longKeySecret);
      
      // 验证保存成功
      expect(configService.getAccessKeyId(), equals(longKeyId));
      expect(configService.getAccessKeySecret(), equals(longKeySecret));
      expect(configService.isConfigured(), isTrue);
    });

    test('ConfigService应该是单例模式', () async {
      final instance1 = await ConfigService.getInstance();
      final instance2 = await ConfigService.getInstance();
      
      expect(identical(instance1, instance2), isTrue);
    });

    test('应该能够处理配置更新', () async {
      // 初始配置
      await configService.saveConfig('initial-key-id', 'initial-key-secret');
      expect(configService.getAccessKeyId(), equals('initial-key-id'));
      
      // 更新配置
      await configService.saveConfig('updated-key-id', 'updated-key-secret');
      expect(configService.getAccessKeyId(), equals('updated-key-id'));
      expect(configService.getAccessKeySecret(), equals('updated-key-secret'));
    });

    test('应该能够处理部分配置更新', () async {
      // 初始配置
      await configService.saveConfig('initial-key-id', 'initial-key-secret');
      
      // 只更新Access Key ID
      await configService.setAccessKeyId('updated-key-id');
      expect(configService.getAccessKeyId(), equals('updated-key-id'));
      expect(configService.getAccessKeySecret(), equals('initial-key-secret'));
    });
  });
} 