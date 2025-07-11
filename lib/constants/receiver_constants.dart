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