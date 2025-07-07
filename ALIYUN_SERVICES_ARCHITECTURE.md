# 阿里云服务架构重构说明

## 概述

为了更好的代码维护和功能扩展，我们将原来的单一 `AliyunEdmService` 类按功能拆分成多个独立的服务模块。

## 新的服务架构

### 目录结构
```
lib/services/aliyun/
├── base_aliyun_service.dart          # 基础服务类
├── aliyun_service_manager.dart       # 服务管理器
├── aliyun_services.dart              # 统一导出文件
├── receiver_service.dart             # 收件人管理服务
├── template_service.dart             # 模板管理服务
├── sender_address_service.dart       # 发信地址管理服务
├── email_tag_service.dart            # 邮件标签管理服务
├── mail_task_service.dart            # 邮件任务管理服务
└── scheduled_email_service.dart      # 定时发送邮件服务
```

### 服务模块说明

#### 1. BaseAliyunService (基础服务类)
- **功能**: 提供所有阿里云服务的通用功能
- **包含**: 
  - 配置管理
  - API请求封装
  - 参数验证
  - 错误处理
  - 日志记录

#### 2. AliyunServiceManager (服务管理器)
- **功能**: 统一管理所有子服务
- **特点**:
  - 单例模式
  - 统一初始化
  - 便捷访问接口
  - 配置同步

#### 3. ReceiverService (收件人管理服务)
- **API**: 
  - `QueryReceiverByParam` - 查询收件人列表
  - `CreateReceiver` - 创建收件人列表
  - `DeleteReceiver` - 删除收件人列表
  - `QueryReceiverDetail` - 查询收件人详情
  - `SaveReceiverDetail` - 保存收件人详情
  - `DeleteReceiverDetail` - 删除收件人详情

#### 4. TemplateService (模板管理服务)
- **API**:
  - `QueryTemplateByParam` - 查询邮件模板
- **功能**:
  - 获取可用模板
  - 模板状态过滤

#### 5. SenderAddressService (发信地址管理服务)
- **API**:
  - `QueryMailAddressByParam` - 查询发信地址
- **功能**:
  - 获取可用发信地址
  - 地址状态过滤

#### 6. EmailTagService (邮件标签管理服务)
- **API**:
  - `QueryTagByParam` - 查询邮件标签
- **功能**:
  - 获取所有邮件标签
  - 标签搜索

#### 7. MailTaskService (邮件任务管理服务)
- **API**:
  - `QueryTaskByParam` - 查询邮件任务
- **功能**:
  - 获取所有邮件任务
  - 按状态过滤任务

#### 8. ScheduledEmailService (定时发送邮件服务)
- **API**:
  - `CreateScheduledEmailTask` - 创建定时发送邮件任务
  - `QueryScheduledEmailTaskByParam` - 查询定时发送邮件任务
  - `DeleteScheduledEmailTask` - 删除定时发送邮件任务
  - `CancelScheduledEmailTask` - 取消定时发送邮件任务

## 使用方式

### 1. 初始化服务管理器
```dart
// 在应用启动时初始化
final serviceManager = AliyunServiceManager();
serviceManager.initialize(globalConfigProvider);
```

### 2. 使用具体服务
```dart
// 获取收件人列表
final receivers = await serviceManager.receiverService.queryReceivers();

// 获取邮件模板
final templates = await serviceManager.templateService.getAvailableTemplates();

// 获取发信地址
final addresses = await serviceManager.senderAddressService.getAvailableSenderAddresses();

// 获取邮件标签
final tags = await serviceManager.emailTagService.getAvailableEmailTags();

// 创建定时发送邮件任务
final result = await serviceManager.scheduledEmailService.createScheduledEmailTask(
  receiversName: 'test_receivers',
  templateName: 'test_template',
  // ... 其他参数
);
```

### 3. 统一导入
```dart
import 'package:your_app/services/aliyun/aliyun_services.dart';

// 直接使用服务管理器
final serviceManager = AliyunServiceManager();
```

## 优势

### 1. 模块化设计
- 每个服务专注于特定功能
- 代码职责清晰
- 便于维护和测试

### 2. 可扩展性
- 新增功能只需添加新的服务模块
- 不影响现有服务
- 支持独立开发和测试

### 3. 代码复用
- 通用功能在基础服务中实现
- 减少重复代码
- 统一错误处理和日志

### 4. 配置管理
- 统一的配置管理
- 支持动态配置更新
- 配置验证和错误处理

### 5. 类型安全
- 每个服务都有明确的类型定义
- 编译时错误检查
- 更好的IDE支持

## 迁移指南

### 从旧服务迁移到新服务

#### 1. 更新导入
```dart
// 旧方式
import 'package:your_app/services/aliyun_edm_service.dart';

// 新方式
import 'package:your_app/services/aliyun/aliyun_services.dart';
```

#### 2. 更新服务调用
```dart
// 旧方式
final aliyunService = AliyunEdmService();
aliyunService.setGlobalConfigProvider(globalConfigProvider);
final receivers = await aliyunService.queryReceivers();

// 新方式
final serviceManager = AliyunServiceManager();
serviceManager.initialize(globalConfigProvider);
final receivers = await serviceManager.receiverService.queryReceivers();
```

#### 3. 更新Provider
```dart
// 在Provider中使用新服务
class YourProvider extends ChangeNotifier {
  late final AliyunServiceManager _serviceManager;
  
  void initialize(GlobalConfigProvider globalConfigProvider) {
    _serviceManager = AliyunServiceManager();
    _serviceManager.initialize(globalConfigProvider);
  }
  
  Future<void> loadData() async {
    final receivers = await _serviceManager.receiverService.queryReceivers();
    // 处理数据...
  }
}
```

## 注意事项

1. **初始化顺序**: 必须先初始化服务管理器，再使用具体服务
2. **配置同步**: 当全局配置更新时，需要调用 `updateGlobalConfigProvider`
3. **错误处理**: 所有服务都继承自基础服务，具有统一的错误处理机制
4. **类型安全**: 使用强类型定义，避免运行时错误

## 未来扩展

1. **新增服务模块**: 可以轻松添加新的功能服务
2. **中间件支持**: 可以在基础服务中添加中间件功能
3. **缓存机制**: 可以在服务管理器中添加缓存功能
4. **监控和统计**: 可以添加API调用监控和统计功能 