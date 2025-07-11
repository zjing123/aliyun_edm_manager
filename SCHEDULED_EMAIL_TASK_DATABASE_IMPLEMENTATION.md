# 定时发送邮件任务数据库实现

## 概述

为定时发送邮件任务创建了详细的数据库表结构，包含所有必要的字段信息，支持完整的CRUD操作。

## 数据库表结构

### 1. scheduled_email_task_details 表

这是新创建的主要表，包含所有要求的字段：

```sql
CREATE TABLE scheduled_email_task_details (
  task_id TEXT PRIMARY KEY,
  receivers_id TEXT NOT NULL,
  receivers_name TEXT NOT NULL,
  template_id TEXT NOT NULL,
  template_name TEXT NOT NULL,
  mail_address_id TEXT NOT NULL,
  mail_address_name TEXT NOT NULL,
  mail_address_type TEXT NOT NULL,
  email_tag TEXT NOT NULL,
  email_tag_name TEXT NOT NULL,
  click_track INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  scheduled_time TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  FOREIGN KEY (task_id) REFERENCES scheduled_email_tasks(task_id) ON DELETE CASCADE
);
```

### 字段说明

| 字段名 | 类型 | 说明 | 必填 |
|--------|------|------|------|
| task_id | TEXT | 任务ID（主键） | 是 |
| receivers_id | TEXT | 收件人列表ID | 是 |
| receivers_name | TEXT | 收件人列表名称 | 是 |
| template_id | TEXT | 模板ID | 是 |
| template_name | TEXT | 模板名称 | 是 |
| mail_address_id | TEXT | 发信地址ID | 是 |
| mail_address_name | TEXT | 发信地址名称 | 是 |
| mail_address_type | TEXT | 发信地址类型 | 是 |
| email_tag | TEXT | 邮件标签ID | 是 |
| email_tag_name | TEXT | 邮件标签名称 | 是 |
| click_track | INTEGER | 是否启用邮件跟踪（0/1） | 是 |
| created_at | TEXT | 创建时间 | 是 |
| scheduled_time | TEXT | 发送时间 | 否 |
| status | TEXT | 状态 | 是 |

### 2. 索引

为了提高查询性能，创建了以下索引：

```sql
CREATE INDEX idx_task_details_status ON scheduled_email_task_details(status);
CREATE INDEX idx_task_details_scheduled_time ON scheduled_email_task_details(scheduled_time);
CREATE INDEX idx_task_details_receivers_id ON scheduled_email_task_details(receivers_id);
CREATE INDEX idx_task_details_template_id ON scheduled_email_task_details(template_id);
CREATE INDEX idx_task_details_mail_address_id ON scheduled_email_task_details(mail_address_id);
CREATE INDEX idx_task_details_email_tag ON scheduled_email_task_details(email_tag);
```

## 数据模型

### ScheduledEmailTaskDetailModel

创建了新的数据模型来表示详细的定时发送邮件任务：

```dart
class ScheduledEmailTaskDetailModel {
  final String taskId;
  final String receiversId;
  final String receiversName;
  final String templateId;
  final String templateName;
  final String mailAddressId;
  final String mailAddressName;
  final String mailAddressType;
  final String emailTag;
  final String emailTagName;
  final bool clickTrack;
  final DateTime createdAt;
  final DateTime? scheduledTime;
  final String status;
  
  // 构造函数、fromMap、toMap、copyWith等方法
}
```

## 数据库操作方法

### 基本CRUD操作

1. **插入操作**
   - `insertTaskDetail()` - 插入单个详细任务记录
   - `insertTaskDetails()` - 批量插入详细任务记录

2. **查询操作**
   - `getTaskDetail()` - 根据任务ID获取详细记录
   - `getAllTaskDetails()` - 获取所有详细记录
   - `getTaskDetailsByStatus()` - 根据状态获取记录
   - `getTaskDetailsByReceiversId()` - 根据收件人列表ID获取记录
   - `getTaskDetailsByTemplateId()` - 根据模板ID获取记录
   - `getTaskDetailsByEmailTag()` - 根据邮件标签获取记录

3. **更新操作**
   - `updateTaskDetail()` - 更新单个详细任务记录
   - `updateTaskDetailStatuses()` - 批量更新状态

4. **删除操作**
   - `deleteTaskDetail()` - 删除单个详细任务记录
   - `deleteExpiredTaskDetails()` - 删除过期的详细任务记录

### 高级查询操作

1. **搜索功能**
   - `searchTaskDetails()` - 根据多个字段搜索任务

2. **统计功能**
   - `getTaskDetailStatistics()` - 获取任务统计信息

3. **定时任务查询**
   - `getPendingScheduledTaskDetails()` - 获取待执行的定时任务

## 数据库升级

### 版本4升级

在数据库版本4中，添加了新的 `scheduled_email_task_details` 表：

```dart
if (oldVersion < 4) {
  // v4: 添加新的定时发送邮件任务详细表
  try {
    // 检查表是否已存在
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='scheduled_email_task_details'"
    );
    
    if (result.isEmpty) {
      // 创建新表和索引
      await db.execute('CREATE TABLE scheduled_email_task_details (...)');
      // 创建索引...
    }
  } catch (e) {
    print('数据库升级错误：$e');
  }
}
```

## Provider集成

### 定时发送邮件任务提供者更新

更新了 `ScheduledEmailTaskProvider` 以支持新的详细表：

1. **创建任务时**
   - 同时创建主任务记录和详细任务记录
   - 支持单个和多个收件人列表的情况

2. **更新任务时**
   - 同时更新主任务记录和详细任务记录

3. **删除任务时**
   - 同时删除主任务记录和详细任务记录

## 使用示例

### 创建任务

```dart
final taskDetail = ScheduledEmailTaskDetailModel(
  taskId: 'task_123',
  receiversId: 'receivers_456',
  receiversName: 'VIP客户列表',
  templateId: 'template_789',
  templateName: '促销邮件模板',
  mailAddressId: 'mail_001',
  mailAddressName: 'marketing@company.com',
  mailAddressType: '1', // 固定地址
  emailTag: 'tag_001',
  emailTagName: '促销活动',
  clickTrack: true,
  createdAt: DateTime.now(),
  scheduledTime: DateTime.now().add(Duration(hours: 1)),
  status: 'pending',
);

await databaseService.insertTaskDetail(taskDetail);
```

### 查询任务

```dart
// 获取所有任务
final allTasks = await databaseService.getAllTaskDetails();

// 根据状态查询
final pendingTasks = await databaseService.getTaskDetailsByStatus('pending');

// 搜索任务
final searchResults = await databaseService.searchTaskDetails('促销');
```

## 状态管理

### 任务状态

支持以下任务状态：
- `pending` - 等待中
- `processing` - 处理中
- `completed` - 已完成
- `failed` - 失败
- `paused` - 已暂停
- `cancelled` - 已取消

### 邮件跟踪

`click_track` 字段用于标识是否启用邮件跟踪功能：
- `0` - 不启用
- `1` - 启用

## 性能优化

1. **索引优化**
   - 为常用查询字段创建索引
   - 支持快速的状态和ID查询

2. **批量操作**
   - 支持批量插入和更新操作
   - 减少数据库事务次数

3. **外键约束**
   - 使用外键确保数据一致性
   - 级联删除相关记录

## 数据完整性

1. **必填字段验证**
   - 所有关键字段都设置为NOT NULL
   - 提供默认值避免空值问题

2. **外键约束**
   - 与主任务表建立外键关系
   - 确保数据关联的完整性

3. **状态管理**
   - 统一的状态枚举
   - 状态转换的验证

## 扩展性

1. **字段扩展**
   - 表结构支持未来字段扩展
   - 向后兼容的升级机制

2. **查询扩展**
   - 灵活的查询接口
   - 支持复杂的搜索条件

3. **功能扩展**
   - 模块化的设计
   - 易于添加新功能 