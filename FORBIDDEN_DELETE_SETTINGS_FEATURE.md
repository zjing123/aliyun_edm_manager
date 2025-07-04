# 禁止删除收件人列表设置功能

## 功能概述

本功能允许用户通过专门的设置页面，动态管理哪些收件人列表不可删除。这些设置保存在本地存储中，每次加载收件人列表时会自动应用这些设置。

## 核心特性

### 1. 动态配置管理
- 通过本地存储（SharedPreferences）保存禁止删除的收件人列表ID
- 支持动态添加/移除禁止删除的列表
- 自动清理不存在的收件人列表ID

### 2. 实时数据同步
- 每次进入设置页面都会调用接口获取最新的收件人列表
- 自动清理本地存储中不存在的收件人列表ID
- 设置修改后立即生效

### 3. 用户友好的界面
- 专门的设置页面，提供清晰的勾选界面
- 实时显示当前设置的统计信息
- 支持一键清空所有设置

## 实现架构

### 1. 数据层

#### ConfigService 扩展
```dart
// 禁止删除的收件人列表ID相关方法
static const String _forbiddenDeleteReceiverIdsKey = 'forbidden_delete_receiver_ids';

// 获取禁止删除的收件人列表ID集合
Future<Set<String>> getForbiddenDeleteReceiverIds()

// 设置禁止删除的收件人列表ID集合
Future<bool> setForbiddenDeleteReceiverIds(Set<String> ids)

// 清理不存在的收件人列表ID
Future<bool> cleanNonExistentReceiverIds(List<String> existingIds)

// 清空所有禁止删除的收件人列表ID
Future<bool> clearForbiddenDeleteReceiverIds()
```

#### ReceiverListModel 扩展
```dart
// 添加copyWith方法
ReceiverListModel copyWith({
  String? receiverId,
  String? receiversName,
  String? receiversAlias,
  String? desc,
  int? count,
  String? createTime,
  bool? isDeletable,
})
```

### 2. 业务逻辑层

#### ReceiverListProvider 增强
```dart
// 加载收件人列表时自动处理isDeletable字段
Future<void> loadReceivers({bool forceRefresh = false}) async {
  // 1. 从接口获取最新数据
  final data = await _service.queryReceivers();
  final configService = await ConfigService.getInstance();
  
  // 2. 获取禁止删除的ID
  final forbiddenIds = await configService.getForbiddenDeleteReceiverIds();
  
  // 3. 清理不存在的ID
  final existingIds = data.map((map) => map['ReceiverId']?.toString() ?? '').toList();
  await configService.cleanNonExistentReceiverIds(existingIds);
  
  // 4. 设置isDeletable字段
  _receivers = data.map((map) {
    final receiver = ReceiverListModel.fromMap(map);
    final isDeletable = !forbiddenIds.contains(receiver.receiverId);
    return receiver.copyWith(isDeletable: isDeletable);
  }).toList();
}
```

### 3. 界面层

#### ForbiddenDeleteSettingsPage
- 专门的设置页面
- 显示所有收件人列表的勾选框
- 实时统计当前设置的数量
- 支持保存和清空操作

#### ReceiverListPage 增强
- 添加"禁止删除设置"按钮
- 根据isDeletable字段控制UI显示
- 不可删除的列表显示"只读"标签
- 复选框和删除按钮根据权限动态显示

## 使用流程

### 1. 进入设置页面
用户点击收件人列表页面的"禁止删除设置"按钮，进入专门的设置页面。

### 2. 加载最新数据
页面会自动调用接口获取最新的收件人列表，并清理本地存储中不存在的ID。

### 3. 设置管理
用户可以通过勾选框选择哪些收件人列表不可删除：
- 勾选：列表将被标记为"只读"，无法删除
- 取消勾选：列表将可以正常删除

### 4. 保存设置
点击"保存设置"按钮，将当前选择保存到本地存储。

### 5. 应用设置
返回收件人列表页面后，设置会立即生效，不可删除的列表会显示相应的UI状态。

## 数据流程

```
用户操作 → 设置页面 → 本地存储 → Provider → UI更新
    ↓
接口调用 → 数据清理 → isDeletable设置 → 界面渲染
```

## 技术特点

### 1. 数据一致性
- 每次加载都会清理不存在的ID，确保数据一致性
- 使用本地存储保证设置的持久性

### 2. 性能优化
- 只在需要时调用接口获取最新数据
- 使用Provider模式进行状态管理

### 3. 用户体验
- 清晰的视觉反馈（只读标签、禁用复选框等）
- 实时统计信息
- 一键操作（保存、清空）

### 4. 错误处理
- 完善的异常处理机制
- 用户友好的错误提示

## 扩展性

这个功能设计具有良好的扩展性：

1. **权限控制**：可以基于用户角色设置不同的默认权限
2. **时间限制**：可以添加时间相关的删除限制
3. **批量操作**：可以支持批量设置权限
4. **审计功能**：可以记录权限变更的历史

## 测试覆盖

提供了完整的测试覆盖：
- 模型测试：验证copyWith方法和isDeletable字段
- Provider测试：验证数据加载和状态管理
- UI测试：验证界面交互和状态显示

## 注意事项

1. 设置修改后需要重新加载收件人列表才能生效
2. 删除操作会同时从本地存储中移除对应的ID
3. 新创建的收件人列表默认为可删除状态
4. 设置保存在本地，不同设备间不会同步 