import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:aliyun_edm_manager/providers/template/template_provider.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/models/template/template_model.dart';
import 'package:aliyun_edm_manager/models/template/template_request_response.dart';

import 'template_provider_test.mocks.dart';

@GenerateMocks([AliyunServiceManager, GlobalConfigProvider])
void main() {
  group('TemplateProvider Tests', () {
    late TemplateProvider provider;
    late MockAliyunServiceManager mockServiceManager;
    late MockGlobalConfigProvider mockGlobalConfig;

    setUp(() {
      mockServiceManager = MockAliyunServiceManager();
      mockGlobalConfig = MockGlobalConfigProvider();
      provider = TemplateProvider(mockServiceManager);
    });

    test('should initialize with default values', () {
      expect(provider.templates, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.currentPage, 1);
      expect(provider.pageSize, 10);
      expect(provider.totalCount, 0);
      expect(provider.totalPages, 0);
    });

    test('should set search parameters', () {
      provider.setSearchParams(
        keyWord: '测试',
        status: 1,
        fromType: 0,
      );

      expect(provider.keyWord, '测试');
      expect(provider.status, 1);
      expect(provider.fromType, 0);
      expect(provider.currentPage, 1); // 应该重置到第一页
    });

    test('should set global config provider', () {
      provider.setGlobalConfigProvider(mockGlobalConfig);
      
      // 验证服务管理器被初始化
      verify(mockServiceManager.initialize(mockGlobalConfig)).called(1);
    });

    test('should load templates successfully', () async {
      // 模拟服务配置
      when(mockServiceManager.isConfigured()).thenReturn(true);

      // 模拟API响应
      final mockResponse = QueryTemplateByParamResponse(
        templates: [
          TemplateModel(
            templateId: '12345',
            templateName: '测试模板',
            templateNickName: '测试发送人',
            templateSubject: '测试邮件标题',
            templateType: '1',
            templateStatus: '1',
            createTime: '2023-01-01 12:00:00',
            utcCreateTime: '2023-01-01T04:00:00Z',
          ),
        ],
        totalCount: 1,
        pageNo: 1,
        pageSize: 10,
        requestId: 'test-request-id',
      );

      // 模拟模板服务
      final mockTemplateService = MockTemplateService();
      when(mockServiceManager.templateService).thenReturn(mockTemplateService);
      when(mockTemplateService.queryTemplateByParamWithRequest(any))
          .thenAnswer((_) async => mockResponse);

      await provider.loadTemplates();

      expect(provider.templates.length, 1);
      expect(provider.templates.first.templateName, '测试模板');
      expect(provider.totalCount, 1);
      expect(provider.totalPages, 1);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('should handle loading error', () async {
      // 模拟服务配置
      when(mockServiceManager.isConfigured()).thenReturn(true);

      // 模拟API错误
      final mockTemplateService = MockTemplateService();
      when(mockServiceManager.templateService).thenReturn(mockTemplateService);
      when(mockTemplateService.queryTemplateByParamWithRequest(any))
          .thenThrow(Exception('API错误'));

      await provider.loadTemplates();

      expect(provider.templates, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNotNull);
      expect(provider.error!.contains('API错误'), true);
    });

    test('should handle unconfigured service', () async {
      // 模拟服务未配置
      when(mockServiceManager.isConfigured()).thenReturn(false);

      await provider.loadTemplates();

      expect(provider.templates, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNotNull);
      expect(provider.error!.contains('阿里云AccessKey未配置'), true);
    });

    test('should navigate pages correctly', () async {
      // 设置初始状态
      provider.setState(() {
        provider._currentPage = 1;
        provider._totalPages = 3;
      });

      // 模拟服务配置
      when(mockServiceManager.isConfigured()).thenReturn(true);
      final mockTemplateService = MockTemplateService();
      when(mockServiceManager.templateService).thenReturn(mockTemplateService);
      when(mockTemplateService.queryTemplateByParamWithRequest(any))
          .thenAnswer((_) async => QueryTemplateByParamResponse(
                templates: [],
                totalCount: 30,
                pageNo: 1,
                pageSize: 10,
                requestId: 'test',
              ));

      // 测试下一页
      await provider.nextPage();
      expect(provider.currentPage, 2);

      // 测试上一页
      await provider.previousPage();
      expect(provider.currentPage, 1);

      // 测试跳转到指定页
      await provider.goToPage(3);
      expect(provider.currentPage, 3);
    });

    test('should create template successfully', () async {
      // 模拟服务配置
      when(mockServiceManager.isConfigured()).thenReturn(true);

      // 模拟API响应
      final mockResponse = CreateTemplateResponse(
        templateId: 12345,
        requestId: 'test-request-id',
      );

      final mockTemplateService = MockTemplateService();
      when(mockServiceManager.templateService).thenReturn(mockTemplateService);
      when(mockTemplateService.createTemplate(any))
          .thenAnswer((_) async => mockResponse);

      final success = await provider.createTemplate(
        templateType: 1,
        templateName: '测试模板',
        templateSubject: '测试邮件标题',
        templateNickName: '测试发送人',
        templateText: '<p>测试内容</p>',
        fromType: 0,
      );

      expect(success, true);
    });

    test('should modify template successfully', () async {
      // 模拟服务配置
      when(mockServiceManager.isConfigured()).thenReturn(true);

      // 模拟API响应
      final mockResponse = ModifyTemplateResponse(
        requestId: 'test-request-id',
      );

      final mockTemplateService = MockTemplateService();
      when(mockServiceManager.templateService).thenReturn(mockTemplateService);
      when(mockTemplateService.modifyTemplate(any))
          .thenAnswer((_) async => mockResponse);

      final success = await provider.modifyTemplate(
        templateId: 12345,
        templateName: '测试模板',
        templateSubject: '测试邮件标题',
        templateNickName: '测试发送人',
        templateText: '<p>测试内容</p>',
        fromType: 0,
      );

      expect(success, true);
    });

    test('should delete template successfully', () async {
      // 模拟服务配置
      when(mockServiceManager.isConfigured()).thenReturn(true);

      // 模拟API响应
      final mockResponse = DeleteTemplateResponse(
        requestId: 'test-request-id',
      );

      final mockTemplateService = MockTemplateService();
      when(mockServiceManager.templateService).thenReturn(mockTemplateService);
      when(mockTemplateService.deleteTemplate(any))
          .thenAnswer((_) async => mockResponse);

      final success = await provider.deleteTemplate(
        templateId: 12345,
        fromType: 0,
      );

      expect(success, true);
    });

    test('should get template detail successfully', () async {
      // 模拟服务配置
      when(mockServiceManager.isConfigured()).thenReturn(true);

      // 模拟API响应
      final mockResponse = DescTemplateResponse(
        requestId: 'test-request-id',
        createTime: '2023-01-01 12:00:00',
        templateSubject: '测试邮件标题',
        templateStatus: '1',
        templateNickName: '测试发送人',
        templateType: '1',
        templateName: '测试模板',
        templateText: '<p>测试内容</p>',
      );

      final mockTemplateService = MockTemplateService();
      when(mockServiceManager.templateService).thenReturn(mockTemplateService);
      when(mockTemplateService.descTemplate(any))
          .thenAnswer((_) async => mockResponse);

      final result = await provider.getTemplateDetail(
        templateId: 12345,
        fromType: 0,
      );

      expect(result, isNotNull);
      expect(result!.templateName, '测试模板');
      expect(result.templateSubject, '测试邮件标题');
    });

    test('should clear error', () {
      // 设置错误状态
      provider.setState(() {
        provider._error = '测试错误';
      });

      expect(provider.error, '测试错误');

      // 清除错误
      provider.clearError();

      expect(provider.error, isNull);
    });
  });
}

// 模拟TemplateService类
class MockTemplateService extends Mock {
  Future<QueryTemplateByParamResponse> queryTemplateByParamWithRequest(
      QueryTemplateByParamRequest request) async {
    return super.noSuchMethod(
      Invocation.method(#queryTemplateByParamWithRequest, [request]),
      returnValue: Future.value(QueryTemplateByParamResponse(
        templates: [],
        totalCount: 0,
        pageNo: 1,
        pageSize: 10,
        requestId: '',
      )),
    );
  }

  Future<CreateTemplateResponse> createTemplate(
      CreateTemplateRequest request) async {
    return super.noSuchMethod(
      Invocation.method(#createTemplate, [request]),
      returnValue: Future.value(CreateTemplateResponse(
        templateId: 0,
        requestId: '',
      )),
    );
  }

  Future<ModifyTemplateResponse> modifyTemplate(
      ModifyTemplateRequest request) async {
    return super.noSuchMethod(
      Invocation.method(#modifyTemplate, [request]),
      returnValue: Future.value(ModifyTemplateResponse(
        requestId: '',
      )),
    );
  }

  Future<DeleteTemplateResponse> deleteTemplate(
      DeleteTemplateRequest request) async {
    return super.noSuchMethod(
      Invocation.method(#deleteTemplate, [request]),
      returnValue: Future.value(DeleteTemplateResponse(
        requestId: '',
      )),
    );
  }

  Future<DescTemplateResponse> descTemplate(
      DescTemplateRequest request) async {
    return super.noSuchMethod(
      Invocation.method(#descTemplate, [request]),
      returnValue: Future.value(DescTemplateResponse(
        requestId: '',
        createTime: '',
        templateSubject: '',
        templateStatus: '',
        templateNickName: '',
        templateType: '',
        templateName: '',
        templateText: '',
      )),
    );
  }
} 