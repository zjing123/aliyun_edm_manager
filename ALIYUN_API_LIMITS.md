# 阿里云邮件服务API限制说明

## SaveReceiverDetail API限制

### 主要限制
- **单次请求最多500个收件人**：这是阿里云API的硬性限制
- **请求频率限制**：每分钟最多100次请求
- **数据大小限制**：单次请求的JSON数据不能超过1MB

### 影响分析

#### 1. 批量大小限制
```dart
// 正确的批量大小配置
final batchSize = 500; // 符合API限制
final emailChunks = _chunkEmails(emails, batchSize);
```

#### 2. 请求频率控制
```dart
// 添加请求间隔，避免触发频率限制
await Future.delayed(Duration(milliseconds: 100));
```

#### 3. 数据大小控制
```dart
// 监控JSON数据大小
final detailJson = ReceiverDetailParams.toBatchDetailJson(receiverParamsList);
if (detailJson.length > 1024 * 1024) { // 1MB限制
  throw Exception('数据大小超过1MB限制');
}
```

## 优化策略

### 1. 批量大小优化
- **默认批量大小**：500个（符合API限制）
- **可选配置**：200、300、500个
- **建议**：根据网络状况选择，网络好时用500，网络差时用200-300

### 2. 并发控制
- **最大并发数**：3个（避免触发频率限制）
- **请求间隔**：100毫秒
- **错误重试**：失败时自动重试

### 3. 数据分片
```dart
// 智能分片策略
List<List<String>> _chunkEmails(List<String> emails, int chunkSize) {
  final chunks = <List<String>>[];
  for (int i = 0; i < emails.length; i += chunkSize) {
    final end = (i + chunkSize < emails.length) ? i + chunkSize : emails.length;
    chunks.add(emails.sublist(i, end));
  }
  return chunks;
}
```

## 错误处理

### 1. 频率限制错误
```dart
if (error.message.contains('Throttling')) {
  // 等待后重试
  await Future.delayed(Duration(seconds: 2));
  return await retryRequest();
}
```

### 2. 数据大小错误
```dart
if (error.message.contains('InvalidParameter')) {
  // 减少批量大小重试
  final smallerBatch = (batchSize * 0.8).round();
  return await processWithBatchSize(smallerBatch);
}
```

### 3. 网络超时错误
```dart
if (error is DioException && error.type == DioExceptionType.connectionTimeout) {
  // 增加超时时间重试
  return await retryWithLongerTimeout();
}
```

## 最佳实践

### 1. 批量大小选择
- **小数据量（<1000个）**：使用500个批量
- **中等数据量（1000-5000个）**：使用500个批量，启用并发
- **大数据量（>5000个）**：使用500个批量，3个并发

### 2. 网络环境适配
- **网络良好**：500个批量，3个并发
- **网络一般**：300个批量，2个并发
- **网络较差**：200个批量，1个并发

### 3. 监控和调优
```dart
// 性能监控
final startTime = DateTime.now();
final performanceLog = <String, Duration>{};

// 记录每个批次的处理时间
performanceLog['批次${i + 1}'] = DateTime.now().difference(batchStartTime);

// 输出性能报告
debugPrint('=== 性能监控报告 ===');
debugPrint('总耗时: ${totalTime.inSeconds}秒');
debugPrint('平均每批次: ${totalTime.inMilliseconds / emailBatches.length}毫秒');
```

## 限制说明

### 1. API限制
- **单次请求最多500个收件人**：这是阿里云的限制，无法绕过
- **请求频率限制**：每分钟最多100次请求
- **数据大小限制**：单次请求不能超过1MB

### 2. 性能优化空间
- **并发处理**：可以同时发送多个请求
- **网络优化**：减少连接建立时间
- **错误重试**：自动处理临时错误
- **智能分片**：根据数据量自动分片

### 3. 用户配置
- **批量大小**：200、300、500个（用户可配置）
- **并发数量**：1、2、3、5个（用户可配置）
- **性能模式**：开关控制是否使用并发

## 总结

虽然阿里云API有500个收件人的限制，但通过以下优化仍然可以显著提升性能：

✅ **并发处理**：同时发送多个请求
✅ **网络优化**：减少连接建立时间
✅ **智能分片**：自动处理大数据量
✅ **错误重试**：提高成功率
✅ **用户配置**：根据网络环境调整参数

这些优化可以在遵守API限制的前提下，最大程度地提升批量保存的性能！ 