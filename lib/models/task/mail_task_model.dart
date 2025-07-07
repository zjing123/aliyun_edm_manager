import 'package:aliyun_edm_manager/utils/time_formatter.dart';

class MailTaskModel {
  final String taskId;
  final String taskName;
  final String addressType;
  final String tagName;
  final String receiversName;
  final String templateName;
  final String requestCount;
  final String successCount;
  final String createTime;
  final String taskStatus;

  MailTaskModel({
    required this.taskId,
    required this.taskName,
    required this.addressType,
    required this.tagName,
    required this.receiversName,
    required this.templateName,
    required this.requestCount,
    required this.successCount,
    required this.createTime,
    required this.taskStatus,
  });

  String get statusText {
    switch (taskStatus) {
      case '1':
        return '成功';
      case '2':
        return '发送中';
      case '3':
        return '失败';
      default:
        return '未知';
    }
  }

  /// 获取格式化后的创建时间
  String formattedCreateTime({String timeZone = TimeFormatter.defaultTimeZone}) {
    return TimeFormatter.formatDateTime(
      timeString: createTime,
      timeZone: timeZone,
    );
  }

  /// 获取格式化后的创建日期（仅日期部分）
  String formattedCreateDate({String timeZone = TimeFormatter.defaultTimeZone}) {
    return TimeFormatter.formatDate(
      timeString: createTime,
      timeZone: timeZone,
    );
  }

  /// 获取相对时间（如：刚刚、5分钟前等）
  String relativeCreateTime({String timeZone = TimeFormatter.defaultTimeZone}) {
    return TimeFormatter.formatRelativeTime(
      timeString: createTime,
      timeZone: timeZone,
    );
  }

  factory MailTaskModel.fromJson(Map<String, dynamic> json) {
    return MailTaskModel(
      taskId: json['TaskId']?.toString() ?? '',
      taskName: json['TaskName']?.toString() ?? '',
      addressType: json['AddressType']?.toString() ?? '',
      tagName: json['TagName']?.toString() ?? '',
      receiversName: json['ReceiversName']?.toString() ?? '',
      templateName: json['TemplateName']?.toString() ?? '',
      requestCount: json['RequestCount']?.toString() ?? '0',
      successCount: json['SuccessCount']?.toString() ?? '0',
      createTime: json['CreateTime']?.toString() ?? '',
      taskStatus: json['TaskStatus']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TaskId': taskId,
      'TaskName': taskName,
      'AddressType': addressType,
      'TagName': tagName,
      'ReceiversName': receiversName,
      'TemplateName': templateName,
      'RequestCount': requestCount,
      'SuccessCount': successCount,
      'CreateTime': createTime,
      'TaskStatus': taskStatus,
    };
  }
}

class MailTaskResponse {
  final List<MailTaskModel> tasks;
  final int totalCount;
  final int pageSize;
  final int pageNumber;

  MailTaskResponse({
    required this.tasks,
    required this.totalCount,
    required this.pageSize,
    required this.pageNumber,
  });

  factory MailTaskResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final tasks = data != null ? data['task'] : null;
    
    List<MailTaskModel> taskList = [];
    if (tasks != null && tasks is List) {
      taskList = tasks.map((task) => MailTaskModel.fromJson(task)).toList();
    }

    return MailTaskResponse(
      tasks: taskList,
      totalCount: json['TotalCount']?.toInt() ?? 0,
      pageSize: json['PageSize']?.toInt() ?? 20,
      pageNumber: json['PageNumber']?.toInt() ?? 1,
    );
  }
}

class BatchSendMailRequest {
  final String receiversName;
  final String templateName;
  final String accountName;
  final String clickTrace;
  final String addressType;
  final String tagName;
  final String replyToAddress;
  final String? taskName;

  BatchSendMailRequest({
    required this.receiversName,
    required this.templateName,
    required this.accountName,
    required this.clickTrace,
    required this.addressType,
    required this.tagName,
    required this.replyToAddress,
    this.taskName,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'ReceiversName': receiversName,
      'TemplateName': templateName,
      'AccountName': accountName,
      'ClickTrace': clickTrace,
      'AddressType': addressType,
      'TagName': tagName,
      'ReplyToAddress': replyToAddress,
    };
    
    if (taskName != null && taskName!.isNotEmpty) {
      data['TaskName'] = taskName!;
    }
    
    return data;
  }
} 