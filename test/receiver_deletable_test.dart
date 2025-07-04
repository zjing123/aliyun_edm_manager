import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/models/receiver_list_model.dart';

void main() {
  group('ReceiverListModel Deletable Tests', () {
    test('should create deletable receiver list by default', () {
      final receiver = ReceiverListModel(
        receiverId: 'test-id',
        receiversName: 'Test List',
        receiversAlias: 'test-alias',
        count: 0,
        createTime: '2024-01-01',
      );
      
      expect(receiver.isDeletable, isTrue);
    });

    test('should create non-deletable receiver list when specified', () {
      final receiver = ReceiverListModel(
        receiverId: 'test-id',
        receiversName: 'Test List',
        receiversAlias: 'test-alias',
        count: 0,
        createTime: '2024-01-01',
        isDeletable: false,
      );
      
      expect(receiver.isDeletable, isFalse);
    });

    test('should parse isDeletable from map', () {
      final map = {
        'ReceiverId': 'test-id',
        'ReceiversName': 'Test List',
        'ReceiversAlias': 'test-alias',
        'Count': 0,
        'CreateTime': '2024-01-01',
        'IsDeletable': false,
      };
      
      final receiver = ReceiverListModel.fromMap(map);
      expect(receiver.isDeletable, isFalse);
    });

    test('should default to deletable when isDeletable is not in map', () {
      final map = {
        'ReceiverId': 'test-id',
        'ReceiversName': 'Test List',
        'ReceiversAlias': 'test-alias',
        'Count': 0,
        'CreateTime': '2024-01-01',
      };
      
      final receiver = ReceiverListModel.fromMap(map);
      expect(receiver.isDeletable, isTrue);
    });

    test('should include isDeletable in toMap', () {
      final receiver = ReceiverListModel(
        receiverId: 'test-id',
        receiversName: 'Test List',
        receiversAlias: 'test-alias',
        count: 0,
        createTime: '2024-01-01',
        isDeletable: false,
      );
      
      final map = receiver.toMap();
      expect(map['IsDeletable'], isFalse);
    });

    test('should include isDeletable in toString', () {
      final receiver = ReceiverListModel(
        receiverId: 'test-id',
        receiversName: 'Test List',
        receiversAlias: 'test-alias',
        count: 0,
        createTime: '2024-01-01',
        isDeletable: false,
      );
      
      final string = receiver.toString();
      expect(string, contains('isDeletable: false'));
    });
  });
} 