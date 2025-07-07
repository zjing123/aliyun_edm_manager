class ScheduledEmailTaskModel {
  final String taskId;
  final String taskName;
  final String templateId;
  final String templateName;
  final List<ReceiverListConfig> receiverLists;
  final String senderAddress;
  final String senderName;
  final String senderType; // '0' for random, '1' for fixed
  final String? tag;
  final bool enableTracking;
  final String status; // 'pending', 'processing', 'completed', 'failed', 'paused'
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? scheduledStartTime; // 定时发送的开始时间
  final int? sendIntervalMinutes; // 发送间隔(分钟)
  final int totalEmails;
  final int sentEmails;
  final int failedEmails;
  final String? errorMessage; // 错误消息

  ScheduledEmailTaskModel({
    required this.taskId,
    required this.taskName,
    required this.templateId,
    required this.templateName,
    required this.receiverLists,
    required this.senderAddress,
    required this.senderName,
    required this.senderType,
    this.tag,
    this.enableTracking = false,
    this.status = 'pending',
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.scheduledStartTime,
    this.sendIntervalMinutes,
    this.totalEmails = 0,
    this.sentEmails = 0,
    this.failedEmails = 0,
    this.errorMessage,
  });

  factory ScheduledEmailTaskModel.fromMap(Map<String, dynamic> map) {
    return ScheduledEmailTaskModel(
      taskId: map['TaskId']?.toString() ?? '',
      taskName: map['TaskName']?.toString() ?? '',
      templateId: map['TemplateId']?.toString() ?? '',
      templateName: map['TemplateName']?.toString() ?? '',
      receiverLists: (map['ReceiverLists'] as List<dynamic>?)
              ?.map((e) => ReceiverListConfig.fromMap(e))
              .toList() ??
          [],
      senderAddress: map['SenderAddress']?.toString() ?? '',
      senderName: map['SenderName']?.toString() ?? '',
      senderType: map['SenderType']?.toString() ?? '1',
      tag: map['Tag']?.toString(),
      enableTracking: map['EnableTracking'] as bool? ?? false,
      status: map['Status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(map['CreatedAt']?.toString() ?? '') ?? DateTime.now(),
      startedAt: map['StartedAt'] != null ? DateTime.tryParse(map['StartedAt'].toString()) : null,
      completedAt: map['CompletedAt'] != null ? DateTime.tryParse(map['CompletedAt'].toString()) : null,
      scheduledStartTime: map['ScheduledStartTime'] != null ? DateTime.tryParse(map['ScheduledStartTime'].toString()) : null,
      sendIntervalMinutes: map['SendIntervalMinutes'] as int?,
      totalEmails: map['TotalEmails'] as int? ?? 0,
      sentEmails: map['SentEmails'] as int? ?? 0,
      failedEmails: map['FailedEmails'] as int? ?? 0,
      errorMessage: map['ErrorMessage']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'TaskId': taskId,
      'TaskName': taskName,
      'TemplateId': templateId,
      'TemplateName': templateName,
      'ReceiverLists': receiverLists.map((e) => e.toMap()).toList(),
      'SenderAddress': senderAddress,
      'SenderName': senderName,
      'SenderType': senderType,
      'Tag': tag,
      'EnableTracking': enableTracking,
      'Status': status,
      'CreatedAt': createdAt.toIso8601String(),
      'StartedAt': startedAt?.toIso8601String(),
      'CompletedAt': completedAt?.toIso8601String(),
      'ScheduledStartTime': scheduledStartTime?.toIso8601String(),
      'SendIntervalMinutes': sendIntervalMinutes,
      'TotalEmails': totalEmails,
      'SentEmails': sentEmails,
      'FailedEmails': failedEmails,
      'ErrorMessage': errorMessage,
    };
  }

  ScheduledEmailTaskModel copyWith({
    String? taskId,
    String? taskName,
    String? templateId,
    String? templateName,
    List<ReceiverListConfig>? receiverLists,
    String? senderAddress,
    String? senderName,
    String? senderType,
    String? tag,
    bool? enableTracking,
    String? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? scheduledStartTime,
    int? sendIntervalMinutes,
    int? totalEmails,
    int? sentEmails,
    int? failedEmails,
    String? errorMessage,
  }) {
    return ScheduledEmailTaskModel(
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      receiverLists: receiverLists ?? this.receiverLists,
      senderAddress: senderAddress ?? this.senderAddress,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      tag: tag ?? this.tag,
      enableTracking: enableTracking ?? this.enableTracking,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      sendIntervalMinutes: sendIntervalMinutes ?? this.sendIntervalMinutes,
      totalEmails: totalEmails ?? this.totalEmails,
      sentEmails: sentEmails ?? this.sentEmails,
      failedEmails: failedEmails ?? this.failedEmails,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'ScheduledEmailTaskModel(taskId: $taskId, taskName: $taskName, status: $status)';
  }
}

class ReceiverListConfig {
  final String receiverId;
  final String receiverName;
  final int intervalMinutes; // 发送间隔（分钟）
  final int emailCount;
  final String? listId;
  final String? listName;
  final int? receiverCount;

  ReceiverListConfig({
    required this.receiverId,
    required this.receiverName,
    required this.intervalMinutes,
    required this.emailCount,
    this.listId,
    this.listName,
    this.receiverCount,
  });

  factory ReceiverListConfig.fromMap(Map<String, dynamic> map) {
    return ReceiverListConfig(
      receiverId: map['ReceiverId']?.toString() ?? '',
      receiverName: map['ReceiverName']?.toString() ?? '',
      intervalMinutes: map['IntervalMinutes'] as int? ?? 0,
      emailCount: map['EmailCount'] as int? ?? 0,
      listId: map['ListId']?.toString(),
      listName: map['ListName']?.toString(),
      receiverCount: map['ReceiverCount'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ReceiverId': receiverId,
      'ReceiverName': receiverName,
      'IntervalMinutes': intervalMinutes,
      'EmailCount': emailCount,
      'ListId': listId,
      'ListName': listName,
      'ReceiverCount': receiverCount,
    };
  }

  @override
  String toString() {
    return 'ReceiverListConfig(receiverId: $receiverId, receiverName: $receiverName, intervalMinutes: $intervalMinutes, receiverCount: $receiverCount)';
  }
} 