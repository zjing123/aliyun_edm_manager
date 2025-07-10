import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/tag/email_tag_model.dart';
import 'package:aliyun_edm_manager/constants/pagination_constants.dart';

/// 邮件标签管理服务
/// 提供邮件标签的查询和管理功能
class EmailTagService extends BaseAliyunService {
  
  /// 查询邮件标签
  Future<QueryTagByParamResponse> queryTagByParam({
    String? keyWord,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    return await withConfigCheck(() async {
      // 参数验证
      validatePagination(pageNo, pageSize, maxPageSize: PaginationConstants.emailTagMaxPageSize);

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
    });
  }

  /// 获取所有邮件标签
  Future<List<EmailTagModel>> getAllEmailTags({
    String? keyWord,
    int pageNo = 1,
    int pageSize = PaginationConstants.emailTagMaxPageSize,
  }) async {
    if (pageSize > PaginationConstants.emailTagMaxPageSize) {
      pageSize = PaginationConstants.emailTagMaxPageSize;
    }

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
    int pageSize = PaginationConstants.emailTagMaxPageSize,
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

  /// 创建标签
  Future<String> createTag({
    required String tagName,
    String? tagDescription,
  }) async {
    return await withConfigCheck(() async {
      // 参数验证
      validateStringLength(tagName, '标签名称', 50);
      if (tagDescription != null) {
        validateStringLength(tagDescription, '标签描述', 200);
      }

      final params = <String, String>{
        'TagName': tagName,
      };
      
      // 可选参数
      if (tagDescription != null && tagDescription.isNotEmpty) {
        params['TagDescription'] = tagDescription;
      }

      final response = await post("CreateTag", params);
      final responseData = response.data as Map<String, dynamic>;
      
      // 打印API返回数据用于调试
      print('CreateTag API 返回数据: $responseData');
      
      // 返回新创建的标签ID
      return responseData['TagId']?.toString() ?? '';
    });
  }

  /// 修改标签
  Future<bool> modifyTag({
    required String tagId,
    String? tagName,
    String? tagDescription,
  }) async {
    return await withConfigCheck(() async {
      // 参数验证
      if (tagName != null) {
        validateStringLength(tagName, '标签名称', 50);
      }
      if (tagDescription != null) {
        validateStringLength(tagDescription, '标签描述', 200);
      }

      final params = <String, String>{
        'TagId': tagId,
      };
      
      // 可选参数
      if (tagName != null && tagName.isNotEmpty) {
        params['TagName'] = tagName;
      }
      if (tagDescription != null && tagDescription.isNotEmpty) {
        params['TagDescription'] = tagDescription;
      }

      try {
        final response = await post("ModifyTag", params);
        final responseData = response.data as Map<String, dynamic>;
        
        // 打印API返回数据用于调试
        print('ModifyTag API 返回数据: $responseData');
        
        // 检查是否有RequestId，表示请求成功
        return responseData['RequestId'] != null;
      } catch (e) {
        print('修改标签失败: $e');
        return false;
      }
    });
  }

  /// 删除标签
  Future<bool> deleteTag({
    required String tagId,
  }) async {
    return await withConfigCheck(() async {
      final params = <String, String>{
        'TagId': tagId,
      };

      try {
        final response = await post("DeleteTag", params);
        final responseData = response.data as Map<String, dynamic>;
        
        // 打印API返回数据用于调试
        print('DeleteTag API 返回数据: $responseData');
        
        // 检查是否有RequestId，表示请求成功
        return responseData['RequestId'] != null;
      } catch (e) {
        print('删除标签失败: $e');
        return false;
      }
    });
  }

  /// 批量删除标签
  Future<Map<String, bool>> batchDeleteTags({
    required List<String> tagIds,
  }) async {
    final results = <String, bool>{};
    
    print('开始批量删除标签，共 ${tagIds.length} 个标签');
    
    for (int i = 0; i < tagIds.length; i++) {
      final tagId = tagIds[i];
      try {
        print('正在删除第 ${i + 1}/${tagIds.length} 个标签: $tagId');
        final success = await deleteTag(tagId: tagId);
        results[tagId] = success;
        
        // 减少延时，避免卡住
        if (i < tagIds.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        print('删除标签 $tagId 失败: $e');
        results[tagId] = false;
      }
    }
    
    print('批量删除完成，成功: ${results.values.where((success) => success).length}/${tagIds.length}');
    return results;
  }
} 