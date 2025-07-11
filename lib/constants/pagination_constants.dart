/// 分页相关常量
class PaginationConstants {
  // 收件人列表分页
  static const int receiverListMaxPageSize = 50;
  
  // 收件人详情分页
  static const int receiverDetailMaxPageSize = 50;
  
  // 发件人地址分页
  static const int senderAddressMaxPageSize = 50;
  
  // 发件人名称分页
  static const int senderNameMaxPageSize = 50;
  
  // 模板分页
  static const int templateMaxPageSize = 50;
  
  // 邮件任务分页
  static const int mailTaskMaxPageSize = 50;
  
  // 定时邮件任务分页
  static const int scheduledEmailTaskMaxPageSize = 50;
  
  // 标签分页
  static const int tagMaxPageSize = 50;
  
  // 跟踪数据分页
  static const int trackDataMaxPageSize = 50;
  
  // 发送统计分页
  static const int senderStatisticsMaxPageSize = 50;
}

/// 收件人相关常量
class ReceiverConstants {
  /// 每个收件人列表最多可添加的收件人数量
  static const int maxReceiversPerList = 2000;
  
  /// 批量添加收件人时的最大批量大小（API限制）
  static const int maxBatchSize = 500;
  
  /// 数据大小限制（1MB）
  static const int maxDataSizeBytes = 1024 * 1024;
  
  /// 数据大小警告阈值（900KB）
  static const int dataSizeWarningThresholdBytes = 900 * 1024;
}