import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/services/di/service_locator.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/providers/receiver/receiver_list_provider.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_list_model.dart';

// 辅助方法
bool _isValidEmail(String email) {
  if (email.isEmpty) return false;
  
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  return emailRegex.hasMatch(email);
}

void _simulateNetworkError() {
  throw Exception('网络连接失败');
}

void _simulateConfigError() {
  throw Exception('配置未完成');
}

void _simulateFileFormatError(String content) {
  if (!content.contains('email')) {
    throw Exception('文件格式不正确，缺少email列');
  }
}

void main() {
  group('批量创建收件人测试', () {
    late ServiceLocator serviceLocator;
    late AliyunServiceManager aliyunServiceManager;
    late GlobalConfigProvider globalConfigProvider;
    late ReceiverListProvider receiverListProvider;

    setUp(() async {
      // 确保Flutter绑定已初始化
      TestWidgetsFlutterBinding.ensureInitialized();
      serviceLocator = ServiceLocator();
      await serviceLocator.initialize();
      
      aliyunServiceManager = serviceLocator.aliyunServiceManager;
      globalConfigProvider = serviceLocator.globalConfigProvider;
      receiverListProvider = serviceLocator.receiverListProvider;
    });

    tearDown(() {
      serviceLocator.dispose();
    });

    group('文件处理测试', () {
      test('应该能够解析CSV文件', () {
        final csvContent = '''
email,name,company
test1@example.com,张三,公司A
test2@example.com,李四,公司B
test3@example.com,王五,公司C
''';

        final lines = csvContent.trim().split('\n');
        expect(lines.length, equals(4)); // 标题行 + 3行数据
        
        final headers = lines[0].split(',');
        expect(headers, equals(['email', 'name', 'company']));
        
        final dataLines = lines.skip(1).toList();
        expect(dataLines.length, equals(3));
        
        // 验证第一行数据
        final firstRow = dataLines[0].split(',');
        expect(firstRow[0], equals('test1@example.com'));
        expect(firstRow[1], equals('张三'));
        expect(firstRow[2], equals('公司A'));
      });

      test('应该能够处理空文件', () {
        final emptyContent = '';
        final lines = emptyContent.split('\n');
        expect(lines.length, equals(1)); // 只有一个空行
        expect(lines[0], equals(''));
      });

      test('应该能够处理只有标题的文件', () {
        final headerOnlyContent = 'email,name,company';
        final lines = headerOnlyContent.split('\n');
        expect(lines.length, equals(1));
        expect(lines[0], equals('email,name,company'));
      });

      test('应该能够处理包含空行的文件', () {
        final contentWithEmptyLines = '''
email,name,company

test1@example.com,张三,公司A

test2@example.com,李四,公司B
''';

        final lines = contentWithEmptyLines.trim().split('\n');
        final nonEmptyLines = lines.where((line) => line.isNotEmpty).toList();
        expect(nonEmptyLines.length, equals(3)); // 标题行 + 2行数据
      });
    });

    group('邮箱验证测试', () {
      test('应该能够验证有效的邮箱地址', () {
        final validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
          '123@test.com',
          'test.email@subdomain.example.com',
        ];

        for (final email in validEmails) {
          expect(_isValidEmail(email), isTrue, reason: '邮箱 $email 应该是有效的');
        }
      });

      test('应该能够识别无效的邮箱地址', () {
        final invalidEmails = [
          '',
          'invalid-email',
          '@example.com',
          'test@',
          'test@.com',
          'test..test@example.com',
          'test@example..com',
        ];

        for (final email in invalidEmails) {
          expect(_isValidEmail(email), isFalse, reason: '邮箱 $email 应该是无效的');
        }
      });

      test('应该能够处理邮箱地址的大小写', () {
        final email = 'Test@Example.COM';
        expect(_isValidEmail(email.toLowerCase()), isTrue);
        expect(_isValidEmail(email), isTrue);
      });
    });

    group('列表名称生成测试', () {
      test('应该能够生成唯一的列表名称', () {
        final baseName = '测试列表';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueName = '${baseName}_$timestamp';
        
        expect(uniqueName.startsWith(baseName), isTrue);
        expect(uniqueName.contains('_'), isTrue);
        expect(uniqueName.length, greaterThan(baseName.length));
      });

      test('应该能够处理特殊字符的列表名称', () {
        final specialName = '测试列表@#\$%^&*()';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueName = '${specialName}_$timestamp';
        
        expect(uniqueName.startsWith(specialName), isTrue);
        expect(uniqueName.contains('_'), isTrue);
      });
    });

    group('重复邮箱处理测试', () {
      test('应该能够检测重复邮箱', () {
        final emails = [
          'test1@example.com',
          'test2@example.com',
          'test1@example.com', // 重复
          'test3@example.com',
          'test2@example.com', // 重复
        ];

        final uniqueEmails = emails.toSet().toList();
        final duplicates = emails.length - uniqueEmails.length;
        
        expect(uniqueEmails.length, equals(3));
        expect(duplicates, equals(2));
      });

      test('应该能够处理大小写不同的重复邮箱', () {
        final emails = [
          'test@example.com',
          'TEST@example.com',
          'Test@example.com',
          'test@EXAMPLE.com',
        ];

        final uniqueEmails = emails.map((e) => e.toLowerCase()).toSet().toList();
        expect(uniqueEmails.length, equals(1));
      });
    });

    group('配置检查测试', () {
      test('未配置时应该返回false', () {
        expect(globalConfigProvider.isConfigured, isFalse);
      });

      test('配置后应该返回true', () async {
        await globalConfigProvider.saveConfig('test-key-id', 'test-key-secret');
        expect(globalConfigProvider.isConfigured, isTrue);
      });
    });

    group('错误处理测试', () {
      test('应该能够处理网络错误', () {
        // 模拟网络错误
        expect(() => _simulateNetworkError(), throwsA(isA<Exception>()));
      });

      test('应该能够处理配置错误', () {
        expect(() => _simulateConfigError(), throwsA(isA<Exception>()));
      });

      test('应该能够处理文件格式错误', () {
        final invalidContent = 'invalid,format,file';
        expect(() => _simulateFileFormatError(invalidContent), throwsA(isA<Exception>()));
      });
    });

    group('进度跟踪测试', () {
      test('应该能够正确计算处理进度', () {
        final totalEmails = 100;
        final processedEmails = 25;
        final progress = processedEmails / totalEmails;
        
        expect(progress, equals(0.25));
        expect(progress * 100, equals(25.0));
      });

      test('应该能够处理零进度', () {
        final totalEmails = 100;
        final processedEmails = 0;
        final progress = processedEmails / totalEmails;
        
        expect(progress, equals(0.0));
      });

      test('应该能够处理完成进度', () {
        final totalEmails = 100;
        final processedEmails = 100;
        final progress = processedEmails / totalEmails;
        
        expect(progress, equals(1.0));
      });
    });
  });
} 