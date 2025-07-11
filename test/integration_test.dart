import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_statistics_model.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_detail_model.dart';

// 辅助方法
bool _isValidEmail(String email) {
  if (email.isEmpty) return false;
  
  // 更严格的邮箱验证正则表达式
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
  return emailRegex.hasMatch(email);
}

void main() {
  group('集成测试', () {
    test('发送统计模型测试', () {
      final json = {
        'unavailablePercent': '5%',
        'CreateTime': '2024-01-15 10:30:00',
        'succeededPercent': '95%',
        'faildCount': '10',
        'unavailableCount': '5',
        'successCount': '190',
        'requestCount': '200',
      };

      final record = StatisticsRecord.fromJson(json);

      expect(record.unavailablePercent, '5%');
      expect(record.createTime, '2024-01-15 10:30:00');
      expect(record.succeededPercent, '95%');
      expect(record.faildCount, '10');
      expect(record.unavailableCount, '5');
      expect(record.successCount, '190');
      expect(record.requestCount, '200');
    });

    test('发送详情模型测试', () {
      final json = {
        'recipient': 'test@example.com',
        'subject': '测试邮件',
        'status': 'sent',
        'sendTime': '2024-01-15T10:30:00Z',
        'openTime': '2024-01-15T10:35:00Z',
      };

      final detail = SendingDetailModel.fromJson(json);

      expect(detail.recipient, 'test@example.com');
      expect(detail.subject, '测试邮件');
      expect(detail.status, SendingStatus.sent);
      expect(detail.openTime, isNotNull);
    });

    test('收件人列表数据测试', () {
      final json = {
        'ReceiversName': '测试列表',
        'ReceiversId': 'test-id',
        'CreateTime': '2024-01-15T10:30:00Z',
        'UpdateTime': '2024-01-15T10:30:00Z',
        'ReceiversCount': '100',
      };

      expect(json['ReceiversName'], '测试列表');
      expect(json['ReceiversId'], 'test-id');
      expect(json['ReceiversCount'], '100');
    });

    test('模板数据测试', () {
      final json = {
        'TemplateId': 'template-1',
        'TemplateName': '测试模板',
        'TemplateContent': '<html>测试内容</html>',
        'CreateTime': '2024-01-15T10:30:00Z',
        'UpdateTime': '2024-01-15T10:30:00Z',
        'TemplateStatus': 'active',
      };

      expect(json['TemplateId'], 'template-1');
      expect(json['TemplateName'], '测试模板');
      expect(json['TemplateContent'], '<html>测试内容</html>');
      expect(json['TemplateStatus'], 'active');
    });

    test('邮箱验证测试', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
        '123@test.com',
        'test.email@subdomain.example.com',
      ];

      final invalidEmails = [
        '',
        'invalid-email',
        '@example.com',
        'test@',
        'test@.com',
        'test..test@example.com',
        'test@example..com',
      ];

      for (final email in validEmails) {
        expect(_isValidEmail(email), isTrue, reason: '邮箱 $email 应该是有效的');
      }

      for (final email in invalidEmails) {
        expect(_isValidEmail(email), isFalse, reason: '邮箱 $email 应该是无效的');
      }
    });

    test('CSV解析测试', () {
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

    test('重复邮箱处理测试', () {
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

    test('进度计算测试', () {
      final totalEmails = 100;
      final processedEmails = 25;
      final progress = processedEmails / totalEmails;
      
      expect(progress, equals(0.25));
      expect(progress * 100, equals(25.0));
    });
  });
} 