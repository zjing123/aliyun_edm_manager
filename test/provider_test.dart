import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:aliyun_edm_manager/providers/receiver_list_provider.dart';
import 'package:aliyun_edm_manager/models/receiver_list_model.dart';

void main() {
  group('ReceiverListProvider 测试', () {
    late ReceiverListProvider provider;

    setUp(() {
      provider = ReceiverListProvider();
    });

    test('初始状态测试', () {
      expect(provider.receivers, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.lastUpdated, isNull);
      expect(provider.receiverNames, isEmpty);
    });

    test('名称重复检查测试', () {
      // 添加一些测试数据
      final receiver1 = ReceiverListModel(
        receiverId: '1',
        receiversName: '测试列表1',
        receiversAlias: 'test1@example.com',
        count: 0,
        createTime: '2024-01-01',
      );
      
      final receiver2 = ReceiverListModel(
        receiverId: '2',
        receiversName: '测试列表2',
        receiversAlias: 'test2@example.com',
        count: 0,
        createTime: '2024-01-01',
      );

      // 手动添加数据（模拟从API获取）
      provider.receivers.add(receiver1);
      provider.receivers.add(receiver2);
      provider.notifyListeners();

      // 测试重复检查
      expect(provider.isNameDuplicate('测试列表1'), isTrue);
      expect(provider.isNameDuplicate('测试列表2'), isTrue);
      expect(provider.isNameDuplicate('新列表'), isFalse);
      
      // 测试大小写不敏感
      expect(provider.isNameDuplicate('测试列表1'), isTrue);
      expect(provider.isNameDuplicate(' 测试列表1 '), isTrue);
    });

    test('receiverNames getter 测试', () {
      final receiver1 = ReceiverListModel(
        receiverId: '1',
        receiversName: 'Test List',
        receiversAlias: 'test@example.com',
        count: 0,
        createTime: '2024-01-01',
      );
      
      final receiver2 = ReceiverListModel(
        receiverId: '2',
        receiversName: '  Another List  ',
        receiversAlias: 'another@example.com',
        count: 0,
        createTime: '2024-01-01',
      );

      provider.receivers.add(receiver1);
      provider.receivers.add(receiver2);
      provider.notifyListeners();

      final names = provider.receiverNames;
      expect(names.length, equals(2));
      expect(names.contains('test list'), isTrue);
      expect(names.contains('another list'), isTrue);
    });

    test('查找方法测试', () {
      final receiver = ReceiverListModel(
        receiverId: '123',
        receiversName: '测试列表',
        receiversAlias: 'test@example.com',
        count: 10,
        createTime: '2024-01-01',
      );

      provider.receivers.add(receiver);
      provider.notifyListeners();

      // 测试根据ID查找
      final foundById = provider.findReceiverById('123');
      expect(foundById, isNotNull);
      expect(foundById!.receiversName, equals('测试列表'));

      // 测试根据名称查找
      final foundByName = provider.findReceiverByName('测试列表');
      expect(foundByName, isNotNull);
      expect(foundByName!.receiverId, equals('123'));

      // 测试查找不存在的项目
      expect(provider.findReceiverById('999'), isNull);
      expect(provider.findReceiverByName('不存在的列表'), isNull);
    });

    test('清空缓存测试', () {
      // 添加一些数据
      final receiver = ReceiverListModel(
        receiverId: '1',
        receiversName: '测试列表',
        receiversAlias: 'test@example.com',
        count: 0,
        createTime: '2024-01-01',
      );
      
      provider.receivers.add(receiver);
      provider.notifyListeners();
      
      expect(provider.receivers, isNotEmpty);
      
      // 清空缓存
      provider.clearCache();
      
      expect(provider.receivers, isEmpty);
      expect(provider.error, isNull);
      expect(provider.lastUpdated, isNull);
    });
  });
} 