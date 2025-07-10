# 通用表单验证工具使用指南

## 概述

`FormValidator` 工具类提供了通用的表单验证功能，避免在多个页面重复编写相同的验证逻辑。

## 使用方法

### 1. 导入工具类

```dart
import 'package:aliyun_edm_manager/utils/form_validator.dart';
```

### 2. 使用混入类（推荐）

在 State 类中添加 `FormValidationMixin`：

```dart
class _MyPageState extends State<MyPage> with FormValidationMixin {
  final _formKey = GlobalKey<FormState>();
  String? _selectedValue;
  bool _isLoading = false;
  
  // 定义必填字段列表
  List<dynamic> get _requiredFields => [
    _selectedValue,
    // 其他必填字段...
  ];
}
```

### 3. 按钮状态管理

#### 基本用法 - 表单验证

```dart
ElevatedButton(
  onPressed: createFormValidCallback(
    formKey: _formKey,
    requiredFields: _requiredFields,
    callback: _submitForm,
  ),
  child: Text('提交'),
)
```

#### 带加载状态

```dart
ElevatedButton(
  onPressed: createFormValidLoadingCallback(
    formKey: _formKey,
    requiredFields: _requiredFields,
    isLoading: _isLoading,
    callback: _submitForm,
  ),
  child: Text('提交'),
)
```

#### 仅加载状态（无表单验证）

```dart
ElevatedButton(
  onPressed: createLoadingCallback(
    isLoading: _isLoading,
    callback: _submitForm,
  ),
  child: Text('提交'),
)
```

#### 自定义条件

```dart
ElevatedButton(
  onPressed: createConditionalCallback(
    condition: _someCondition && !_isLoading,
    callback: _submitForm,
  ),
  child: Text('提交'),
)
```

### 4. 验证方法

#### 检查表单是否有效

```dart
bool isValid = isFormValid(_formKey, _requiredFields);
```

#### 仅检查字段（不包含Form验证）

```dart
bool isValid = isFormValidWithoutValidation(_requiredFields);
```

#### 检查字符串字段

```dart
bool isValid = areRequiredFieldsFilled([field1, field2, field3]);
```

#### 检查多种类型字段

```dart
bool isValid = areRequiredFieldsFilledGeneric([
  stringField,
  intField,
  boolField,
]);
```

## 使用示例

### 发送邮件页面

```dart
class _SendEmailCreatePageState extends State<SendEmailCreatePage> with FormValidationMixin {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReceiver;
  String? _selectedTemplate;
  String? _selectedSender;
  String? _selectedAddressType;
  String? _selectedTagName;
  
  // 定义必填字段
  List<dynamic> get _requiredFields => [
    _selectedReceiver,
    _selectedTemplate,
    _selectedSender,
    _selectedAddressType,
    _selectedTagName,
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 表单字段...
            ElevatedButton(
              onPressed: createFormValidCallback(
                formKey: _formKey,
                requiredFields: _requiredFields,
                callback: _submitForm,
              ),
              child: Text('发送邮件'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 创建页面（带加载状态）

```dart
class _CreatePageState extends State<CreatePage> with FormValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  
  List<dynamic> get _requiredFields => [
    _nameController.text,
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 表单字段...
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: createLoadingCallback(
                      isLoading: _isLoading,
                      callback: () => Navigator.pop(context),
                    ),
                    child: Text('取消'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: createFormValidLoadingCallback(
                      formKey: _formKey,
                      requiredFields: _requiredFields,
                      isLoading: _isLoading,
                      callback: _saveData,
                    ),
                    child: Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## 优势

1. **代码复用**：避免在每个页面重复编写相同的验证逻辑
2. **一致性**：确保所有页面的验证行为一致
3. **易维护**：验证逻辑集中管理，修改时只需更新一处
4. **类型安全**：支持多种数据类型的验证
5. **灵活性**：提供多种验证方法，适应不同场景

## 注意事项

1. 使用 `FormValidationMixin` 时，确保在 State 类中正确添加 `with FormValidationMixin`
2. 必填字段列表 `_requiredFields` 应该包含所有需要验证的字段
3. 对于文本输入框，建议使用 `controller.text` 而不是 `controller`
4. 在字段值改变时调用 `setState()` 以刷新按钮状态 