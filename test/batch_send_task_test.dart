import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/models/batch_send_task_model.dart';

void main() {
  group('BatchSendTaskModel Tests', () {
    test('should create BatchSendTaskModel with required fields', () {
      final task = BatchSendTaskModel(
        taskId: 'test-task-001',
        taskName: '测试任务',
        templateId: 'template-001',
        templateName: '测试模板',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver-001',
            receiverName: '测试收件人列表',
            intervalMinutes: 5,
            emailCount: 100,
          ),
        ],
        senderAddress: 'test@example.com',
        senderName: '测试发件人',
        createdAt: DateTime.now(),
      );

      expect(task.taskId, 'test-task-001');
      expect(task.taskName, '测试任务');
      expect(task.templateId, 'template-001');
      expect(task.templateName, '测试模板');
      expect(task.receiverLists.length, 1);
      expect(task.senderAddress, 'test@example.com');
      expect(task.senderName, '测试发件人');
      expect(task.status, 'pending');
      expect(task.enableTracking, false);
      expect(task.totalEmails, 0);
      expect(task.sentEmails, 0);
      expect(task.failedEmails, 0);
    });

    test('should create BatchSendTaskModel with optional fields', () {
      final task = BatchSendTaskModel(
        taskId: 'test-task-002',
        taskName: '测试任务2',
        templateId: 'template-002',
        templateName: '测试模板2',
        receiverLists: [],
        senderAddress: 'test2@example.com',
        senderName: '测试发件人2',
        tag: 'test-tag',
        enableTracking: true,
        status: 'running',
        createdAt: DateTime.now(),
        startedAt: DateTime.now(),
        totalEmails: 200,
        sentEmails: 50,
        failedEmails: 2,
      );

      expect(task.tag, 'test-tag');
      expect(task.enableTracking, true);
      expect(task.status, 'running');
      expect(task.startedAt, isNotNull);
      expect(task.totalEmails, 200);
      expect(task.sentEmails, 50);
      expect(task.failedEmails, 2);
    });

    test('should create BatchSendTaskModel from Map', () {
      final map = {
        'TaskId': 'test-task-003',
        'TaskName': '测试任务3',
        'TemplateId': 'template-003',
        'TemplateName': '测试模板3',
        'ReceiverLists': [
          {
            'ReceiverId': 'receiver-003',
            'ReceiverName': '测试收件人列表3',
            'IntervalMinutes': 10,
            'EmailCount': 150,
          }
        ],
        'SenderAddress': 'test3@example.com',
        'SenderName': '测试发件人3',
        'Tag': 'test-tag-3',
        'EnableTracking': true,
        'Status': 'completed',
        'CreatedAt': '2024-01-01T00:00:00.000Z',
        'StartedAt': '2024-01-01T01:00:00.000Z',
        'CompletedAt': '2024-01-01T02:00:00.000Z',
        'TotalEmails': 150,
        'SentEmails': 150,
        'FailedEmails': 0,
      };

      final task = BatchSendTaskModel.fromMap(map);

      expect(task.taskId, 'test-task-003');
      expect(task.taskName, '测试任务3');
      expect(task.templateId, 'template-003');
      expect(task.templateName, '测试模板3');
      expect(task.receiverLists.length, 1);
      expect(task.receiverLists.first.receiverId, 'receiver-003');
      expect(task.receiverLists.first.receiverName, '测试收件人列表3');
      expect(task.receiverLists.first.intervalMinutes, 10);
      expect(task.receiverLists.first.emailCount, 150);
      expect(task.senderAddress, 'test3@example.com');
      expect(task.senderName, '测试发件人3');
      expect(task.tag, 'test-tag-3');
      expect(task.enableTracking, true);
      expect(task.status, 'completed');
      expect(task.totalEmails, 150);
      expect(task.sentEmails, 150);
      expect(task.failedEmails, 0);
    });

    test('should convert BatchSendTaskModel to Map', () {
      final task = BatchSendTaskModel(
        taskId: 'test-task-004',
        taskName: '测试任务4',
        templateId: 'template-004',
        templateName: '测试模板4',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver-004',
            receiverName: '测试收件人列表4',
            intervalMinutes: 15,
            emailCount: 200,
          ),
        ],
        senderAddress: 'test4@example.com',
        senderName: '测试发件人4',
        tag: 'test-tag-4',
        enableTracking: true,
        status: 'pending',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        totalEmails: 200,
        sentEmails: 0,
        failedEmails: 0,
      );

      final map = task.toMap();

      expect(map['TaskId'], 'test-task-004');
      expect(map['TaskName'], '测试任务4');
      expect(map['TemplateId'], 'template-004');
      expect(map['TemplateName'], '测试模板4');
      expect(map['SenderAddress'], 'test4@example.com');
      expect(map['SenderName'], '测试发件人4');
      expect(map['Tag'], 'test-tag-4');
      expect(map['EnableTracking'], true);
      expect(map['Status'], 'pending');
      expect(map['TotalEmails'], 200);
      expect(map['SentEmails'], 0);
      expect(map['FailedEmails'], 0);
      expect(map['ReceiverLists'], isA<List>());
      expect(map['ReceiverLists'].length, 1);
    });

    test('should copy BatchSendTaskModel with new values', () {
      final originalTask = BatchSendTaskModel(
        taskId: 'test-task-005',
        taskName: '测试任务5',
        templateId: 'template-005',
        templateName: '测试模板5',
        receiverLists: [],
        senderAddress: 'test5@example.com',
        senderName: '测试发件人5',
        createdAt: DateTime.now(),
      );

      final copiedTask = originalTask.copyWith(
        status: 'running',
        sentEmails: 50,
        startedAt: DateTime.now(),
      );

      expect(copiedTask.taskId, originalTask.taskId);
      expect(copiedTask.taskName, originalTask.taskName);
      expect(copiedTask.status, 'running');
      expect(copiedTask.sentEmails, 50);
      expect(copiedTask.startedAt, isNotNull);
      expect(copiedTask.completedAt, isNull);
    });
  });

  group('ReceiverListConfig Tests', () {
    test('should create ReceiverListConfig with required fields', () {
      final config = ReceiverListConfig(
        receiverId: 'receiver-test-001',
        receiverName: '测试收件人列表',
        intervalMinutes: 5,
        emailCount: 100,
      );

      expect(config.receiverId, 'receiver-test-001');
      expect(config.receiverName, '测试收件人列表');
      expect(config.intervalMinutes, 5);
      expect(config.emailCount, 100);
    });

    test('should create ReceiverListConfig from Map', () {
      final map = {
        'ReceiverId': 'receiver-test-002',
        'ReceiverName': '测试收件人列表2',
        'IntervalMinutes': 10,
        'EmailCount': 200,
      };

      final config = ReceiverListConfig.fromMap(map);

      expect(config.receiverId, 'receiver-test-002');
      expect(config.receiverName, '测试收件人列表2');
      expect(config.intervalMinutes, 10);
      expect(config.emailCount, 200);
    });

    test('should convert ReceiverListConfig to Map', () {
      final config = ReceiverListConfig(
        receiverId: 'receiver-test-003',
        receiverName: '测试收件人列表3',
        intervalMinutes: 15,
        emailCount: 300,
      );

      final map = config.toMap();

      expect(map['ReceiverId'], 'receiver-test-003');
      expect(map['ReceiverName'], '测试收件人列表3');
      expect(map['IntervalMinutes'], 15);
      expect(map['EmailCount'], 300);
    });

    test('should handle default values in fromMap', () {
      final map = {
        'ReceiverId': 'receiver-test-004',
        'ReceiverName': '测试收件人列表4',
      };

      final config = ReceiverListConfig.fromMap(map);

      expect(config.receiverId, 'receiver-test-004');
      expect(config.receiverName, '测试收件人列表4');
      expect(config.intervalMinutes, 0);
      expect(config.emailCount, 0);
    });
  });
} 