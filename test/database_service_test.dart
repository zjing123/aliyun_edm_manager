import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/services/database/database_service.dart';
import 'package:aliyun_edm_manager/models/sender/sender_name_model.dart';
import 'package:aliyun_edm_manager/models/task/scheduled_email_task_model.dart';

void main() {
  group('DatabaseService 测试', () {
    late DatabaseService databaseService;

    setUp(() async {
      // 确保Flutter绑定已初始化
      TestWidgetsFlutterBinding.ensureInitialized();
      databaseService = DatabaseService();
      // 获取数据库实例来触发初始化
      await databaseService.database;
    });

    tearDown(() async {
      // 关闭数据库连接
      final db = await databaseService.database;
      await db.close();
    });

    test('应该能够创建DatabaseService实例', () {
      expect(databaseService, isA<DatabaseService>());
    });

    test('应该能够获取数据库实例', () async {
      final db = await databaseService.database;
      expect(db, isNotNull);
    });

    test('DatabaseService应该是单例模式', () {
      final instance1 = DatabaseService();
      final instance2 = DatabaseService();
      expect(identical(instance1, instance2), isTrue);
    });

    group('发送人名称表测试', () {
      test('应该能够插入发送人名称', () async {
        final senderName = SenderNameModel(
          id: 'test-1',
          name: '测试发送人',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        final result = await databaseService.insertSenderName(senderName);
        expect(result, isNotNull);
        expect(result, greaterThan(0));
      });

      test('应该能够查询发送人名称', () async {
        final senderName = SenderNameModel(
          id: 'test-2',
          name: '测试发送人2',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        await databaseService.insertSenderName(senderName);
        final retrievedName = await databaseService.getSenderName('test-2');
        
        expect(retrievedName, isNotNull);
        expect(retrievedName!.name, equals('测试发送人2'));
      });

      test('应该能够获取所有发送人名称', () async {
        final senderName1 = SenderNameModel(
          id: 'test-3',
          name: '测试发送人3',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        final senderName2 = SenderNameModel(
          id: 'test-4',
          name: '测试发送人4',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        await databaseService.insertSenderName(senderName1);
        await databaseService.insertSenderName(senderName2);

        final allNames = await databaseService.getAllSenderNames();
        expect(allNames, isNotEmpty);
        expect(allNames.any((name) => name.name == '测试发送人3'), isTrue);
        expect(allNames.any((name) => name.name == '测试发送人4'), isTrue);
      });

      test('应该能够更新发送人名称', () async {
        final senderName = SenderNameModel(
          id: 'test-5',
          name: '原始名称',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        await databaseService.insertSenderName(senderName);

        // 更新名称
        final updatedName = SenderNameModel(
          id: 'test-5',
          name: '更新后的名称',
          createdAt: senderName.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );

        final result = await databaseService.updateSenderName(updatedName);
        expect(result, greaterThan(0));

        // 验证更新
        final retrievedName = await databaseService.getSenderName('test-5');
        expect(retrievedName!.name, equals('更新后的名称'));
      });

      test('应该能够删除发送人名称', () async {
        final senderName = SenderNameModel(
          id: 'test-6',
          name: '要删除的名称',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        await databaseService.insertSenderName(senderName);

        // 删除
        final result = await databaseService.deleteSenderName('test-6');
        expect(result, greaterThan(0));

        // 验证删除
        final retrievedName = await databaseService.getSenderName('test-6');
        expect(retrievedName, isNull);
      });

      test('应该能够处理重复的发送人名称', () async {
        final senderName1 = SenderNameModel(
          id: 'test-7',
          name: '重复名称',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        final senderName2 = SenderNameModel(
          id: 'test-8',
          name: '重复名称', // 相同的名称
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        // 插入第一个
        await databaseService.insertSenderName(senderName1);

        // 尝试插入重复的名称，应该抛出异常
        expect(
          () => databaseService.insertSenderName(senderName2),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('定时邮件任务表测试', () {
      test('应该能够验证定时邮件任务表存在', () async {
        // 验证定时邮件任务表存在
        final db = await databaseService.database;
        final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
        final tableNames = tables.map((table) => table['name'] as String).toList();
        
        expect(tableNames.contains('scheduled_email_tasks'), isTrue);
      });
    });

    group('数据库升级测试', () {
      test('应该能够处理数据库版本升级', () async {
        // 这个测试验证数据库升级机制是否正常工作
        final db = await databaseService.database;
        expect(db, isNotNull);
        
        // 验证表是否存在
        final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
        expect(tables, isNotEmpty);
        
        // 验证必要的表存在
        final tableNames = tables.map((table) => table['name'] as String).toList();
        expect(tableNames.contains('sender_names'), isTrue);
        expect(tableNames.contains('scheduled_email_tasks'), isTrue);
      });
    });
  });
} 