import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/models/template/template_model.dart';
import 'package:aliyun_edm_manager/models/template/template_request_response.dart';

void main() {
  group('TemplateModel Tests', () {
    test('should create TemplateModel from JSON', () {
      final json = {
        'TemplateId': '12345',
        'TemplateName': '测试模板',
        'TemplateNickName': '测试发送人',
        'TemplateSubject': '测试邮件标题',
        'TemplateType': '1',
        'TemplateStatus': '1',
        'CreateTime': '2023-01-01 12:00:00',
        'UtcCreateTime': '2023-01-01T04:00:00Z',
        'Remark': '测试备注',
      };

      final template = TemplateModel.fromJson(json);

      expect(template.templateId, '12345');
      expect(template.templateName, '测试模板');
      expect(template.templateNickName, '测试发送人');
      expect(template.templateSubject, '测试邮件标题');
      expect(template.templateType, '1');
      expect(template.templateStatus, '1');
      expect(template.createTime, '2023-01-01 12:00:00');
      expect(template.utcCreateTime, '2023-01-01T04:00:00Z');
      expect(template.remark, '测试备注');
    });

    test('should convert TemplateModel to JSON', () {
      final template = TemplateModel(
        templateId: '12345',
        templateName: '测试模板',
        templateNickName: '测试发送人',
        templateSubject: '测试邮件标题',
        templateType: '1',
        templateStatus: '1',
        createTime: '2023-01-01 12:00:00',
        utcCreateTime: '2023-01-01T04:00:00Z',
        remark: '测试备注',
      );

      final json = template.toJson();

      expect(json['TemplateId'], '12345');
      expect(json['TemplateName'], '测试模板');
      expect(json['TemplateNickName'], '测试发送人');
      expect(json['TemplateSubject'], '测试邮件标题');
      expect(json['TemplateType'], '1');
      expect(json['TemplateStatus'], '1');
      expect(json['CreateTime'], '2023-01-01 12:00:00');
      expect(json['UtcCreateTime'], '2023-01-01T04:00:00Z');
      expect(json['Remark'], '测试备注');
    });

    test('should get status description', () {
      final template = TemplateModel(
        templateId: '12345',
        templateName: '测试模板',
        templateNickName: '测试发送人',
        templateSubject: '测试邮件标题',
        templateType: '1',
        templateStatus: '0', // 审核通过
        createTime: '2023-01-01 12:00:00',
        utcCreateTime: '2023-01-01T04:00:00Z',
      );

      expect(template.statusDescription, '审核通过');
    });

    test('should get type description', () {
      final template = TemplateModel(
        templateId: '12345',
        templateName: '测试模板',
        templateNickName: '测试发送人',
        templateSubject: '测试邮件标题',
        templateType: '1', // 批量邮件
        templateStatus: '0',
        createTime: '2023-01-01 12:00:00',
        utcCreateTime: '2023-01-01T04:00:00Z',
      );

      expect(template.typeDescription, '批量邮件');
    });

    test('should check if template is available', () {
      final approvedTemplate = TemplateModel(
        templateId: '12345',
        templateName: '测试模板',
        templateNickName: '测试发送人',
        templateSubject: '测试邮件标题',
        templateType: '1',
        templateStatus: '0', // 审核通过
        createTime: '2023-01-01 12:00:00',
        utcCreateTime: '2023-01-01T04:00:00Z',
      );

      final pendingTemplate = TemplateModel(
        templateId: '12346',
        templateName: '测试模板2',
        templateNickName: '测试发送人',
        templateSubject: '测试邮件标题',
        templateType: '1',
        templateStatus: '2', // 待审核
        createTime: '2023-01-01 12:00:00',
        utcCreateTime: '2023-01-01T04:00:00Z',
      );

      expect(approvedTemplate.isAvailable, true);
      expect(pendingTemplate.isAvailable, false);
    });
  });

  group('QueryTemplateByParamRequest Tests', () {
    test('should create request with required parameters', () {
      final request = QueryTemplateByParamRequest(
        pageNo: 1,
        pageSize: 10,
      );

      final json = request.toJson();

      expect(json['PageNo'], 1);
      expect(json['PageSize'], 10);
      expect(json.containsKey('KeyWord'), false);
      expect(json.containsKey('Status'), false);
      expect(json.containsKey('FromType'), false);
    });

    test('should create request with all parameters', () {
      final request = QueryTemplateByParamRequest(
        pageNo: 2,
        pageSize: 20,
        keyWord: '测试',
        status: 1,
        fromType: 0,
      );

      final json = request.toJson();

      expect(json['PageNo'], 2);
      expect(json['PageSize'], 20);
      expect(json['KeyWord'], '测试');
      expect(json['Status'], 1);
      expect(json['FromType'], 0);
    });
  });

  group('QueryTemplateByParamResponse Tests', () {
    test('should create response from JSON', () {
      final json = {
        'RequestId': 'test-request-id',
        'data': {
          'totalCount': 100,
          'pageNo': 1,
          'pageSize': 10,
          'template': [
            {
              'TemplateId': '12345',
              'TemplateName': '测试模板',
              'TemplateNickName': '测试发送人',
              'TemplateSubject': '测试邮件标题',
              'TemplateType': '1',
              'TemplateStatus': '1',
              'CreateTime': '2023-01-01 12:00:00',
              'UtcCreateTime': '2023-01-01T04:00:00Z',
            }
          ],
        },
      };

      final response = QueryTemplateByParamResponse.fromJson(json);

      expect(response.requestId, 'test-request-id');
      expect(response.totalCount, 100);
      expect(response.pageNo, 1);
      expect(response.pageSize, 10);
      expect(response.templates.length, 1);
      expect(response.templates.first.templateName, '测试模板');
    });

    test('should calculate total pages correctly', () {
      final response = QueryTemplateByParamResponse(
        templates: [],
        totalCount: 100,
        pageNo: 1,
        pageSize: 10,
        requestId: 'test',
      );

      expect(response.totalPages, 10);
    });

    test('should handle empty response', () {
      final json = {
        'RequestId': 'test-request-id',
        'data': {
          'totalCount': 0,
          'pageNo': 1,
          'pageSize': 10,
          'template': [],
        },
      };

      final response = QueryTemplateByParamResponse.fromJson(json);

      expect(response.templates.length, 0);
      expect(response.totalCount, 0);
      expect(response.totalPages, 0);
    });
  });

  group('CreateTemplateRequest Tests', () {
    test('should create request with required parameters', () {
      final request = CreateTemplateRequest(
        templateType: 1,
        templateName: '测试模板',
      );

      final json = request.toJson();

      expect(json['TemplateType'], 1);
      expect(json['TemplateName'], '测试模板');
      expect(json.containsKey('TemplateSubject'), false);
      expect(json.containsKey('TemplateNickName'), false);
      expect(json.containsKey('TemplateText'), false);
      expect(json.containsKey('FromType'), false);
    });

    test('should create request with all parameters', () {
      final request = CreateTemplateRequest(
        templateType: 1,
        templateName: '测试模板',
        templateSubject: '测试邮件标题',
        templateNickName: '测试发送人',
        templateText: '<p>测试内容</p>',
        fromType: 0,
      );

      final json = request.toJson();

      expect(json['TemplateType'], 1);
      expect(json['TemplateName'], '测试模板');
      expect(json['TemplateSubject'], '测试邮件标题');
      expect(json['TemplateNickName'], '测试发送人');
      expect(json['TemplateText'], '<p>测试内容</p>');
      expect(json['FromType'], 0);
    });
  });

  group('CreateTemplateResponse Tests', () {
    test('should create response from JSON', () {
      final json = {
        'TemplateId': 12345,
        'RequestId': 'test-request-id',
      };

      final response = CreateTemplateResponse.fromJson(json);

      expect(response.templateId, 12345);
      expect(response.requestId, 'test-request-id');
    });
  });

  group('ModifyTemplateRequest Tests', () {
    test('should create request with required parameters', () {
      final request = ModifyTemplateRequest(
        templateId: 12345,
        templateName: '测试模板',
      );

      final json = request.toJson();

      expect(json['TemplateId'], 12345);
      expect(json['TemplateName'], '测试模板');
      expect(json.containsKey('TemplateSubject'), false);
      expect(json.containsKey('TemplateNickName'), false);
      expect(json.containsKey('TemplateText'), false);
      expect(json.containsKey('FromType'), false);
    });

    test('should create request with all parameters', () {
      final request = ModifyTemplateRequest(
        templateId: 12345,
        templateName: '测试模板',
        templateSubject: '测试邮件标题',
        templateNickName: '测试发送人',
        templateText: '<p>测试内容</p>',
        fromType: 0,
      );

      final json = request.toJson();

      expect(json['TemplateId'], 12345);
      expect(json['TemplateName'], '测试模板');
      expect(json['TemplateSubject'], '测试邮件标题');
      expect(json['TemplateNickName'], '测试发送人');
      expect(json['TemplateText'], '<p>测试内容</p>');
      expect(json['FromType'], 0);
    });
  });

  group('DeleteTemplateRequest Tests', () {
    test('should create request with required parameters', () {
      final request = DeleteTemplateRequest(
        templateId: 12345,
      );

      final json = request.toJson();

      expect(json['TemplateId'], 12345);
      expect(json.containsKey('FromType'), false);
    });

    test('should create request with optional parameters', () {
      final request = DeleteTemplateRequest(
        templateId: 12345,
        fromType: 0,
      );

      final json = request.toJson();

      expect(json['TemplateId'], 12345);
      expect(json['FromType'], 0);
    });
  });

  group('DescTemplateRequest Tests', () {
    test('should create request with required parameters', () {
      final request = DescTemplateRequest(
        templateId: 12345,
      );

      final json = request.toJson();

      expect(json['TemplateId'], 12345);
      expect(json.containsKey('FromType'), false);
    });

    test('should create request with optional parameters', () {
      final request = DescTemplateRequest(
        templateId: 12345,
        fromType: 0,
      );

      final json = request.toJson();

      expect(json['TemplateId'], 12345);
      expect(json['FromType'], 0);
    });
  });

  group('DescTemplateResponse Tests', () {
    test('should create response from JSON', () {
      final json = {
        'RequestId': 'test-request-id',
        'CreateTime': '2023-01-01 12:00:00',
        'TemplateSubject': '测试邮件标题',
        'TemplateStatus': '1',
        'TemplateNickName': '测试发送人',
        'TemplateType': '1',
        'TemplateName': '测试模板',
        'TemplateText': '<p>测试内容</p>',
      };

      final response = DescTemplateResponse.fromJson(json);

      expect(response.requestId, 'test-request-id');
      expect(response.createTime, '2023-01-01 12:00:00');
      expect(response.templateSubject, '测试邮件标题');
      expect(response.templateStatus, '1');
      expect(response.templateNickName, '测试发送人');
      expect(response.templateType, '1');
      expect(response.templateName, '测试模板');
      expect(response.templateText, '<p>测试内容</p>');
    });
  });
} 