THIS SHOULD BE A LINTER ERRORimport 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/tag/email_tag_model.dart';

/// 邮件标签管理服务
/// 提供邮件标签的查询和管理功能
class EmailTagService extends BaseAliyunService {
  
  /// 查询邮件标签
  Future<QueryTagByParamResponse> queryTagByParam({
    String? keyWord,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    // 参数验证
    validatePagination(pageNo, pageSize);

    final params = <String, String>{
      'PageNo': pageNo.toString(),
      'PageSize': pageSize.toString(),
    };
    
    // 可选参数
    if (keyWord != null && keyWord.isNotEmpty) {
      params['KeyWord'] = keyWord;
    }

    final response = await get("QueryTagByParam", params);
    return QueryTagByParamResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取所有邮件标签
  Future<List<EmailTagModel>> getAllEmailTags({
    String? keyWord,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await queryTagByParam(
        keyWord: keyWord,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      return response.tags;
    } catch (e) {
      print('获取邮件标签失败: $e');
      return [];
    }
  }

  /// 获取可用的邮件标签
  Future<List<EmailTagModel>> getAvailableEmailTags({
    String? keyWord,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    try {
      final allTags = await getAllEmailTags(
        keyWord: keyWord,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      // 邮件标签没有状态字段，直接返回所有标签
      return allTags;
    } catch (e) {
      print('获取可用邮件标签失败: $e');
      return [];
    }
  }
} 