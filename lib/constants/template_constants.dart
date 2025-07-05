/// 模板相关常量定义
class TemplateConstants {
  // 模板状态
  static const String STATUS_APPROVED = '0';  // 审核通过
  static const String STATUS_PENDING = '2';   // 待审核
  
  // 模板类型
  static const String TYPE_TRIGGER = '0';     // 触发邮件
  static const String TYPE_BATCH = '1';       // 批量邮件
  
  // 状态描述映射
  static const Map<String, String> statusDescriptions = {
    STATUS_APPROVED: '审核通过',
    STATUS_PENDING: '待审核',
  };
  
  // 类型描述映射
  static const Map<String, String> typeDescriptions = {
    TYPE_TRIGGER: '触发邮件',
    TYPE_BATCH: '批量邮件',
  };
  
  // 获取状态描述
  static String getStatusDescription(String status) {
    return statusDescriptions[status] ?? '未知状态';
  }
  
  // 获取类型描述
  static String getTypeDescription(String type) {
    return typeDescriptions[type] ?? '未知类型';
  }
  
  // 判断模板是否可用
  static bool isTemplateAvailable(String status) {
    return status == STATUS_APPROVED;
  }
}