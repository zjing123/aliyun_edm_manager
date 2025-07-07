import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/models/email_tag_model.dart';

void main() {
  group('邮件标签模型测试', () {
    test('应该正确解析JSON数据', () {
      final jsonData = {
        'TagId': 'tag_001',
        'TagName': '推广邮件',
        'Description': '用于推广活动的邮件标签',
        'CreateTime': '2024-01-01T00:00:00Z',
        'TemplateCount': 5,
      };

      final tag = EmailTagModel.fromJson(jsonData);

      expect(tag.tagId, 'tag_001');
      expect(tag.tagName, '推广邮件');
      expect(tag.description, '用于推广活动的邮件标签');
      expect(tag.createTime, '2024-01-01T00:00:00Z');
      expect(tag.templateCount, 5);
    });

    test('应该处理缺失的可选字段', () {
      final jsonData = {
        'TagId': 'tag_002',
        'TagName': '通知邮件',
        'CreateTime': '2024-01-02T00:00:00Z',
      };

      final tag = EmailTagModel.fromJson(jsonData);

      expect(tag.tagId, 'tag_002');
      expect(tag.tagName, '通知邮件');
      expect(tag.description, null);
      expect(tag.createTime, '2024-01-02T00:00:00Z');
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
        'RequestId': 'request_001',
        'Data': {
          'TotalCount': 2,
          'PageNo': 1,
          'PageSize': 10,
          'tag': [
            {
              'TagId': 'tag_001',
              'TagName': '推广邮件',
              'Description': '推广活动邮件',
              'CreateTime': '2024-01-01T00:00:00Z',
              'TemplateCount': 5,
            },
            {
              'TagId': 'tag_002',
              'TagName': '通知邮件',
              'Description': '系统通知邮件',
              'CreateTime': '2024-01-02T00:00:00Z',
              'TemplateCount': 3,
            },
          ],
        },
      };

      final response = QueryTagByParamResponse.fromJson(jsonData);

      expect(response.requestId, 'request_001');
      expect(response.totalCount, 2);
      expect(response.pageNo, 1);
      expect(response.pageSize, 10);
      expect(response.tags.length, 2);
      expect(response.tags[0].tagName, '推广邮件');
      expect(response.tags[1].tagName, '通知邮件');
    });

    test('应该处理空标签列表', () {
      final jsonData = {
        'RequestId': 'request_002',
        'Data': {
          'TotalCount': 0,
          'PageNo': 1,
          'PageSize': 10,
          'tag': [],
        },
      };

      final response = QueryTagByParamResponse.fromJson(jsonData);

      expect(response.requestId, 'request_002');
      expect(response.totalCount, 0);
      expect(response.tags.length, 0);
    });
  });
} 