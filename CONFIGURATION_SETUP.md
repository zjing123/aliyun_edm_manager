# 阿里云EDM管理器 - 配置系统实现

## 概述

我已经为您的阿里云EDM管理器添加了完整的配置系统，允许用户通过图形界面安全地管理AccessKey ID和Access Key Secret。

## 新增功能

### 1. 配置服务 (`lib/services/config_service.dart`)
- 使用SharedPreferences安全存储AccessKey信息
- 提供配置的读取、保存、验证和清除功能
- 单例模式确保配置的一致性

### 2. 配置页面 (`lib/pages/config_page.dart`)
- 用户友好的配置界面
- AccessKey ID和Secret的输入和验证
- 密码字段的显示/隐藏切换
- 保存和清除配置功能
- 内置帮助说明

### 3. 更新的EDM服务 (`lib/services/aliyun_edm_service.dart`)
- 移除了硬编码的AccessKey
- 从配置服务动态获取认证信息
- 提供配置检查功能
- 优雅的错误处理

### 4. 增强的主界面 (`lib/pages/receiver_list_page.dart`)
- 新增设置按钮访问配置页面
- 配置缺失时的友好提示界面
- 改进的错误处理和用户反馈

## 新增依赖

在 `pubspec.yaml` 中添加了：
```yaml
shared_preferences: ^2.2.2
```

## 使用步骤

### 1. 安装依赖
```bash
flutter pub get
```

### 2. 运行应用
```bash
flutter run
```

### 3. 配置AccessKey
1. 打开应用后，点击右上角的设置图标 ⚙️
2. 输入您的阿里云Access Key ID和Access Key Secret
3. 点击"保存配置"
4. 返回主界面即可正常使用EDM功能

## 获取阿里云AccessKey

1. 登录[阿里云控制台](https://ecs.console.aliyun.com)
2. 点击右上角头像，选择"AccessKey管理" 
3. 创建新的AccessKey或查看现有AccessKey
4. 复制Access Key ID和Access Key Secret到应用中

## 安全特性

- ✅ 本地安全存储，不会泄露到网络
- ✅ 密码字段自动隐藏
- ✅ 输入验证防止无效配置
- ✅ 清除功能方便更换密钥
- ✅ 配置缺失时的友好提示

## 文件结构

```
lib/
├── services/
│   ├── config_service.dart          # 配置管理服务
│   └── aliyun_edm_service.dart      # 更新的EDM服务
├── pages/
│   ├── config_page.dart             # 配置页面
│   └── receiver_list_page.dart      # 更新的主页面
└── ...
```

## 主要改进

1. **安全性提升**: 移除硬编码密钥，采用本地安全存储
2. **用户体验**: 图形化配置界面，无需手动编辑代码
3. **错误处理**: 配置缺失时的友好提示和引导
4. **灵活性**: 支持运行时修改配置，无需重新编译

## 注意事项

- 首次使用需要先配置AccessKey才能正常使用EDM功能
- AccessKey信息仅存储在本地设备，不会上传到任何服务器
- 建议定期更换AccessKey以确保账户安全
- 如需更换AccessKey，可通过设置页面直接修改

## 故障排除

### 问题：提示"Access Key未配置"
**解决**：点击右上角设置按钮，输入正确的AccessKey信息

### 问题：API调用失败
**解决**：检查AccessKey是否正确，是否有EDM服务权限

### 问题：配置无法保存
**解决**：检查输入格式是否正确，AccessKey ID不少于10位，Secret不少于20位

---

现在您的阿里云EDM管理器已经具备完整的配置管理功能！🎉