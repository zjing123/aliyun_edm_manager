class ScheduledEmailTaskModel {
  final String taskId;                    // 任务id
  final String taskName;                  // 任务名称
  final String templateId;                // 模板id
  final String templateName;              // 模板名称
  final String status;                    // 任务状态
  final DateTime createdAt;               // 创建时间
  final DateTime? startedAt;              // 任务开始时间
  final DateTime? completedAt;            // 任务完成时间
  final int? sendIntervalMinutes;         // 任务间隔分钟数
  final String? errorMessage;             // 错误信息
  final String receiversId;               // 收件人列表id
  final String receiversName;             // 收件人列表名称
  final String mailAddressId;             // 发信地址 ID
  final String mailAddress;               // 发信地址
  final String mailAddressType;           // 发信地址类型
  final String emailTagId;                // 邮件标签id
  final String emailTagName;              // 邮件标签名称
  final bool clickTrack;                  // 是否启用跟踪
  final DateTime? scheduledTime;          // 任务执行时间

  ScheduledEmailTaskModel({
    required this.taskId,
    required this.taskName,
    required this.templateId,
    required this.templateName,
    this.status = 'pending',
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.sendIntervalMinutes,
    this.errorMessage,
    required this.receiversId,
    required this.receiversName,
    required this.mailAddressId,
    required this.mailAddress,
    required this.mailAddressType,
    required this.emailTagId,
    required this.emailTagName,
    this.clickTrack = false,
    this.scheduledTime,
  });

  factory ScheduledEmailTaskModel.fromMap(Map<String, dynamic> map) {
    return ScheduledEmailTaskModel(
      taskId: map['TaskId']?.toString() ?? '',
      taskName: map['TaskName']?.toString() ?? '',
      templateId: map['TemplateId']?.toString() ?? '',
      templateName: map['TemplateName']?.toString() ?? '',
      status: map['Status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(map['CreatedAt']?.toString() ?? '') ?? DateTime.now(),
      startedAt: map['StartedAt'] != null ? DateTime.tryParse(map['StartedAt'].toString()) : null,
      completedAt: map['CompletedAt'] != null ? DateTime.tryParse(map['CompletedAt'].toString()) : null,
      sendIntervalMinutes: map['SendIntervalMinutes'] as int?,
      errorMessage: map['ErrorMessage']?.toString(),
      receiversId: map['ReceiversId']?.toString() ?? '',
      receiversName: map['ReceiversName']?.toString() ?? '',
      mailAddressId: map['MailAddressId']?.toString() ?? '',
      mailAddress: map['MailAddress']?.toString() ?? '',
      mailAddressType: map['MailAddressType']?.toString() ?? '',
      emailTagId: map['EmailTagId']?.toString() ?? '',
      emailTagName: map['EmailTagName']?.toString() ?? '',
      clickTrack: map['ClickTrack'] as bool? ?? false,
      scheduledTime: map['ScheduledTime'] != null ? DateTime.tryParse(map['ScheduledTime'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'TaskId': taskId,
      'TaskName': taskName,
      'TemplateId': templateId,
      'TemplateName': templateName,
      'Status': status,
      'CreatedAt': createdAt.toIso8601String(),
      'StartedAt': startedAt?.toIso8601String(),
      'CompletedAt': completedAt?.toIso8601String(),
      'SendIntervalMinutes': sendIntervalMinutes,
      'ErrorMessage': errorMessage,
      'ReceiversId': receiversId,
      'ReceiversName': receiversName,
      'MailAddressId': mailAddressId,
      'MailAddress': mailAddress,
      'MailAddressType': mailAddressType,
      'EmailTagId': emailTagId,
      'EmailTagName': emailTagName,
      'ClickTrack': clickTrack,
      'ScheduledTime': scheduledTime?.toIso8601String(),
    };
  }

  ScheduledEmailTaskModel copyWith({
    String? taskId,
    String? taskName,
    String? templateId,
    String? templateName,
    String? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? sendIntervalMinutes,
    String? errorMessage,
    String? receiversId,
    String? receiversName,
    String? mailAddressId,
    String? mailAddress,
    String? mailAddressType,
    String? emailTagId,
    String? emailTagName,
    bool? clickTrack,
    DateTime? scheduledTime,
  }) {
    return ScheduledEmailTaskModel(
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      sendIntervalMinutes: sendIntervalMinutes ?? this.sendIntervalMinutes,
      errorMessage: errorMessage ?? this.errorMessage,
      receiversId: receiversId ?? this.receiversId,
      receiversName: receiversName ?? this.receiversName,
      mailAddressId: mailAddressId ?? this.mailAddressId,
      mailAddress: mailAddress ?? this.mailAddress,
      mailAddressType: mailAddressType ?? this.mailAddressType,
      emailTagId: emailTagId ?? this.emailTagId,
      emailTagName: emailTagName ?? this.emailTagName,
      clickTrack: clickTrack ?? this.clickTrack,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  @override
  String toString() {
    return 'ScheduledEmailTaskModel(taskId: $taskId, taskName: $taskName, status: $status)';
  }
} 