/// 分页相关常量
/// 定义不同接口的最大分页数量限制
class PaginationConstants {
  // 收件人相关
  static const int receiverDefaultPageSize = 50;
  static const int receiverDetailMaxPageSize = 50;

  // 模板相关
  static const int templateDefaultPageSize = 10;
  static const int templateMaxPageSize = 50;

  // 跟踪数据相关
  static const int trackDefaultPageSize = 10;
  static const int trackMaxPageSize = 10;

  // 邮件任务相关
  static const int mailTaskDefaultPageSize = 20;
  static const int emailTaskMaxPageSize = 10;

  // 发信地址相关
  static const int senderAddressDefaultPageSize = 10;
  static const int senderAddressMaxPageSize = 50;

  // 邮件标签相关
  static const int tagDefaultPageSize = 10;
  static const int emailTagMaxPageSize = 500;

  // 定时邮件任务相关
  static const int scheduledEmailTaskDefaultPageSize = 10;
  static const int scheduledEmailTaskMaxPageSize = 10;

  // 通用默认最大分页大小
  static const int defaultMaxPageSize = 50;
  // 通用默认分页大小（仅用于未指定场景）
  static const int defaultPageSize = 10;
}