# 邮件标签功能实现

## 概述

本功能实现了使用阿里云邮件推送服务的 `QueryTagByParam` API 获取邮件标签数据，并在新建定时发送任务页面中提供邮件标签选择功能。

## 功能特性

### 1. API 集成
- 使用阿里云 `QueryTagByParam` API 获取邮件标签列表
- 支持分页查询和关键词搜索
- 完整的错误处理和重试机制

### 2. 数据模型
- `EmailTagModel`: 邮件标签数据模型
- `QueryTagByParamResponse`: API 响应数据模型
- 支持标签ID、名称、描述、创建时间、模板数量等字段

### 3. 用户界面
- 下拉式邮件标签选择器
- 实时搜索功能（支持标签名称和描述搜索）
- 加载状态和错误状态显示
- 选中状态可视化

## 实现细节

### 1. 数据模型 (`lib/models/email_tag_model.dart`)

```dart
class EmailTagModel {
  final String tagId;
  final String tagName;
  final String? description;
  final String createTime;
  final int? templateCount;
  
  // 构造函数、fromJson、toJson 方法
}

class QueryTagByParamResponse {
  final String requestId;
  final int totalCount;
  final int pageNo;
  final int pageSize;
  final List<EmailTagModel> tags;
  
  // 构造函数、fromJson、toJson 方法
}
```

### 2. 服务层 (`lib/services/aliyun_edm_service.dart`)

#### QueryTagByParam API 方法
```dart
Future<QueryTagByParamResponse> queryTagByParam({
  String? keyWord,
  int pageNo = 1,
  int pageSize = 20,
}) async {
  // 构建请求参数
  // 签名验证
  // 发送请求
  // 解析响应
}

Future<List<EmailTagModel>> getAllEmailTags({
  String? keyWord,
  int pageNo = 1,
  int pageSize = 50,
}) async {
  // 获取所有邮件标签的便捷方法
}
```

### 3. 页面实现 (`lib/pages/scheduled_email_task_create_page.dart`)

#### 状态管理
```dart
// 邮件标签数据
List<EmailTagModel> _emailTags = [];
List<EmailTagModel> _filteredEmailTags = [];
bool _isLoadingEmailTags = false;
String? _emailTagError;
bool _emailTagsLoaded = false;
bool _showEmailTagDropdown = false;
```

#### 数据加载
```dart
Future<void> _loadEmailTags() async {
  // 懒加载邮件标签数据
  // 错误处理
  // 状态更新
}
```

#### 搜索过滤
```dart
void _filterEmailTags(String query) {
  // 根据关键词过滤标签
  // 支持标签名称和描述搜索
}
```

#### UI 组件
- `_buildEmailTagField()`: 邮件标签选择器主组件
- `_buildEmailTagDropdown()`: 下拉选择器容器
- `_buildEmailTagList()`: 标签列表显示

## API 文档参考

根据 [阿里云邮件推送 API 文档](https://next.api.aliyun.com/document/Dm/2015-11-23/QueryTagByParam)：

### 请求参数
- `Action`: QueryTagByParam
- `PageNo`: 页码（必填）
- `PageSize`: 每页数量（必填）
- `KeyWord`: 关键词搜索（可选）

### 响应格式
```json
{
  "RequestId": "request_id",
  "Data": {
    "TotalCount": 10,
    "PageNo": 1,
    "PageSize": 20,
    "tag": [
      {
        "TagId": "tag_id",
        "TagName": "标签名称",
        "Description": "标签描述",
        "CreateTime": "创建时间",
        "TemplateCount": 5
      }
    ]
  }
}
```

## 使用流程

### 1. 新建任务时
1. 用户点击邮件标签字段
2. 系统自动加载邮件标签数据
3. 显示下拉选择器
4. 用户可搜索和选择标签
5. 选中后存储标签ID

### 2. 编辑任务时
1. 页面初始化时预加载邮件标签数据
2. 根据任务中的标签ID显示对应标签名称
3. 用户可重新选择标签

## 错误处理

### 1. 网络错误
- 显示错误提示
- 提供重试按钮
- 记录错误日志

### 2. 配置错误
- 检查阿里云AccessKey配置
- 提示用户先配置AccessKey

### 3. 数据解析错误
- 使用默认值处理缺失字段
- 记录解析错误日志

## 测试覆盖

### 单元测试 (`test/email_tag_test.dart`)
- 邮件标签模型解析测试
- API 响应解析测试
- 可选字段处理测试
- JSON 转换测试

## 注意事项

1. **API 限制**: 阿里云API有调用频率限制，建议实现缓存机制
2. **数据同步**: 邮件标签数据可能发生变化，需要定期刷新
3. **用户体验**: 加载状态和错误状态的友好提示
4. **性能优化**: 懒加载和搜索过滤减少不必要的API调用

## 未来改进

1. **缓存机制**: 实现邮件标签数据的本地缓存
2. **自动刷新**: 定期自动刷新标签数据
3. **批量操作**: 支持批量选择多个标签
4. **标签管理**: 添加创建、编辑、删除标签的功能 