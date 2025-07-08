import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/services/database/database_service.dart';
import 'package:aliyun_edm_manager/models/sender/sender_name_model.dart';

void main() {
  group('数据库升级测试', () {
    late DatabaseService databaseService;

    setUp(() async {
      databaseService = DatabaseService();
      // 获取数据库实例来触发初始化
      await databaseService.database;
    });

    tearDown(() async {
      // 关闭数据库连接
      final db = await databaseService.database;
      await db.close();
    });

    test('应该能够创建sender_names表', () async {
      // 测试插入发送人名称
      final senderName = SenderNameModel(
        id: 'test-1',
        name: '测试发送人',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final result = await databaseService.insertSenderName(senderName);
      expect(result, isNotNull);
      expect(result, greaterThan(0));

      // 测试查询发送人名称
      final retrievedName = await databaseService.getSenderName('test-1');
      expect(retrievedName, isNotNull);
      expect(retrievedName!.name, equals('测试发送人'));

      // 测试获取所有发送人名称
      final allNames = await databaseService.getAllSenderNames();
      expect(allNames, isNotEmpty);
      expect(allNames.any((name) => name.name == '测试发送人'), isTrue);

      print('数据库升级测试通过：sender_names表正常工作');
    });

    test('应该能够处理重复的发送人名称', () async {
      final senderName1 = SenderNameModel(
        id: 'test-2',
        name: '重复测试',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final senderName2 = SenderNameModel(
        id: 'test-3',
        name: '重复测试', // 相同的名称
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

      print('数据库升级测试通过：唯一性约束正常工作');
    });
  });
} 