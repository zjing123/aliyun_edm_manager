import 'base_aliyun_service.dart';
import '../../models/task/scheduled_email_task_model.dart';

/// 定时发送邮件服务
/// 提供定时发送邮件任务的创建、查询和管理功能
class ScheduledEmailService extends BaseAliyunService {
  
  /// 创建定时发送邮件任务
  Future<Map<String, dynamic>> createScheduledEmailTask({
    required String receiversName,
    required String templateName,
    required String accountName,
    required String clickTrace,
    required String addressType,
    required String tagName,
    required String replyToAddress,
    required String scheduledTime,
    String? taskName,
  }) async {
    final params = <String, String>{
      'ReceiversName': receiversName,
      'TemplateName': templateName,
      'AccountName': accountName,
      'ClickTrace': clickTrace,
      'AddressType': addressType,
      'TagName': tagName,
      'ReplyToAddress': replyToAddress,
      'ScheduledTime': scheduledTime,
    };
    
    if (taskName != null && taskName.isNotEmpty) {
      params['TaskName'] = taskName;
    }

    final response = await post("CreateScheduledEmailTask", params);
    return response.data as Map<String, dynamic>;
  }

  /// 查询定时发送邮件任务
  Future<Map<String, dynamic>> queryScheduledEmailTaskByParam({
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

    final response = await get("QueryScheduledEmailTaskByParam", params);
    return response.data as Map<String, dynamic>;
  }

  /// 获取所有定时发送邮件任务
  Future<List<ScheduledEmailTaskModel>> getAllScheduledEmailTasks({
    String? keyWord,
    String? status,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await queryScheduledEmailTaskByParam(
        keyWord: keyWord,
        status: status,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      // 解析响应数据
      final data = response['data'];
      final tasks = data != null ? data['task'] : null;
      
      if (tasks != null && tasks is List) {
        return tasks.map((task) => ScheduledEmailTaskModel.fromMap(task as Map<String, dynamic>)).toList();
      }
      
      return [];
    } catch (e) {
      print('获取定时发送邮件任务失败: $e');
      return [];
    }
  }

  /// 删除定时发送邮件任务
  Future<void> deleteScheduledEmailTask(String taskId) async {
    await get("DeleteScheduledEmailTask", {'TaskId': taskId});
  }

  /// 取消定时发送邮件任务
  Future<void> cancelScheduledEmailTask(String taskId) async {
    await get("CancelScheduledEmailTask", {'TaskId': taskId});
  }
} 