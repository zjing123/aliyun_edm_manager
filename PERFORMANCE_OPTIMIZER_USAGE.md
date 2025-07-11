# PerformanceOptimizer 使用指南

## 📖 概述

PerformanceOptimizer 是一个综合性的性能优化工具类，专门为批量创建收件人列表功能设计。它提供了性能监控、动态调整、智能重试、缓存管理和内存优化等功能。

## 🚀 快速开始

### 1. 基础使用

```dart
import 'package:aliyun_edm_manager/utils/performance_optimizer.dart';

// 记录API响应时间
PerformanceOptimizer.recordResponseTime(1500); // 1.5秒

// 记录处理结果
PerformanceOptimizer.recordResult(true); // 成功
PerformanceOptimizer.recordResult(false, "网络超时"); // 失败

// 获取性能报告
final report = PerformanceOptimizer.getPerformanceReport();
print('平均响应时间: ${report['averageResponseTime']}ms');
print('成功率: ${(report['successRate'] * 100).toStringAsFixed(1)}%');
```

### 2. 动态调整配置

```dart
// 自动调整所有参数
PerformanceOptimizer.performDynamicAdjustment();

// 手动设置参数
PerformanceOptimizer.setBatchSize(250);
PerformanceOptimizer.setConcurrency(2);
PerformanceOptimizer.setInterval(200);

// 重置到推荐值
PerformanceOptimizer.resetToRecommended();
```

## 📊 性能监控

### 监控指标

```dart
// 获取当前配置
final batchSize = PerformanceOptimizer.currentBatchSize;
final concurrency = PerformanceOptimizer.currentConcurrency;
final interval = PerformanceOptimizer.currentInterval;

// 获取性能指标
final avgResponseTime = PerformanceOptimizer.getAverageResponseTime();
final successRate = PerformanceOptimizer.getSuccessRate();
final errorRate = PerformanceOptimizer.getErrorRate();

// 获取最近的错误
final recentErrors = PerformanceOptimizer.getRecentErrors();
```

### 性能报告示例

```dart
final report = PerformanceOptimizer.getPerformanceReport();
/*
{
  'averageResponseTime': 2345.6,
  'successRate': 0.92,
  'errorRate': 0.08,
  'totalRequests': 50,
  'currentBatchSize': 200,
  'currentConcurrency': 2,
  'currentInterval': 150,
  'recentErrors': ['网络超时', 'InvalidReceiverDetailMax.Malformed']
}
*/
```

## 🔄 智能重试

### 基础重试

```dart
import 'package:aliyun_edm_manager/utils/performance_optimizer.dart';

// 使用指数退避重试
final result = await RetryManager.retryWithBackoff(
  () => receiverService.saveReceiverDetails(receiverId, params),
  maxRetries: 3,
  initialDelay: Duration(milliseconds: 1000),
  operationName: '保存收件人详情',
);
```

### 智能重试策略

```dart
// 使用智能重试，根据错误类型自动调整策略
final result = await RetryManager.retryWithSmartStrategy(
  () => receiverService.saveReceiverDetails(receiverId, params),
  operationName: '批量保存收件人',
);
```

### 错误处理示例

```dart
try {
  await RetryManager.retryWithSmartStrategy(
    () => apiCall(),
    operationName: 'API调用',
  );
} catch (e) {
  if (e.toString().contains('InvalidReceiverDetailMax.Malformed')) {
    // 自动减少批量大小
    PerformanceOptimizer.adjustBatchSize();
    print('已自动减少批量大小');
  }
}
```

## 💾 缓存管理

### 基础缓存操作

```dart
// 检查邮箱是否已处理
if (!CacheManager.isProcessed('user@example.com')) {
  // 处理邮箱
  await processEmail('user@example.com');
  
  // 标记为已处理
  CacheManager.markProcessed('user@example.com');
} else {
  print('邮箱已处理，跳过');
}

// 标记处理失败
CacheManager.markFailed('invalid@example.com');
```

### 缓存统计

```dart
// 获取缓存统计
final cacheStats = CacheManager.getCacheStats();
print('缓存总数: ${cacheStats['totalCached']}');
print('成功数: ${cacheStats['successCount']}');
print('失败数: ${cacheStats['failedCount']}');
print('成功率: ${(cacheStats['successRate'] * 100).toStringAsFixed(1)}%');

// 清除缓存
CacheManager.clear();
```

## 🔧 数据预处理

### 邮箱验证

```dart
// 验证单个邮箱
final isValid = DataPreprocessor.isValidEmail('user@example.com');
print('邮箱有效: $isValid');

// 批量验证邮箱
final emails = ['user1@example.com', 'invalid-email', 'user2@example.com'];
final validationResult = DataPreprocessor.validateEmailsBatch(emails);

print('有效邮箱: ${validationResult['valid']}');
print('无效邮箱: ${validationResult['invalid']}');
print('重复邮箱: ${validationResult['duplicate']}');
```

### 数据预处理

```dart
// 完整的数据预处理
final rawEmails = [
  'user1@example.com',
  'user1@example.com', // 重复
  'invalid-email',
  'user2@example.com',
  'USER1@EXAMPLE.COM', // 大小写重复
];

final preprocessResult = DataPreprocessor.preprocessData(rawEmails);

print('预处理结果:');
print('- 有效邮箱: ${preprocessResult['validEmails'].length}个');
print('- 无效邮箱: ${preprocessResult['invalidEmails'].length}个');
print('- 重复邮箱: ${preprocessResult['duplicateEmails'].length}个');
print('- 处理时间: ${preprocessResult['statistics']['processingTime']}ms');
```

## 💾 内存管理

### 分批处理大数据

```dart
// 分批处理大量数据
final largeDataList = List.generate(10000, (index) => 'user$index@example.com');

await MemoryManager.processLargeData(
  largeDataList,
  (chunk) async {
    // 处理每个分片
    for (final email in chunk) {
      await processEmail(email);
    }
  },
  chunkSize: 500, // 自定义分片大小
  operationName: '批量处理邮箱',
);
```

### 内存清理

```dart
// 检查内存使用
MemoryManager.checkMemoryUsage();

// 强制垃圾回收
MemoryManager.forceGarbageCollection();
```

## 🎯 实际应用示例

### 在批量创建收件人页面中使用

```dart
class BatchCreateReceiverPage extends StatefulWidget {
  @override
  _BatchCreateReceiverPageState createState() => _BatchCreateReceiverPageState();
}

class _BatchCreateReceiverPageState extends State<BatchCreateReceiverPage> {
  final List<String> _emails = [];
  bool _isProcessing = false;
  
  Future<void> _processEmails() async {
    setState(() => _isProcessing = true);
    
    try {
      // 1. 数据预处理
      final preprocessResult = DataPreprocessor.preprocessData(_emails);
      final validEmails = preprocessResult['validEmails'] as List<String>;
      
      // 2. 分批处理
      await MemoryManager.processLargeData(
        validEmails,
        (chunk) async {
          // 3. 使用智能重试
          await RetryManager.retryWithSmartStrategy(
            () => _saveReceiverChunk(chunk),
            operationName: '保存收件人分片',
          );
        },
        chunkSize: PerformanceOptimizer.currentBatchSize,
      );
      
      // 4. 显示性能报告
      final report = PerformanceOptimizer.getPerformanceReport();
      _showPerformanceReport(report);
      
    } catch (e) {
      print('处理失败: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  
  Future<void> _saveReceiverChunk(List<String> emails) async {
    final startTime = DateTime.now();
    
    try {
      // 过滤已处理的邮箱
      final unprocessedEmails = emails.where(
        (email) => !CacheManager.isProcessed(email)
      ).toList();
      
      if (unprocessedEmails.isEmpty) {
        print('所有邮箱都已处理');
        return;
      }
      
      // 调用API
      final result = await receiverService.saveReceiverDetails(
        receiverId,
        unprocessedEmails.map((email) => ReceiverDetailParams(email: email)).toList(),
      );
      
      // 记录成功
      final duration = DateTime.now().difference(startTime);
      PerformanceOptimizer.recordResponseTime(duration.inMilliseconds);
      PerformanceOptimizer.recordResult(true);
      
      // 标记为已处理
      for (final email in unprocessedEmails) {
        CacheManager.markProcessed(email);
      }
      
    } catch (e) {
      // 记录失败
      final duration = DateTime.now().difference(startTime);
      PerformanceOptimizer.recordResponseTime(duration.inMilliseconds);
      PerformanceOptimizer.recordResult(false, e.toString());
      
      // 标记为处理失败
      for (final email in emails) {
        CacheManager.markFailed(email);
      }
      
      rethrow;
    }
  }
  
  void _showPerformanceReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('性能报告'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('平均响应时间: ${report['averageResponseTime'].toStringAsFixed(0)}ms'),
            Text('成功率: ${(report['successRate'] * 100).toStringAsFixed(1)}%'),
            Text('错误率: ${(report['errorRate'] * 100).toStringAsFixed(1)}%'),
            Text('总请求数: ${report['totalRequests']}'),
            Text('当前批量大小: ${report['currentBatchSize']}'),
            Text('当前并发数: ${report['currentConcurrency']}'),
            Text('当前请求间隔: ${report['currentInterval']}ms'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}
```

## ⚙️ 配置调优

### 根据网络环境调整

```dart
// 网络良好时
PerformanceOptimizer.setBatchSize(300);
PerformanceOptimizer.setConcurrency(3);
PerformanceOptimizer.setInterval(100);

// 网络一般时
PerformanceOptimizer.setBatchSize(200);
PerformanceOptimizer.setConcurrency(2);
PerformanceOptimizer.setInterval(150);

// 网络较差时
PerformanceOptimizer.setBatchSize(100);
PerformanceOptimizer.setConcurrency(1);
PerformanceOptimizer.setInterval(300);
```

### 根据数据量调整

```dart
// 小批量数据 (< 1000个)
PerformanceOptimizer.setBatchSize(200);
PerformanceOptimizer.setConcurrency(2);

// 中批量数据 (1000-5000个)
PerformanceOptimizer.setBatchSize(250);
PerformanceOptimizer.setConcurrency(2);

// 大批量数据 (> 5000个)
PerformanceOptimizer.setBatchSize(200);
PerformanceOptimizer.setConcurrency(1);
```

## 📈 性能监控和优化

### 定期性能检查

```dart
// 每处理100个请求后检查性能
if (PerformanceOptimizer.getPerformanceReport()['totalRequests'] % 100 == 0) {
  PerformanceOptimizer.performDynamicAdjustment();
  
  final report = PerformanceOptimizer.getPerformanceReport();
  if (report['errorRate'] > 0.1) {
    print('错误率过高，建议检查网络连接或减少批量大小');
  }
}
```

### 性能日志记录

```dart
// 记录详细的性能日志
void logPerformanceMetrics() {
  final report = PerformanceOptimizer.getPerformanceReport();
  final cacheStats = CacheManager.getCacheStats();
  
  print('=== 性能监控报告 ===');
  print('API性能:');
  print('- 平均响应时间: ${report['averageResponseTime'].toStringAsFixed(0)}ms');
  print('- 成功率: ${(report['successRate'] * 100).toStringAsFixed(1)}%');
  print('- 错误率: ${(report['errorRate'] * 100).toStringAsFixed(1)}%');
  print('- 总请求数: ${report['totalRequests']}');
  
  print('当前配置:');
  print('- 批量大小: ${report['currentBatchSize']}');
  print('- 并发数: ${report['currentConcurrency']}');
  print('- 请求间隔: ${report['currentInterval']}ms');
  
  print('缓存统计:');
  print('- 缓存总数: ${cacheStats['totalCached']}');
  print('- 缓存成功率: ${(cacheStats['successRate'] * 100).toStringAsFixed(1)}%');
}
```

## 🚨 注意事项

1. **API限制遵守**: 始终确保不超过阿里云API的限制
2. **内存管理**: 处理大量数据时注意内存使用
3. **错误处理**: 确保错误不会影响整体处理流程
4. **缓存清理**: 定期清理过期缓存，避免内存泄漏
5. **性能监控**: 定期检查性能指标，及时调整参数

## 📚 最佳实践

1. **渐进式优化**: 从推荐配置开始，根据实际情况逐步调整
2. **监控驱动**: 基于性能监控数据调整参数
3. **错误分类**: 根据错误类型采用不同的处理策略
4. **缓存利用**: 合理使用缓存，避免重复处理
5. **分批处理**: 大数据量时使用分批处理，避免内存溢出

通过合理使用PerformanceOptimizer，可以显著提升批量创建收件人列表的性能和稳定性。 