class BatchSendTaskModel {
  final String taskId;
  final String taskName;
  final String templateId;
  final String templateName;
  final List<ReceiverListConfig> receiverLists;
  final String senderAddress;
  final String senderName;
  final String? tag;
  final bool enableTracking;
  final String status; // 'pending', 'running', 'completed', 'failed', 'paused'
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int totalEmails;
  final int sentEmails;
  final int failedEmails;

  BatchSendTaskModel({
    required this.taskId,
    required this.taskName,
    required this.templateId,
    required this.templateName,
    required this.receiverLists,
    required this.senderAddress,
    required this.senderName,
    this.tag,
    this.enableTracking = false,
    this.status = 'pending',
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.totalEmails = 0,
    this.sentEmails = 0,
    this.failedEmails = 0,
  });

  factory BatchSendTaskModel.fromMap(Map<String, dynamic> map) {
    return BatchSendTaskModel(
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
      tag: map['Tag']?.toString(),
      enableTracking: map['EnableTracking'] as bool? ?? false,
      status: map['Status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(map['CreatedAt']?.toString() ?? '') ?? DateTime.now(),
      startedAt: map['StartedAt'] != null ? DateTime.tryParse(map['StartedAt'].toString()) : null,
      completedAt: map['CompletedAt'] != null ? DateTime.tryParse(map['CompletedAt'].toString()) : null,
      totalEmails: map['TotalEmails'] as int? ?? 0,
      sentEmails: map['SentEmails'] as int? ?? 0,
      failedEmails: map['FailedEmails'] as int? ?? 0,
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
      'Tag': tag,
      'EnableTracking': enableTracking,
      'Status': status,
      'CreatedAt': createdAt.toIso8601String(),
      'StartedAt': startedAt?.toIso8601String(),
      'CompletedAt': completedAt?.toIso8601String(),
      'TotalEmails': totalEmails,
      'SentEmails': sentEmails,
      'FailedEmails': failedEmails,
    };
  }

  BatchSendTaskModel copyWith({
    String? taskId,
    String? taskName,
    String? templateId,
    String? templateName,
    List<ReceiverListConfig>? receiverLists,
    String? senderAddress,
    String? senderName,
    String? tag,
    bool? enableTracking,
    String? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? totalEmails,
    int? sentEmails,
    int? failedEmails,
  }) {
    return BatchSendTaskModel(
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      receiverLists: receiverLists ?? this.receiverLists,
      senderAddress: senderAddress ?? this.senderAddress,
      senderName: senderName ?? this.senderName,
      tag: tag ?? this.tag,
      enableTracking: enableTracking ?? this.enableTracking,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalEmails: totalEmails ?? this.totalEmails,
      sentEmails: sentEmails ?? this.sentEmails,
      failedEmails: failedEmails ?? this.failedEmails,
    );
  }

  @override
  String toString() {
    return 'BatchSendTaskModel(taskId: $taskId, taskName: $taskName, status: $status)';
  }
}

class ReceiverListConfig {
  final String receiverId;
  final String receiverName;
  final int intervalMinutes; // 发送间隔（分钟）
  final int emailCount;

  ReceiverListConfig({
    required this.receiverId,
    required this.receiverName,
    required this.intervalMinutes,
    required this.emailCount,
  });

  factory ReceiverListConfig.fromMap(Map<String, dynamic> map) {
    return ReceiverListConfig(
      receiverId: map['ReceiverId']?.toString() ?? '',
      receiverName: map['ReceiverName']?.toString() ?? '',
      intervalMinutes: map['IntervalMinutes'] as int? ?? 0,
      emailCount: map['EmailCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ReceiverId': receiverId,
      'ReceiverName': receiverName,
      'IntervalMinutes': intervalMinutes,
      'EmailCount': emailCount,
    };
  }

  @override
  String toString() {
    return 'ReceiverListConfig(receiverId: $receiverId, receiverName: $receiverName, intervalMinutes: $intervalMinutes)';
  }
} 