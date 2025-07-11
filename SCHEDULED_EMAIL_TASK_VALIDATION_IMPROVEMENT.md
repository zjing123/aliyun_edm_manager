# 定时发送邮件任务创建页面验证改进

## 改进概述

对定时发送邮件任务创建页面进行了以下改进：

1. **邮件标签设置为必填字段**
2. **创建任务按钮默认禁用，只有在所有必填字段填写正确后才启用**

## 具体修改

### 1. 邮件标签必填标识

在 `_buildEmailTagField()` 方法中，将邮件标签字段的标题从普通文本改为 `RichText`，添加了红色星号标识：

```dart
RichText(
  text: TextSpan(
    style: TextStyle(color: Colors.grey[700], fontSize: 14),
    children: const [
      TextSpan(
        text: '邮件标签',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      TextSpan(
        text: ' *',
        style: TextStyle(color: Colors.red),
      ),
    ],
  ),
),
```

### 2. 添加字段验证方法

新增 `_areAllRequiredFieldsFilled()` 方法来检查所有必填字段是否已填写：

```dart
bool _areAllRequiredFieldsFilled() {
  // 检查任务名称
  if (_taskNameController.text.trim().isEmpty) return false;
  
  // 检查收件人列表
  if (_selectedReceiverIds.isEmpty) return false;
  
  // 检查邮件模板
  if (_selectedTemplateId == null || _selectedTemplateId!.isEmpty) return false;
  
  // 检查发信地址
  if (_selectedSenderAddress == null || _selectedSenderAddress!.isEmpty) return false;
  
  // 检查发信地址类型
  if (_selectedSenderType == null || _selectedSenderType!.isEmpty) return false;
  
  // 检查邮件标签（必填）
  if (_selectedEmailTag == null || _selectedEmailTag!.isEmpty) return false;
  
  // 如果启用了定时发送，检查定时发送时间
  if (_enableScheduledSend) {
    if (_startSendTime == null) return false;
    if (_startSendTime!.isBefore(DateTime.now())) return false;
  }
  
  return true;
}
```

### 3. 按钮状态管理

修改 `_buildBottomActionBar()` 方法，根据字段验证状态来控制按钮的启用/禁用：

```dart
Widget _buildBottomActionBar() {
  final bool isFormValid = _areAllRequiredFieldsFilled();
  
  return Container(
    // ... 其他代码
    child: Row(
      children: [
        // ... 取消按钮
        Expanded(
          child: ElevatedButton(
            onPressed: isFormValid ? _submitTask : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFormValid ? Colors.blue[600] : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: isFormValid ? 2 : 0,
            ),
            child: Text(
              widget.taskToEdit != null ? '更新任务' : '创建任务',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    ),
  );
}
```

### 4. 添加控制器监听器

在 `initState()` 方法中为相关控制器添加监听器，确保字段值变化时能触发状态更新：

```dart
@override
void initState() {
  super.initState();
  
  // 添加任务名称控制器监听器
  _taskNameController.addListener(() {
    setState(() {});
  });
  
  // 添加发送间隔控制器监听器
  _sendIntervalController.addListener(() {
    setState(() {});
  });
  
  // ... 其他初始化代码
}
```

### 5. 邮件标签选择状态更新

在邮件标签选择时添加额外的状态更新调用：

```dart
onTap: () {
  setState(() {
    _selectedEmailTag = isSelected ? null : tag.tagId;
    _showEmailTagDropdown = false;
  });
  // 触发按钮状态更新
  setState(() {});
},
```

## 验证逻辑

### 必填字段列表

1. **任务名称** - 不能为空，至少2个字符，最多50个字符
2. **收件人列表** - 至少选择一个收件人列表
3. **邮件模板** - 必须选择一个邮件模板
4. **发信地址** - 必须选择一个发信地址
5. **发信地址类型** - 必须选择发信地址类型
6. **邮件标签** - 必须选择一个邮件标签（新增必填项）

### 条件验证

- **定时发送时间** - 如果启用了定时发送，必须选择有效的开始时间（不能小于当前时间）

## 用户体验改进

1. **视觉反馈** - 按钮颜色会根据验证状态变化（蓝色表示可用，灰色表示禁用）
2. **实时验证** - 用户填写字段时，按钮状态会实时更新
3. **清晰标识** - 必填字段都有红色星号标识
4. **错误提示** - 提交时会显示具体的验证错误信息

## 技术实现

- 使用 `setState()` 来触发UI更新
- 通过控制器监听器实现实时验证
- 使用 `RichText` 组件显示必填标识
- 通过条件渲染控制按钮状态和样式

## 测试要点

1. 验证邮件标签字段显示红色星号
2. 验证创建任务按钮初始状态为禁用（灰色）
3. 验证填写所有必填字段后按钮变为启用（蓝色）
4. 验证删除必填字段后按钮重新变为禁用
5. 验证定时发送时间验证逻辑
6. 验证编辑模式下的预填充和验证逻辑 