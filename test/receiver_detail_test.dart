import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_detail.dart';
import 'dart:convert';

void main() {
  group('ReceiverDetailParams JSON格式测试', () {
    test('单个收件人详情JSON格式应该正确', () {
      final params = ReceiverDetailParams.withFields(
        email: 'test@example.com',
        userName: '张三',
        nickName: '小张',
        gender: '男',
        birthday: '1990-01-01',
        mobile: '13800138000',
      );
      
      final json = params.toDetailJson();
      print('单个收件人JSON: $json');
      
      // 验证JSON格式是否正确
      expect(() => jsonDecode(json), returnsNormally);
      
      final decoded = jsonDecode(json) as List;
      expect(decoded.length, 1);
      
      final detail = decoded[0] as Map<String, dynamic>;
      expect(detail['e'], 'test@example.com');
      expect(detail['u'], '张三');
      expect(detail['n'], '小张');
      expect(detail['g'], '男');
      expect(detail['b'], '1990-01-01');
      expect(detail['m'], '13800138000');
    });

    test('批量收件人详情JSON格式应该正确', () {
      final paramsList = [
        ReceiverDetailParams.withFields(
          email: 'test1@example.com',
          userName: '张三',
          nickName: '小张',
        ),
        ReceiverDetailParams.withFields(
          email: 'test2@example.com',
          userName: '李四',
          nickName: '小李',
        ),
      ];
      
      final json = ReceiverDetailParams.toBatchDetailJson(paramsList);
      print('批量收件人JSON: $json');
      
      // 验证JSON格式是否正确
      expect(() => jsonDecode(json), returnsNormally);
      
      final decoded = jsonDecode(json) as List;
      expect(decoded.length, 2);
      
      final detail1 = decoded[0] as Map<String, dynamic>;
      expect(detail1['e'], 'test1@example.com');
      expect(detail1['u'], '张三');
      expect(detail1['n'], '小张');
      
      final detail2 = decoded[1] as Map<String, dynamic>;
      expect(detail2['e'], 'test2@example.com');
      expect(detail2['u'], '李四');
      expect(detail2['n'], '小李');
    });

    test('包含特殊字符的字段值应该正确转义', () {
      final params = ReceiverDetailParams.withFields(
        email: 'test@example.com',
        userName: '张三"测试"',
        nickName: '小张,测试',
        gender: '男\n女',
      );
      
      final json = params.toDetailJson();
      print('特殊字符JSON: $json');
      
      // 验证JSON格式是否正确
      expect(() => jsonDecode(json), returnsNormally);
      
      final decoded = jsonDecode(json) as List;
      final detail = decoded[0] as Map<String, dynamic>;
      expect(detail['e'], 'test@example.com');
      expect(detail['u'], '张三"测试"');
      expect(detail['n'], '小张,测试');
      expect(detail['g'], '男\n女');
    });

    test('空字段值应该被忽略', () {
      final params = ReceiverDetailParams.withFields(
        email: 'test@example.com',
        userName: '',
        nickName: null,
        gender: '男',
        birthday: '',
        mobile: null,
      );
      
      final json = params.toDetailJson();
      print('空字段JSON: $json');
      
      // 验证JSON格式是否正确
      expect(() => jsonDecode(json), returnsNormally);
      
      final decoded = jsonDecode(json) as List;
      final detail = decoded[0] as Map<String, dynamic>;
      expect(detail['e'], 'test@example.com');
      expect(detail['g'], '男');
      expect(detail.containsKey('u'), false);
      expect(detail.containsKey('n'), false);
      expect(detail.containsKey('b'), false);
      expect(detail.containsKey('m'), false);
    });

    test('自定义字段应该正确处理', () {
      final params = ReceiverDetailParams(
        email: 'test@example.com',
        fieldValues: {
          'UserName': '张三',
          'CustomField1': '自定义值1',
          'CustomField2': '自定义值2',
        },
      );
      
      final json = params.toDetailJson();
      print('自定义字段JSON: $json');
      
      // 验证JSON格式是否正确
      expect(() => jsonDecode(json), returnsNormally);
      
      final decoded = jsonDecode(json) as List;
      final detail = decoded[0] as Map<String, dynamic>;
      expect(detail['e'], 'test@example.com');
      expect(detail['u'], '张三');
      expect(detail['CustomField1'], '自定义值1');
      expect(detail['CustomField2'], '自定义值2');
    });
  });
} 