# 收件人列表名称重复检查功能

## 功能概述

为了防止创建重复的收件人列表名称，系统现在会在创建新收件人列表时自动检查名称是否已存在。

## 实现的功能

### 1. 单个收件人列表创建时的重复检查

在 `lib/utils/dialog_util.dart` 的 `inputReceiverName` 方法中：

- 在打开创建对话框时，自动获取现有的收件人列表
- 在用户输入列表名称时，实时检查是否与现有名称重复
- 如果检测到重复，会显示错误提示："列表名称已存在，请使用其他名称"
- 重复检查忽略大小写和前后空格

### 2. 批量创建收件人列表时的重复检查

在 `lib/pages/batch_create_receiver_page.dart` 的 `_processFile` 方法中：

- 在开始批量创建前，获取所有现有的收件人列表名称
- 在创建每个列表前，检查生成的名称是否重复
- 如果检测到重复，会跳过该列表的创建，并在失败列表中标记为"名称重复"
- 成功创建的列表名称会被添加到现有名称集合中，避免后续批次重复

## 检查规则

1. **大小写不敏感**：`"测试列表"` 和 `"测试列表"` 被认为是重复的
2. **忽略空格**：`" 测试列表 "` 和 `"测试列表"` 被认为是重复的
3. **实时验证**：在输入过程中实时检查，提供即时反馈
4. **批量处理**：在批量创建时，会跳过重复的名称并继续处理其他列表

## 用户体验

### 单个创建
- 用户输入重复名称时，输入框会显示红色边框和错误提示
- 创建按钮会被禁用，直到输入有效的非重复名称
- 错误提示：`"列表名称已存在，请使用其他名称"`

### 批量创建
- 重复的列表会被跳过，不会影响其他列表的创建
- 在结果报告中会显示哪些列表因名称重复而失败
- 失败原因会明确标注为"名称重复"

## 技术实现

### 数据获取
```dart
// 获取现有的收件人列表名称用于重复检查
final AliyunEDMService service = AliyunEDMService();
List<Map<String, dynamic>> existingReceivers = await service.queryReceivers();
final existingNames = existingReceivers
    .map((r) => (r['ReceiversName'] as String?)?.toLowerCase().trim())
    .where((name) => name != null)
    .toSet();
```

### 重复检查
```dart
// 检查名称是否重复
if (existingNames.contains(trimmedValue.toLowerCase())) {
  nameError = '列表名称已存在，请使用其他名称';
}
```

## 测试

创建了专门的测试文件 `test/receiver_name_validation_test.dart` 来验证：

1. 重复名称检测
2. 大小写和空格处理
3. 空值和无效数据处理

运行测试：
```bash
flutter test test/receiver_name_validation_test.dart
```

## 注意事项

1. 该功能依赖于 `AliyunEDMService.queryReceivers()` 方法的正常工作
2. 在网络连接不稳定时，可能会影响重复检查的准确性
3. 建议在创建大量列表前，先检查现有列表，避免不必要的重复尝试 