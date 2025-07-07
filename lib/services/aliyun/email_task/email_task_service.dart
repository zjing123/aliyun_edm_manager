import 'base_aliyun_service.dart';
import '../../models/task/mail_task_model.dart';

/// 邮件任务管理服务
/// 提供邮件任务的查询和管理功能
class EmailTaskService extends BaseAliyunService {
  
  /// 查询邮件任务
  Future<MailTaskResponse> queryTaskByParam({
    String? keyWord,
    String? status,
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
    if (status != null && status.isNotEmpty) {
      params['Status'] = status;
    }

    final response = await get("QueryTaskByParam", params);
    return MailTaskResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取所有邮件任务
  Future<List<MailTaskModel>> getAllMailTasks({
    String? keyWord,
    String? status,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await queryTaskByParam(
        keyWord: keyWord,
        status: status,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      return response.tasks;
    } catch (e) {
      print('获取邮件任务失败: $e');
      return [];
    }
  }

  /// 获取特定状态的邮件任务
  Future<List<MailTaskModel>> getMailTasksByStatus({
    required String status,
    String? keyWord,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    return await getAllMailTasks(
      keyWord: keyWord,
      status: status,
      pageNo: pageNo,
      pageSize: pageSize,
    );
  }
} 