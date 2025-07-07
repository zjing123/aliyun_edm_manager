import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/task/mail_task_model.dart';

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

  /// 批量发送邮件
  Future<bool> batchSendMail(BatchSendMailRequest request) async {
    try {
      final params = <String, String>{
        'ReceiversName': request.receiversName,
        'TemplateName': request.templateName,
        'AccountName': request.accountName,
        'ClickTrace': request.clickTrace,
        'AddressType': request.addressType,
        'TagName': request.tagName,
        'ReplyToAddress': request.replyToAddress,
      };
      
      if (request.taskName != null && request.taskName!.isNotEmpty) {
        params['TaskName'] = request.taskName!;
      }

      final response = await post("BatchSendMail", params);
      final responseData = response.data as Map<String, dynamic>;
      
      // 检查响应状态
      return responseData['RequestId'] != null;
    } catch (e) {
      print('批量发送邮件失败: $e');
      return false;
    }
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