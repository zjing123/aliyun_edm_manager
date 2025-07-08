import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/template/template_model.dart';
import 'package:aliyun_edm_manager/constants/template_constants.dart';

/// 模板管理服务
/// 提供邮件模板的查询和管理功能
class TemplateService extends BaseAliyunService {
  
  /// 查询邮件模板
  Future<QueryTemplateResponse> queryTemplateByParam({
    String? templateName,
    String? templateStatus,
    String? templateType,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    // 参数验证
    validatePagination(pageNo, pageSize);

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
    return QueryTemplateResponse.fromJson(response.data as Map<String, dynamic>);
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
      if (pageSize > 50) {
        pageSize = 50;
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
    int pageSize = 50,
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