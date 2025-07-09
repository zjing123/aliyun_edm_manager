import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_statistics_model.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_detail_model.dart';

void main() {
  group('发送统计模型测试', () {
    test('StatisticsRecord.fromJson 应该正确解析数据', () {
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

    test('StatisticsRecord 应该正确计算成功率', () {
      final record = StatisticsRecord(
        unavailablePercent: '5%',
        createTime: '2024-01-15 10:30:00',
        succeededPercent: '95%',
        faildCount: '10',
        unavailableCount: '5',
        successCount: '190',
        requestCount: '200',
      );

      expect(record.successCountInt, 190);
      expect(record.faildCountInt, 10);
      expect(record.unavailableCountInt, 5);
      expect(record.requestCountInt, 200);
      expect(record.successRate, 95.0);
    });

    test('SendingStatisticsModel.fromJson 应该正确解析数据', () {
      final json = {
        'TotalCount': 1,
        'RequestId': 'test-request-id',
        'data': {
          'stat': [
            {
              'unavailablePercent': '5%',
              'CreateTime': '2024-01-15 10:30:00',
              'succeededPercent': '95%',
              'faildCount': '10',
              'unavailableCount': '5',
              'successCount': '190',
              'requestCount': '200',
            }
          ]
        }
      };

      final model = SendingStatisticsModel.fromJson(json);

      expect(model.totalCount, 1);
      expect(model.requestId, 'test-request-id');
      expect(model.records.length, 1);
      expect(model.records.first.successCount, '190');
    });
  });

  group('发送详情模型测试', () {
    test('SendingDetailModel.fromJson 应该正确解析数据', () {
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

    test('SendingDetailModel 应该正确显示状态文本', () {
      final sentDetail = SendingDetailModel(
        recipient: 'test1@example.com',
        subject: '测试邮件1',
        status: SendingStatus.sent,
        sendTime: DateTime.now(),
      );

      final openedDetail = SendingDetailModel(
        recipient: 'test2@example.com',
        subject: '测试邮件2',
        status: SendingStatus.opened,
        sendTime: DateTime.now(),
        openTime: DateTime.now(),
      );

      final failedDetail = SendingDetailModel(
        recipient: 'test3@example.com',
        subject: '测试邮件3',
        status: SendingStatus.failed,
        sendTime: DateTime.now(),
      );

      expect(sentDetail.statusText, '已发送');
      expect(openedDetail.statusText, '已打开');
      expect(failedDetail.statusText, '发送失败');
    });
  });
} 