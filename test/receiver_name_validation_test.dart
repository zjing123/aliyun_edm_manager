import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/utils/dialog_util.dart';

void main() {
  group('收件人列表名称重复检查测试', () {
    test('应该检测到重复的名称', () {
      // 模拟现有的收件人列表
      final existingReceivers = [
        {'ReceiversName': '测试列表1'},
        {'ReceiversName': '测试列表2'},
        {'ReceiversName': '重复名称'},
      ];
      
      final existingNames = existingReceivers
          .map((r) => (r['ReceiversName'] as String?)?.toLowerCase().trim())
          .where((name) => name != null)
          .toSet();
      
      // 测试重复名称
      expect(existingNames.contains('重复名称'), isTrue);
      expect(existingNames.contains('重复名称'.toLowerCase().trim()), isTrue);
      
      // 测试不重复的名称
      expect(existingNames.contains('新列表名称'), isFalse);
      expect(existingNames.contains('测试列表3'), isFalse);
    });
    
    test('应该忽略大小写和空格', () {
      final existingReceivers = [
        {'ReceiversName': 'Test List'},
        {'ReceiversName': 'test list'},
        {'ReceiversName': '  Test List  '},
      ];
      
      final existingNames = existingReceivers
          .map((r) => (r['ReceiversName'] as String?)?.toLowerCase().trim())
          .where((name) => name != null)
          .toSet();
      
      // 所有变体都应该被认为是重复的
      expect(existingNames.contains('test list'), isTrue);
      expect(existingNames.contains('Test List'.toLowerCase().trim()), isTrue);
      expect(existingNames.contains('  test list  '.toLowerCase().trim()), isTrue);
    });
    
    test('应该处理空值和无效数据', () {
      final existingReceivers = [
        {'ReceiversName': '有效名称'},
        {'ReceiversName': null},
        {'ReceiversName': ''},
        {'ReceiversName': '   '},
        {'ReceiversName': '另一个有效名称'},
      ];
      
      final existingNames = existingReceivers
          .map((r) => (r['ReceiversName'] as String?)?.toLowerCase().trim())
          .where((name) => name != null && name.isNotEmpty)
          .toSet();
      
      // 只应该包含有效的名称
      expect(existingNames.length, equals(2));
      expect(existingNames.contains('有效名称'), isTrue);
      expect(existingNames.contains('另一个有效名称'), isTrue);
      expect(existingNames.contains(''), isFalse);
      expect(existingNames.contains(null), isFalse);
    });
  });
} 