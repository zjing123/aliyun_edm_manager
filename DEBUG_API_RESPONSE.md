# API响应调试指南

## 问题描述

遇到错误：`type 'int' is not a subtype of type 'String'`

这个错误表明API返回的某些字段是整数类型，但我们的模型期望的是字符串类型。

## 解决方案

### 1. 数据模型修复

已更新 `SendingStatisticsModel` 和 `StatisticsRecord` 类，添加了类型转换方法：

```dart
// 整数解析方法
static int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

// 字符串解析方法
static String? _parseString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is int) return value.toString();
  if (value is double) return value.toString();
  return value.toString();
}
```

### 2. 调试信息增强

在服务类中添加了详细的调试信息：

```dart
print('发送统计API请求参数: $params');
print('发送统计API响应: ${response.data}');
print('数据模型解析错误: $e');
print('响应数据结构: $responseData');
```

### 3. 错误处理改进

- 添加了时间范围验证
- 增强了异常捕获
- 提供了详细的错误信息

## 调试步骤

### 1. 检查API响应

运行应用后，查看控制台输出：

```
发送统计API请求参数: {StartTime: 2025-01-20, EndTime: 2025-01-27}
发送统计API响应: {...}
```

### 2. 分析响应结构

如果API响应格式与预期不符，请检查：

- 响应是否为有效的JSON格式
- 字段名称是否正确
- 数据类型是否匹配

### 3. 常见问题

#### 问题1: API返回空数据
```
响应: {"TotalCount": 0, "RequestId": "...", "data": {"stat": []}}
```
**解决方案**: 这是正常情况，表示指定时间范围内没有发送数据。

#### 问题2: 字段类型不匹配
```
错误: type 'int' is not a subtype of type 'String'
```
**解决方案**: 已通过类型转换方法解决。

#### 问题3: 时间格式错误
```
错误: 时间格式必须为 yyyy-MM-dd
```
**解决方案**: 确保传入的时间格式正确。

## 测试建议

### 1. 使用有效的时间范围

```dart
final now = DateTime.now();
final sevenDaysAgo = now.subtract(const Duration(days: 7));

await service.getSendingStatistics(
  startTime: sevenDaysAgo,
  endTime: now,
);
```

### 2. 检查阿里云配置

确保：
- AccessKey ID 和 Secret 已正确配置
- 有阿里云EDM服务的访问权限
- 网络连接正常

### 3. 验证API权限

确认阿里云账户有调用 `SenderStatisticsByTagNameAndBatchID` API的权限。

## 故障排除

### 如果仍然遇到问题：

1. **检查网络连接**
   ```bash
   curl -I https://dm.aliyuncs.com
   ```

2. **验证AccessKey**
   - 在阿里云控制台检查AccessKey是否有效
   - 确认AccessKey有EDM服务权限

3. **查看详细日志**
   - 运行应用时查看完整的控制台输出
   - 检查是否有其他错误信息

4. **测试API调用**
   ```bash
   # 使用curl测试API（需要签名）
   curl -X GET "https://dm.aliyuncs.com/?Action=SenderStatisticsByTagNameAndBatchID&StartTime=2025-01-20&EndTime=2025-01-27&Version=2015-11-23"
   ```

## 预期结果

修复后，应用应该能够：

1. ✅ 成功调用API
2. ✅ 正确解析响应数据
3. ✅ 显示统计信息
4. ✅ 处理空数据情况
5. ✅ 提供友好的错误提示

## 更新日志

- **2025-01-27**: 修复数据类型转换问题
  - 添加了类型转换方法
  - 增强了错误处理
  - 添加了调试信息
  - 改进了异常捕获机制 