import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/models/email_tag_model.dart';

void main() {
  group('邮件标签模型测试', () {
    test('应该正确解析JSON数据', () {
      final jsonData = {
        'TagId': '92165',
        'TagName': 'EDM',
        'TagDescription': '阿里云后台EDM邮件发送标签',
        'CreateTime': '2024-01-01T00:00:00Z',
        'TemplateCount': 5,
      };

      final tag = EmailTagModel.fromJson(jsonData);

      expect(tag.tagId, '92165');
      expect(tag.tagName, 'EDM');
      expect(tag.description, '阿里云后台EDM邮件发送标签');
      expect(tag.createTime, '2024-01-01T00:00:00Z');
      expect(tag.templateCount, 5);
    });

    test('应该处理缺失的可选字段', () {
      final jsonData = {
        'TagId': '88481',
        'TagName': 'warmupTest001',
      };

      final tag = EmailTagModel.fromJson(jsonData);

      expect(tag.tagId, '88481');
      expect(tag.tagName, 'warmupTest001');
      expect(tag.description, null);
      expect(tag.createTime, '');
      expect(tag.templateCount, null);
    });

    test('应该正确转换为JSON', () {
      final tag = EmailTagModel(
        tagId: 'tag_003',
        tagName: '测试标签',
        description: '测试描述',
        createTime: '2024-01-03T00:00:00Z',
        templateCount: 10,
      );

      final json = tag.toJson();

      expect(json['TagId'], 'tag_003');
      expect(json['TagName'], '测试标签');
      expect(json['Description'], '测试描述');
      expect(json['CreateTime'], '2024-01-03T00:00:00Z');
      expect(json['TemplateCount'], 10);
    });
  });

  group('QueryTagByParamResponse测试', () {
    test('应该正确解析API响应', () {
      final jsonData = {
        'TotalCount': 2,
        'PageSize': 50,
        'RequestId': '8ABD21E3-2F55-55B7-8296-EDE4017CB9BA',
        'data': {
          'tag': [
            {
              'TagName': 'EDM',
              'TagDescription': '阿里云后台EDM邮件发送标签',
              'TagId': '92165',
            },
            {
              'TagName': 'warmupTest001',
              'TagId': '88481',
            },
          ],
        },
        'PageNumber': 1,
      };

      final response = QueryTagByParamResponse.fromJson(jsonData);

      expect(response.requestId, '8ABD21E3-2F55-55B7-8296-EDE4017CB9BA');
      expect(response.totalCount, 2);
      expect(response.pageNo, 1);
      expect(response.pageSize, 50);
      expect(response.tags.length, 2);
      expect(response.tags[0].tagName, 'EDM');
      expect(response.tags[0].description, '阿里云后台EDM邮件发送标签');
      expect(response.tags[1].tagName, 'warmupTest001');
    });

    test('应该处理空标签列表', () {
      final jsonData = {
        'TotalCount': 0,
        'PageSize': 50,
        'RequestId': 'request_002',
        'data': {
          'tag': [],
        },
        'PageNumber': 1,
      };

      final response = QueryTagByParamResponse.fromJson(jsonData);

      expect(response.requestId, 'request_002');
      expect(response.totalCount, 0);
      expect(response.tags.length, 0);
    });
  });
} 