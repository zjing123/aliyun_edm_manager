# SenderStatisticsByTagNameAndBatchID API 文档

## API 概述

**API名称**: SenderStatisticsByTagNameAndBatchID  
**功能**: 获取指定条件下的发送数据  
**版本**: 2015-11-23  
**请求方法**: GET, POST  
**安全认证**: AK (AccessKey)

## 请求参数

| 参数名 | 类型 | 必填 | 描述 | 示例 |
|--------|------|------|------|------|
| AccountName | string | 否 | 发信地址。不填，代表所有地址 | "xxx" |
| StartTime | string | 是 | 起始时间，时间不能早于30日，格式yyyy-MM-dd | "2019-09-29" |
| EndTime | string | 是 | 结束时间，和起始时间跨度不能超出7天，格式yyyy-MM-dd | "2019-09-29" |
| TagName | string | 否 | 邮件标签。不填，代表所有标签 | "xxx" |
| DedicatedIpPoolId | string | 否 | 对于独立IP用户，查询特定的独立IP池ID的数据。不填写此参数时默认查询所有数据 | "xxx" |
| DedicatedIp | string | 否 | 对于独立IP用户，查询特定的独立IP的数据。不填写此参数时默认查询所有数据 | "xxx.xxx.xxx.xxx" |
| Esp | string | 否 | 对于独立IP用户，查询特定的ESP数据的数据，可以填写的值如下：<br>- gmail.com<br>- yahoo.com<br>- outlook.com<br>- icloud.com<br>- others（对应其他的非上述ESP的数据）<br><br>不填写此参数时默认查询所有数据 | "gmail.com" |

## 响应格式

### 成功响应 (200)

```json
{
  "TotalCount": 1,
  "RequestId": "10A1AD70-E48E-476D-98D9-39BD92193837",
  "data": {
    "stat": [
      {
        "unavailablePercent": "0%",
        "CreateTime": "2025-03-02",
        "succeededPercent": "100.00%",
        "faildCount": "0",
        "unavailableCount": "0",
        "successCount": "4",
        "requestCount": "4"
      }
    ]
  }
}
```

### 响应字段说明

| 字段名 | 类型 | 描述 | 示例 |
|--------|------|------|------|
| TotalCount | integer | 总数量 | 1 |
| RequestId | string | 请求ID | "10A1AD70-E48E-476D-98D9-39BD92193837" |
| data.stat | array | 数据记录数组 | - |
| data.stat[].unavailablePercent | string | 无效率 | "0%" |
| data.stat[].CreateTime | string | 创建时间 | "2025-03-02" |
| data.stat[].succeededPercent | string | 成功率 | "100.00%" |
| data.stat[].faildCount | string | 失败数量 | "0" |
| data.stat[].unavailableCount | string | 无效数量 | "0" |
| data.stat[].successCount | string | 成功数量 | "4" |
| data.stat[].requestCount | string | 请求数量 | "4" |

## 业务规则

### 时间限制
- 起始时间不能早于30天前
- 结束时间和起始时间跨度不能超出7天
- 时间格式必须为 yyyy-MM-dd

### 数据范围
- 如果不填写 AccountName，代表查询所有发信地址的数据
- 如果不填写 TagName，代表查询所有标签的数据
- 如果不填写 DedicatedIpPoolId，默认查询所有数据
- 如果不填写 DedicatedIp，默认查询所有数据
- 如果不填写 Esp，默认查询所有数据

## 错误处理

### 常见错误
1. **时间格式错误**: 时间格式必须为 yyyy-MM-dd
2. **时间范围错误**: 起始时间不能早于30天前
3. **时间跨度错误**: 结束时间和起始时间跨度不能超出7天
4. **认证失败**: AccessKey 无效或过期
5. **权限不足**: 没有访问该API的权限

### 错误响应示例
```json
{
  "Code": "InvalidTimeRange",
  "Message": "时间范围超出限制",
  "RequestId": "10A1AD70-E48E-476D-98D9-39BD92193837"
}
```

## 使用示例

### 基本查询
```dart
// 查询最近7天的所有发送数据
final now = DateTime.now();
final sevenDaysAgo = now.subtract(const Duration(days: 7));

final statistics = await service.getSendingStatistics(
  startTime: sevenDaysAgo,
  endTime: now,
);
```

### 按发信地址查询
```dart
// 查询特定发信地址的数据
final statistics = await service.getSendingStatistics(
  accountName: "sender@example.com",
  startTime: startTime,
  endTime: endTime,
);
```

### 按标签查询
```dart
// 查询特定标签的数据
final statistics = await service.getSendingStatistics(
  tagName: "newsletter",
  startTime: startTime,
  endTime: endTime,
);
```

### 独立IP用户查询
```dart
// 查询特定独立IP池的数据
final statistics = await service.getSendingStatistics(
  dedicatedIpPoolId: "pool-123",
  startTime: startTime,
  endTime: endTime,
);

// 查询特定ESP的数据
final statistics = await service.getSendingStatistics(
  esp: "gmail.com",
  startTime: startTime,
  endTime: endTime,
);
```

## 实现注意事项

### 1. 数据解析
- 所有数量字段都是字符串类型，需要转换为整数
- 百分比字段包含 "%" 符号，需要解析为数值
- 时间字段格式为 yyyy-MM-dd

### 2. 错误处理
- 检查 API 响应状态码
- 处理网络错误和超时
- 验证响应数据格式

### 3. 性能优化
- 合理设置时间范围，避免查询过大数据量
- 考虑缓存查询结果
- 实现分页加载（如果需要）

### 4. 用户体验
- 显示加载状态
- 提供错误提示
- 支持数据刷新

## 相关API

- **SenderStatisticsDetailByParam**: 获取发送统计详情
- **GetTrackList**: 获取发送跟踪列表
- **GetTrackListByMailFromAndTagName**: 按发信地址和标签获取跟踪列表

## 更新日志

- **2025-01-27**: 基于阿里云API文档更新实现
- 添加了完整的参数支持
- 更新了数据模型以匹配API响应格式
- 实现了错误处理和验证逻辑 