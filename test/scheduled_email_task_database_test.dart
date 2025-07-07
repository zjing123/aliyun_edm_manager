import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/models/scheduled_email_task_model.dart';
import '../lib/services/database_service.dart';

void main() {
  late DatabaseService databaseService;

  setUpAll(() {
    // 初始化SQLite FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseService = DatabaseService();
  });

  tearDown(() async {
    await databaseService.close();
  });

  group('定时发送邮件数据库测试', () {
    test('插入和获取任务', () async {
      final task = ScheduledEmailTaskModel(
        taskId: 'test_task_001',
        taskName: '测试任务',
        templateId: 'template_001',
        templateName: '测试模板',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver_001',
            receiverName: '测试收件人列表',
            intervalMinutes: 5,
            emailCount: 100,
            listId: 'list_001',
            listName: '测试列表',
            receiverCount: 100,
          ),
        ],
        senderAddress: 'test@example.com',
        senderName: '测试发件人',
        senderType: '1',
        tag: 'test',
        enableTracking: true,
        status: 'pending',
        createdAt: DateTime.now(),
        totalEmails: 100,
      );

      // 插入任务
      await databaseService.insertTask(task);

      // 获取任务
      final retrievedTask = await databaseService.getTask(task.taskId);
      
      expect(retrievedTask, isNotNull);
      expect(retrievedTask!.taskId, equals(task.taskId));
      expect(retrievedTask.taskName, equals(task.taskName));
      expect(retrievedTask.status, equals(task.status));
      expect(retrievedTask.receiverLists.length, equals(1));
      expect(retrievedTask.receiverLists.first.receiverId, equals('receiver_001'));
    });

    test('更新任务状态', () async {
      final task = ScheduledEmailTaskModel(
        taskId: 'test_task_002',
        taskName: '测试任务2',
        templateId: 'template_002',
        templateName: '测试模板2',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver_002',
            receiverName: '测试收件人列表2',
            intervalMinutes: 10,
            emailCount: 50,
            listId: 'list_002',
            listName: '测试列表2',
            receiverCount: 50,
          ),
        ],
        senderAddress: 'test2@example.com',
        senderName: '测试发件人2',
        senderType: '1',
        tag: 'test2',
        enableTracking: false,
        status: 'pending',
        createdAt: DateTime.now(),
        totalEmails: 50,
      );

      // 插入任务
      await databaseService.insertTask(task);

      // 更新任务状态
      final updatedTask = task.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
        sentEmails: 50,
      );
      await databaseService.updateTask(updatedTask);

      // 获取更新后的任务
      final retrievedTask = await databaseService.getTask(task.taskId);
      
      expect(retrievedTask, isNotNull);
      expect(retrievedTask!.status, equals('completed'));
      expect(retrievedTask.sentEmails, equals(50));
    });

    test('根据状态获取任务', () async {
      final task1 = ScheduledEmailTaskModel(
        taskId: 'test_task_003',
        taskName: '测试任务3',
        templateId: 'template_003',
        templateName: '测试模板3',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver_003',
            receiverName: '测试收件人列表3',
            intervalMinutes: 15,
            emailCount: 75,
            listId: 'list_003',
            listName: '测试列表3',
            receiverCount: 75,
          ),
        ],
        senderAddress: 'test3@example.com',
        senderName: '测试发件人3',
        senderType: '1',
        tag: 'test3',
        enableTracking: true,
        status: 'pending',
        createdAt: DateTime.now(),
        totalEmails: 75,
      );

      final task2 = task1.copyWith(
        taskId: 'test_task_004',
        taskName: '测试任务4',
        status: 'completed',
      );

      // 插入任务
      await databaseService.insertTask(task1);
      await databaseService.insertTask(task2);

      // 根据状态获取任务
      final pendingTasks = await databaseService.getTasksByStatus('pending');
      final completedTasks = await databaseService.getTasksByStatus('completed');

      expect(pendingTasks.length, greaterThanOrEqualTo(1));
      expect(completedTasks.length, greaterThanOrEqualTo(1));
      expect(pendingTasks.any((t) => t.taskId == 'test_task_003'), isTrue);
      expect(completedTasks.any((t) => t.taskId == 'test_task_004'), isTrue);
    });

    test('搜索任务', () async {
      final task = ScheduledEmailTaskModel(
        taskId: 'test_task_005',
        taskName: '搜索测试任务',
        templateId: 'template_005',
        templateName: '搜索测试模板',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver_005',
            receiverName: '搜索测试收件人列表',
            intervalMinutes: 20,
            emailCount: 25,
            listId: 'list_005',
            listName: '搜索测试列表',
            receiverCount: 25,
          ),
        ],
        senderAddress: 'search@example.com',
        senderName: '搜索测试发件人',
        senderType: '1',
        tag: 'search',
        enableTracking: false,
        status: 'pending',
        createdAt: DateTime.now(),
        totalEmails: 25,
      );

      // 插入任务
      await databaseService.insertTask(task);

      // 搜索任务
      final searchResults = await databaseService.searchTasks('搜索');
      
      expect(searchResults.length, greaterThanOrEqualTo(1));
      expect(searchResults.any((t) => t.taskId == 'test_task_005'), isTrue);
    });

    test('删除任务', () async {
      final task = ScheduledEmailTaskModel(
        taskId: 'test_task_006',
        taskName: '删除测试任务',
        templateId: 'template_006',
        templateName: '删除测试模板',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver_006',
            receiverName: '删除测试收件人列表',
            intervalMinutes: 30,
            emailCount: 200,
            listId: 'list_006',
            listName: '删除测试列表',
            receiverCount: 200,
          ),
        ],
        senderAddress: 'delete@example.com',
        senderName: '删除测试发件人',
        senderType: '1',
        tag: 'delete',
        enableTracking: true,
        status: 'pending',
        createdAt: DateTime.now(),
        totalEmails: 200,
      );

      // 插入任务
      await databaseService.insertTask(task);

      // 确认任务存在
      final existingTask = await databaseService.getTask(task.taskId);
      expect(existingTask, isNotNull);

      // 删除任务
      await databaseService.deleteTask(task.taskId);

      // 确认任务已删除
      final deletedTask = await databaseService.getTask(task.taskId);
      expect(deletedTask, isNull);
    });

    test('获取任务统计信息', () async {
      final task1 = ScheduledEmailTaskModel(
        taskId: 'stats_task_001',
        taskName: '统计测试任务1',
        templateId: 'template_stats_001',
        templateName: '统计测试模板1',
        receiverLists: [
          ReceiverListConfig(
            receiverId: 'receiver_stats_001',
            receiverName: '统计测试收件人列表1',
            intervalMinutes: 5,
            emailCount: 50,
            listId: 'list_stats_001',
            listName: '统计测试列表1',
            receiverCount: 50,
          ),
        ],
        senderAddress: 'stats1@example.com',
        senderName: '统计测试发件人1',
        senderType: '1',
        tag: 'stats1',
        enableTracking: true,
        status: 'pending',
        createdAt: DateTime.now(),
        totalEmails: 50,
      );

      final task2 = task1.copyWith(
        taskId: 'stats_task_002',
        taskName: '统计测试任务2',
        status: 'completed',
      );

      // 插入任务
      await databaseService.insertTask(task1);
      await databaseService.insertTask(task2);

      // 获取统计信息
      final stats = await databaseService.getTaskStatistics();
      
      expect(stats['total'], greaterThanOrEqualTo(2));
      expect(stats['pending'], greaterThanOrEqualTo(1));
      expect(stats['completed'], greaterThanOrEqualTo(1));
    });
  });
} 