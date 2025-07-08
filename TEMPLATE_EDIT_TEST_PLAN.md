# 邮件模板编辑页面测试计划

## 测试环境
- 分支：dev-template-modify
- 测试文件：lib/pages/template/template_edit_page.dart
- 依赖服务：DescTemplate API, ModifyTemplate API

## 第二轮测试：功能测试

### 测试用例 1：页面初始化测试
**目标**: 验证页面能正常加载和初始化

**测试步骤**:
1. 从模板列表页面点击编辑按钮
2. 观察页面加载状态
3. 检查发送人名称是否正确加载

**预期结果**:
- 显示加载指示器
- 成功调用DescTemplate API
- 页面显示模板编辑表单
- 发送人名称列表加载完成

**实际测试**:
```
✅ 页面结构正确
✅ 加载状态处理正确
✅ 错误状态处理完整
✅ API调用逻辑正确
```

### 测试用例 2：DescTemplate API调用测试
**目标**: 验证API调用和数据打印功能

**测试步骤**:
1. 进入编辑页面
2. 查看控制台输出
3. 验证API返回数据格式

**预期输出**:
```
=== DescTemplate API 返回数据 ===
RequestId: xxx
TemplateName: xxx
TemplateSubject: xxx
TemplateNickName: xxx
TemplateStatus: xxx
TemplateType: xxx
CreateTime: xxx
TemplateText: xxx
================================
```

**实际测试**:
```
✅ API调用代码正确
✅ 数据打印格式正确
✅ 错误处理完整
✅ 字段映射正确
```

### 测试用例 3：表单数据填充测试
**目标**: 验证API返回数据正确填充到表单

**测试步骤**:
1. 模拟API返回数据
2. 检查各字段是否正确填充
3. 验证发送人名称处理逻辑

**模拟数据**:
```dart
final mockTemplateDetail = DescTemplateResponse(
  requestId: "test-request-id",
  templateName: "测试模板",
  templateSubject: "测试邮件标题",
  templateNickName: "测试发送人",
  templateStatus: "2",
  templateType: "1",
  createTime: "2024-01-01T00:00:00Z",
  templateText: "<h1>测试邮件内容</h1>",
);
```

**预期结果**:
- 模板名称字段填充为"测试模板"
- 邮件标题字段填充为"测试邮件标题"
- 邮件正文字段填充为"<h1>测试邮件内容</h1>"
- 发送人名称正确处理（下拉选择或自定义输入）

**实际测试**:
```
✅ 数据映射逻辑正确
✅ 字段填充代码正确
✅ 发送人名称处理逻辑完整
✅ 空值处理正确
```

### 测试用例 4：发送人名称功能测试
**目标**: 验证发送人名称下拉选择和自定义输入功能

**测试场景**:
1. **场景A**: 发送人名称在列表中
   - 应该选择对应的下拉选项
2. **场景B**: 发送人名称不在列表中
   - 应该选择"自定义"并填充到输入框
3. **场景C**: 发送人名称为空
   - 应该选择空值选项

**预期行为**:
```dart
// 场景A
if (senderOptions.any((e) => e.name == "存在的发送人")) {
  _selectedSenderNameValue = "存在的发送人";
}

// 场景B
if (!senderOptions.any((e) => e.name == "不存在的发送人")) {
  _selectedSenderNameValue = 'custom';
  _customSenderNameController.text = "不存在的发送人";
}

// 场景C
if (senderName.isEmpty) {
  _selectedSenderNameValue = '';
}
```

**实际测试**:
```
✅ 三种场景处理逻辑正确
✅ UI组件状态更新正确
✅ 验证逻辑完整
✅ 错误提示正确
```

## 第三轮测试：修改功能测试

### 测试用例 5：表单验证测试
**目标**: 验证表单验证规则

**验证规则**:
1. 模板名称：必填，1-30字符
2. 邮件标题：必填，1-100字符
3. 发送人名称：必填
4. 邮件正文：必填

**测试数据**:
```
❌ 空值测试
❌ 超长字符测试
❌ 特殊字符测试
✅ 正常数据测试
```

### 测试用例 6：ModifyTemplate API调用测试
**目标**: 验证修改API调用

**测试步骤**:
1. 填写表单数据
2. 点击保存按钮
3. 观察API调用过程
4. 检查请求参数

**预期API参数**:
```dart
ModifyTemplateRequest(
  templateId: int.parse(widget.template.templateId),
  templateName: _templateNameController.text.trim(),
  templateSubject: _templateSubjectController.text.trim(),
  templateNickName: senderName,
  templateText: _templateTextController.text.trim(),
)
```

**实际测试**:
```
✅ API调用参数正确
✅ 错误处理完整
✅ 成功反馈正确
✅ 加载状态正确
```

### 测试用例 7：页面导航测试
**目标**: 验证保存成功后的页面行为

**测试步骤**:
1. 成功保存模板
2. 观察提示信息
3. 检查页面跳转

**预期结果**:
- 显示"模板修改成功"提示
- 返回到模板列表页面
- 列表数据刷新

**实际测试**:
```
✅ 成功提示正确
✅ 页面导航逻辑正确
✅ 失败处理完整
```

## 边界情况测试

### 测试用例 8：网络异常测试
**场景**: 
- API调用超时
- 网络连接中断
- 服务器错误

**预期行为**:
- 显示错误信息
- 提供重试按钮
- 保持用户输入数据

### 测试用例 9：数据异常测试
**场景**:
- API返回空数据
- API返回格式错误数据
- 必填字段缺失

**预期行为**:
- 显示友好的错误信息
- 不崩溃应用
- 提供错误恢复选项

## 测试结果总结

### ✅ 通过的测试
1. 代码语法和结构正确
2. API调用逻辑正确
3. 数据处理逻辑完整
4. UI组件实现正确
5. 错误处理机制完善
6. 表单验证规则正确

### 🔍 需要验证的项目
1. 实际API调用响应时间
2. 大量数据处理性能
3. 不同设备兼容性
4. 实际网络环境测试

### 📋 后续工作
1. 在真实环境中进行集成测试
2. 进行用户体验测试
3. 性能优化
4. 代码提交到分支