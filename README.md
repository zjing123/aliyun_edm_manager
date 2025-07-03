# 阿里云EDM收件人管理器

一个基于Flutter开发的阿里云邮件推送(DirectMail)收件人管理工具，提供可视化的收件人列表管理功能。

## 📋 功能特性

### 🎯 核心功能
- **收件人列表查看**：展示所有收件人列表，支持分页加载
- **收件人详情管理**：查看、添加、删除收件人详情
- **智能搜索**：支持按Email地址搜索收件人
- **实时验证**：Email格式实时验证，防止无效数据
- **批量操作**：支持加载更多数据，优化大量数据展示

### 🛡️ 数据验证
- **Email格式验证**：使用正则表达式验证Email格式
- **重复检查**：防止添加重复的Email地址
- **输入验证**：实时显示输入错误和验证状态

### 🎨 用户体验
- **响应式设计**：支持桌面和Web平台
- **实时反馈**：操作结果即时显示
- **友好提示**：详细的错误信息和成功提示
- **表格展示**：清晰的数据表格，支持滚动和固定表头

## 🚀 技术栈

- **框架**：Flutter 3.x
- **语言**：Dart
- **HTTP客户端**：Dio
- **加密**：crypto (HMAC-SHA1签名)
- **日期处理**：intl
- **平台支持**：Web、Linux、Windows、macOS

## 📦 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 应用主体
├── models/                   # 数据模型
│   └── receiver_detail.dart  # 收件人详情模型
├── pages/                    # 页面
│   └── receiver_list_page.dart # 收件人列表页面
├── services/                 # 服务层
│   └── aliyun_edm_service.dart # 阿里云EDM API服务
└── utils/                    # 工具类
    ├── aliyun_signer.dart    # 阿里云API签名工具
    └── dialog_util.dart     # 对话框工具
```

## 🔧 配置说明

### 阿里云配置
在 `lib/services/aliyun_edm_service.dart` 中配置您的阿里云凭证：

```dart
final String accessKeyId = 'YOUR_ACCESS_KEY_ID';
final String accessKeySecret = 'YOUR_ACCESS_KEY_SECRET';
```

### 字段配置
在 `lib/models/receiver_detail.dart` 中自定义收件人字段：

```dart
static const List<ReceiverField> fields = [
  ReceiverField(field: 'UserName', label: '姓名', apiKey: 'u'),
  ReceiverField(field: 'NickName', label: '昵称', apiKey: 'n'),
  ReceiverField(field: 'Gender', label: '性别', apiKey: 'g'),
  ReceiverField(field: 'Birthday', label: '生日', apiKey: 'b'),
  ReceiverField(field: 'Mobile', label: '手机号', apiKey: 'm'),
];
```

## 🛠️ 安装和使用

### 前置要求
- Flutter SDK 3.0+
- Dart SDK 3.0+
- 阿里云账号和EDM服务

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/YOUR_USERNAME/aliyun_edm_manager.git
cd aliyun_edm_manager
```

2. **安装依赖**
```bash
flutter pub get
```

3. **配置阿里云凭证**
编辑 `lib/services/aliyun_edm_service.dart`，填入您的AccessKey信息

4. **运行应用**
```bash
# Web平台
flutter run -d chrome

# Linux桌面
flutter run -d linux

# Windows桌面
flutter run -d windows
```

## 📱 使用说明

### 主要操作

1. **查看收件人列表**
   - 启动应用后自动加载收件人列表
   - 点击列表项查看详细信息

2. **管理收件人详情**
   - 点击"详情"按钮打开收件人管理对话框
   - 使用搜索框按Email地址筛选
   - 点击"新建"添加收件人
   - 点击"删除"移除收件人

3. **添加新收件人**
   - 填写Email地址（必填）
   - 填写其他可选字段
   - 系统会自动验证Email格式
   - 成功后新收件人会显示在列表顶部

## 🔐 API签名机制

项目实现了完整的阿里云API签名验证：
- 支持GET、POST、DELETE等HTTP方法
- HMAC-SHA1加密算法
- 标准的阿里云API签名流程
- 自动处理URL编码和特殊字符

## 🐛 问题排查

### 常见问题

1. **签名验证失败**
   - 检查AccessKey和Secret是否正确
   - 确认系统时间准确
   - 验证API参数格式

2. **网络请求失败**
   - 检查网络连接
   - 确认阿里云服务状态
   - 查看控制台错误日志

3. **数据显示异常**
   - 检查API响应格式
   - 确认数据模型映射
   - 查看Flutter调试信息

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 📞 联系方式

如有问题或建议，请通过以下方式联系：
- 提交GitHub Issue
- 发送邮件至项目维护者

---

**注意**：使用前请确保已正确配置阿里云凭证，并且拥有相应的EDM服务权限。
