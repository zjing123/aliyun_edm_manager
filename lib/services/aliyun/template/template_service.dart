import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/template/template_model.dart';
import 'package:aliyun_edm_manager/models/template/template_request_response.dart';
import 'package:aliyun_edm_manager/constants/template_constants.dart';
import 'package:aliyun_edm_manager/constants/pagination_constants.dart';

/// 模板管理服务
/// 提供邮件模板的查询和管理功能
class TemplateService extends BaseAliyunService {
  
  /// 查询邮件模板
  Future<QueryTemplateByParamResponse> queryTemplateByParam({
    String? templateName,
    String? templateStatus,
    String? templateType,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    // 参数验证
    validatePagination(pageNo, pageSize, maxPageSize: PaginationConstants.templateMaxPageSize);

    final params = <String, String>{
      'PageNo': pageNo.toString(),
      'PageSize': pageSize.toString(),
    };
    
    // 添加可选参数
    if (templateName != null && templateName.isNotEmpty) {
      params['TemplateName'] = templateName;
    }
    if (templateStatus != null && templateStatus.isNotEmpty) {
      params['TemplateStatus'] = templateStatus;
    }
    if (templateType != null && templateType.isNotEmpty) {
      params['TemplateType'] = templateType;
    }

    final response = await get("QueryTemplateByParam", params);
    print('QueryTemplateByParam API 返回数据: ${response.data}');
    return QueryTemplateByParamResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 使用新的Request类查询模板
  Future<QueryTemplateByParamResponse> queryTemplateByParamWithRequest(QueryTemplateByParamRequest request) async {
    final params = request.toJson().map((key, value) => MapEntry(key, value.toString()));
    final response = await get("QueryTemplateByParam", params);
    print('QueryTemplateByParam API 返回数据: ${response.data}');
    return QueryTemplateByParamResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 创建模板
  Future<CreateTemplateResponse> createTemplate(CreateTemplateRequest request) async {
    final params = request.toJson().map((key, value) => MapEntry(key, value.toString()));
    final response = await post("CreateTemplate", params);
    print('CreateTemplate API 返回数据: ${response.data}');
    return CreateTemplateResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 修改模板
  Future<ModifyTemplateResponse> modifyTemplate(ModifyTemplateRequest request) async {
    final params = request.toJson().map((key, value) => MapEntry(key, value.toString()));
    final response = await post("ModifyTemplate", params);
    print('ModifyTemplate API 返回数据: ${response.data}');
    return ModifyTemplateResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 删除模板
  Future<DeleteTemplateResponse> deleteTemplate(DeleteTemplateRequest request) async {
    final params = request.toJson().map((key, value) => MapEntry(key, value.toString()));
    final response = await post("DeleteTemplate", params);
    print('DeleteTemplate API 返回数据: ${response.data}');
    return DeleteTemplateResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取模板详情
  Future<DescTemplateResponse> descTemplate(DescTemplateRequest request) async {
    final params = request.toJson().map((key, value) => MapEntry(key, value.toString()));
    final response = await get("DescTemplate", params);
    print('DescTemplate API 返回数据: ${response.data}');
    return DescTemplateResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取所有模板（包括审核中、审核通过、审核未通过）
  Future<List<TemplateModel>> getAllTemplates({
    String? templateName,
    String? templateStatus = TemplateConstants.STATUS_APPROVED, // 默认只获取审核通过的模板
    String? templateType,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    try {
      if (pageSize > PaginationConstants.templateMaxPageSize) {
        pageSize = PaginationConstants.templateMaxPageSize;
      }

      final response = await queryTemplateByParam(
        templateName: templateName,
        templateStatus: templateStatus,
        templateType: templateType,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      return response.templates;
    } catch (e) {
      print('获取可用模板失败: $e');
      return [];
    }
  }

  /// 获取可用的邮件模板
  Future<List<TemplateModel>> getAvailableTemplates({
    String? templateName,
    String? templateType,
    int pageNo = 1,
    int pageSize = PaginationConstants.templateMaxPageSize,
  }) async {
    return await getAllTemplates(
      templateName: templateName,
      templateStatus: TemplateConstants.STATUS_APPROVED, // 过滤审核通过的模板
      templateType: templateType,
      pageNo: pageNo,
      pageSize: pageSize,
    );
  }
} 