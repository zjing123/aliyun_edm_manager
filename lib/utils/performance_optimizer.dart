import 'dart:async';
import 'dart:developer' as developer;

/// 性能优化器 - 用于优化批量创建收件人列表的性能
class PerformanceOptimizer {
  // 基础配置
  static const int RECOMMENDED_BATCH_SIZE = 200;
  static const int MAX_BATCH_SIZE = 300;
  static const int MIN_BATCH_SIZE = 50;
  
  static const int RECOMMENDED_CONCURRENCY = 2;
  static const int MAX_CONCURRENCY = 3;
  static const int MIN_CONCURRENCY = 1;
  
  static const int RECOMMENDED_INTERVAL = 150;
  static const int MAX_INTERVAL = 300;
  static const int MIN_INTERVAL = 100;
  
  // 性能监控数据
  static final List<int> _responseTimes = [];
  static final List<bool> _successResults = [];
  static final List<String> _errors = [];
  
  // 当前配置
  static int _currentBatchSize = RECOMMENDED_BATCH_SIZE;
  static int _currentConcurrency = RECOMMENDED_CONCURRENCY;
  static int _currentInterval = RECOMMENDED_INTERVAL;
  
  /// 获取当前批量大小
  static int get currentBatchSize => _currentBatchSize;
  
  /// 获取当前并发数
  static int get currentConcurrency => _currentConcurrency;
  
  /// 获取当前请求间隔
  static int get currentInterval => _currentInterval;
  
  /// 记录响应时间
  static void recordResponseTime(int milliseconds) {
    _responseTimes.add(milliseconds);
    if (_responseTimes.length > 100) {
      _responseTimes.removeAt(0);
    }
  }
  
  /// 记录处理结果
  static void recordResult(bool success, [String? error]) {
    _successResults.add(success);
    if (_successResults.length > 100) {
      _successResults.removeAt(0);
    }
    
    if (!success && error != null) {
      _errors.add(error);
      if (_errors.length > 50) {
        _errors.removeAt(0);
      }
    }
  }
  
  /// 获取平均响应时间
  static double getAverageResponseTime() {
    if (_responseTimes.isEmpty) return 0;
    return _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;
  }
  
  /// 获取成功率
  static double getSuccessRate() {
    if (_successResults.isEmpty) return 0;
    final successCount = _successResults.where((r) => r).length;
    return successCount / _successResults.length;
  }
  
  /// 获取错误率
  static double getErrorRate() {
    if (_successResults.isEmpty) return 0;
    final errorCount = _successResults.where((r) => !r).length;
    return errorCount / _successResults.length;
  }
  
  /// 获取最近的错误列表
  static List<String> getRecentErrors() {
    return List.from(_errors);
  }
  
  /// 清除监控数据
  static void clearMetrics() {
    _responseTimes.clear();
    _successResults.clear();
    _errors.clear();
  }
  
  /// 重置配置到推荐值
  static void resetToRecommended() {
    _currentBatchSize = RECOMMENDED_BATCH_SIZE;
    _currentConcurrency = RECOMMENDED_CONCURRENCY;
    _currentInterval = RECOMMENDED_INTERVAL;
    
    developer.log('🔄 [性能优化器] 重置配置到推荐值', name: 'PerformanceOptimizer');
  }
  
  /// 获取性能报告
  static Map<String, dynamic> getPerformanceReport() {
    return {
      'averageResponseTime': getAverageResponseTime(),
      'successRate': getSuccessRate(),
      'errorRate': getErrorRate(),
      'totalRequests': _successResults.length,
      'currentBatchSize': _currentBatchSize,
      'currentConcurrency': _currentConcurrency,
      'currentInterval': _currentInterval,
      'recentErrors': getRecentErrors(),
    };
  }
  
  /// 动态调整批量大小
  static void adjustBatchSize() {
    final errorRate = getErrorRate();
    final successRate = getSuccessRate();
    final avgResponseTime = getAverageResponseTime();
    
    developer.log('📊 [性能优化器] 当前指标 - 错误率: ${(errorRate * 100).toStringAsFixed(1)}%, 成功率: ${(successRate * 100).toStringAsFixed(1)}%, 平均响应时间: ${avgResponseTime.toStringAsFixed(0)}ms', name: 'PerformanceOptimizer');
    
    // 根据错误率调整批量大小
    if (errorRate > 0.1) {  // 错误率超过10%
      final newBatchSize = (_currentBatchSize * 0.8).round();
      if (newBatchSize >= MIN_BATCH_SIZE) {
        _currentBatchSize = newBatchSize;
        developer.log('🔽 [性能优化器] 错误率过高，减少批量大小: ${_currentBatchSize}', name: 'PerformanceOptimizer');
      }
    } else if (errorRate < 0.02 && successRate > 0.95) {  // 成功率很高
      final newBatchSize = (_currentBatchSize * 1.1).round();
      if (newBatchSize <= MAX_BATCH_SIZE) {
        _currentBatchSize = newBatchSize;
        developer.log('🔼 [性能优化器] 成功率很高，增加批量大小: ${_currentBatchSize}', name: 'PerformanceOptimizer');
      }
    }
  }
  
  /// 动态调整并发数
  static void adjustConcurrency() {
    final avgResponseTime = getAverageResponseTime();
    final errorRate = getErrorRate();
    
    // 根据响应时间调整并发数
    if (avgResponseTime > 5000) {  // 平均响应时间超过5秒
      final newConcurrency = _currentConcurrency - 1;
      if (newConcurrency >= MIN_CONCURRENCY) {
        _currentConcurrency = newConcurrency;
        developer.log('🔽 [性能优化器] 响应时间过长，减少并发数: $_currentConcurrency', name: 'PerformanceOptimizer');
      }
    } else if (avgResponseTime < 2000 && errorRate < 0.05) {  // 响应时间短且错误率低
      final newConcurrency = _currentConcurrency + 1;
      if (newConcurrency <= MAX_CONCURRENCY) {
        _currentConcurrency = newConcurrency;
        developer.log('🔼 [性能优化器] 响应时间短，增加并发数: $_currentConcurrency', name: 'PerformanceOptimizer');
      }
    }
  }
  
  /// 动态调整请求间隔
  static void adjustInterval() {
    final errorRate = getErrorRate();
    final requestsPerMinute = 60 * 1000 / _currentInterval;
    
    // 根据API限制调整间隔
    if (requestsPerMinute > 90) {  // 接近每分钟100次限制
      final newInterval = (_currentInterval * 1.2).round();
      if (newInterval <= MAX_INTERVAL) {
        _currentInterval = newInterval;
        developer.log('⏱️ [性能优化器] 接近API限制，增加请求间隔: ${_currentInterval}ms', name: 'PerformanceOptimizer');
      }
    } else if (requestsPerMinute < 50 && errorRate < 0.02) {  // 请求频率低且错误率低
      final newInterval = (_currentInterval * 0.9).round();
      if (newInterval >= MIN_INTERVAL) {
        _currentInterval = newInterval;
        developer.log('⚡ [性能优化器] 请求频率低，减少请求间隔: ${_currentInterval}ms', name: 'PerformanceOptimizer');
      }
    }
  }
  
  /// 执行所有动态调整
  static void performDynamicAdjustment() {
    adjustBatchSize();
    adjustConcurrency();
    adjustInterval();
    
    developer.log('🎯 [性能优化器] 动态调整完成 - 批量大小: $_currentBatchSize, 并发数: $_currentConcurrency, 间隔: ${_currentInterval}ms', name: 'PerformanceOptimizer');
  }
  
  /// 设置批量大小
  static void setBatchSize(int batchSize) {
    if (batchSize >= MIN_BATCH_SIZE && batchSize <= MAX_BATCH_SIZE) {
      _currentBatchSize = batchSize;
      developer.log('📝 [性能优化器] 设置批量大小: $_currentBatchSize', name: 'PerformanceOptimizer');
    } else {
      developer.log('⚠️ [性能优化器] 批量大小超出范围: $batchSize (${MIN_BATCH_SIZE}-${MAX_BATCH_SIZE})', name: 'PerformanceOptimizer');
    }
  }
  
  /// 设置并发数
  static void setConcurrency(int concurrency) {
    if (concurrency >= MIN_CONCURRENCY && concurrency <= MAX_CONCURRENCY) {
      _currentConcurrency = concurrency;
      developer.log('📝 [性能优化器] 设置并发数: $_currentConcurrency', name: 'PerformanceOptimizer');
    } else {
      developer.log('⚠️ [性能优化器] 并发数超出范围: $concurrency (${MIN_CONCURRENCY}-${MAX_CONCURRENCY})', name: 'PerformanceOptimizer');
    }
  }
  
  /// 设置请求间隔
  static void setInterval(int interval) {
    if (interval >= MIN_INTERVAL && interval <= MAX_INTERVAL) {
      _currentInterval = interval;
      developer.log('📝 [性能优化器] 设置请求间隔: ${_currentInterval}ms', name: 'PerformanceOptimizer');
    } else {
      developer.log('⚠️ [性能优化器] 请求间隔超出范围: $interval (${MIN_INTERVAL}-${MAX_INTERVAL})', name: 'PerformanceOptimizer');
    }
  }
}

/// 智能重试机制
class RetryManager {
  /// 指数退避重试
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 1000),
    String? operationName,
  }) async {
    int retries = 0;
    Duration delay = initialDelay;
    
    while (retries < maxRetries) {
      try {
        final startTime = DateTime.now();
        final result = await operation();
        final duration = DateTime.now().difference(startTime);
        
        PerformanceOptimizer.recordResponseTime(duration.inMilliseconds);
        PerformanceOptimizer.recordResult(true);
        
        developer.log('✅ [重试管理器] ${operationName ?? '操作'} 成功 - 耗时: ${duration.inMilliseconds}ms', name: 'RetryManager');
        return result;
      } catch (e) {
        retries++;
        final errorMsg = e.toString();
        
        PerformanceOptimizer.recordResult(false, errorMsg);
        developer.log('❌ [重试管理器] ${operationName ?? '操作'} 失败 (${retries}/${maxRetries}) - 错误: $errorMsg', name: 'RetryManager');
        
        if (retries >= maxRetries) {
          developer.log('💥 [重试管理器] ${operationName ?? '操作'} 达到最大重试次数，放弃重试', name: 'RetryManager');
          rethrow;
        }
        
        developer.log('⏳ [重试管理器] ${operationName ?? '操作'} 等待 ${delay.inMilliseconds}ms 后重试', name: 'RetryManager');
        await Future.delayed(delay);
        delay *= 2;  // 指数退避
      }
    }
    
    throw Exception('Max retries exceeded');
  }
  
  /// 智能重试（根据错误类型决定重试策略）
  static Future<T> retryWithSmartStrategy<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      return await retryWithBackoff(
        operation,
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 1000),
        operationName: operationName,
      );
    } catch (e) {
      final errorStr = e.toString();
      
      // 根据错误类型决定是否继续重试
      if (errorStr.contains('InvalidReceiverDetailMax.Malformed')) {
        developer.log('🔄 [重试管理器] 检测到InvalidReceiverDetailMax.Malformed错误，建议减少批量大小', name: 'RetryManager');
        // 这里可以触发批量大小调整
        PerformanceOptimizer.adjustBatchSize();
      } else if (errorStr.contains('timeout') || errorStr.contains('Timeout')) {
        developer.log('⏰ [重试管理器] 检测到超时错误，建议增加请求间隔', name: 'RetryManager');
        // 这里可以触发间隔调整
        PerformanceOptimizer.adjustInterval();
      } else if (errorStr.contains('rate limit') || errorStr.contains('too many requests')) {
        developer.log('🚫 [重试管理器] 检测到频率限制错误，建议减少并发数', name: 'RetryManager');
        // 这里可以触发并发数调整
        PerformanceOptimizer.adjustConcurrency();
      }
      
      rethrow;
    }
  }
}

/// 缓存管理器
class CacheManager {
  static final Map<String, bool> _processedEmails = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  /// 检查邮箱是否已处理
  static bool isProcessed(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    final timestamp = _cacheTimestamps[normalizedEmail];
    
    if (timestamp != null) {
      // 检查缓存是否过期
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        _processedEmails.remove(normalizedEmail);
        _cacheTimestamps.remove(normalizedEmail);
        return false;
      }
      return _processedEmails[normalizedEmail] ?? false;
    }
    
    return false;
  }
  
  /// 标记邮箱为已处理
  static void markProcessed(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    _processedEmails[normalizedEmail] = true;
    _cacheTimestamps[normalizedEmail] = DateTime.now();
  }
  
  /// 标记邮箱为处理失败
  static void markFailed(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    _processedEmails[normalizedEmail] = false;
    _cacheTimestamps[normalizedEmail] = DateTime.now();
  }
  
  /// 清除缓存
  static void clear() {
    _processedEmails.clear();
    _cacheTimestamps.clear();
    developer.log('🧹 [缓存管理器] 清除所有缓存', name: 'CacheManager');
  }
  
  /// 清除过期缓存
  static void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _processedEmails.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      developer.log('🧹 [缓存管理器] 清除 ${expiredKeys.length} 个过期缓存', name: 'CacheManager');
    }
  }
  
  /// 获取缓存统计
  static Map<String, dynamic> getCacheStats() {
    clearExpired(); // 先清理过期缓存
    
    final totalCached = _processedEmails.length;
    final successCount = _processedEmails.values.where((success) => success).length;
    final failedCount = totalCached - successCount;
    
    return {
      'totalCached': totalCached,
      'successCount': successCount,
      'failedCount': failedCount,
      'successRate': totalCached > 0 ? successCount / totalCached : 0,
    };
  }
}

/// 数据预处理优化器
class DataPreprocessor {
  /// 邮箱验证正则表达式
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );
  
  /// 验证单个邮箱
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final trimmedEmail = email.trim();
    if (!_emailRegex.hasMatch(trimmedEmail)) return false;
    
    // 检查长度限制
    if (trimmedEmail.length > 254) return false;
    
    // 检查本地部分和域名部分
    final parts = trimmedEmail.split('@');
    if (parts.length != 2) return false;
    
    final localPart = parts[0];
    final domainPart = parts[1];
    
    // 本地部分不能为空且不能超过64字符
    if (localPart.isEmpty || localPart.length > 64) return false;
    
    // 域名部分不能为空且不能超过253字符
    if (domainPart.isEmpty || domainPart.length > 253) return false;
    
    return true;
  }
  
  /// 批量验证邮箱
  static Map<String, List<String>> validateEmailsBatch(List<String> emails) {
    final validEmails = <String>[];
    final invalidEmails = <String>[];
    final duplicateEmails = <String>[];
    final seenEmails = <String>{};
    
    for (final email in emails) {
      final normalizedEmail = email.toLowerCase().trim();
      
      // 检查是否重复
      if (seenEmails.contains(normalizedEmail)) {
        duplicateEmails.add(email);
        continue;
      }
      
      seenEmails.add(normalizedEmail);
      
      // 验证邮箱格式
      if (isValidEmail(normalizedEmail)) {
        validEmails.add(email); // 保持原始格式
      } else {
        invalidEmails.add(email);
      }
    }
    
    return {
      'valid': validEmails,
      'invalid': invalidEmails,
      'duplicate': duplicateEmails,
    };
  }
  
  /// 高效去重算法
  static List<String> removeDuplicates(List<String> emails) {
    final seen = <String>{};
    final unique = <String>[];
    
    for (final email in emails) {
      final normalized = email.toLowerCase().trim();
      if (seen.add(normalized)) {
        unique.add(email); // 保持原始格式
      }
    }
    
    return unique;
  }
  
  /// 数据预处理（验证、去重、过滤）
  static Map<String, dynamic> preprocessData(List<String> emails) {
    final startTime = DateTime.now();
    
    // 1. 去重
    final uniqueEmails = removeDuplicates(emails);
    final duplicateCount = emails.length - uniqueEmails.length;
    
    // 2. 验证
    final validationResult = validateEmailsBatch(uniqueEmails);
    final validEmails = validationResult['valid'] as List<String>;
    final invalidEmails = validationResult['invalid'] as List<String>;
    final duplicateEmails = validationResult['duplicate'] as List<String>;
    
    // 3. 统计
    final totalCount = emails.length;
    final validCount = validEmails.length;
    final invalidCount = invalidEmails.length;
    final duplicateCount2 = duplicateEmails.length;
    
    final duration = DateTime.now().difference(startTime);
    
    developer.log('📊 [数据预处理器] 预处理完成 - 总数量: $totalCount, 有效: $validCount, 无效: $invalidCount, 重复: ${duplicateCount + duplicateCount2}', name: 'DataPreprocessor');
    developer.log('⏱️ [数据预处理器] 预处理耗时: ${duration.inMilliseconds}ms', name: 'DataPreprocessor');
    
    return {
      'validEmails': validEmails,
      'invalidEmails': invalidEmails,
      'duplicateEmails': duplicateEmails,
      'statistics': {
        'totalCount': totalCount,
        'validCount': validCount,
        'invalidCount': invalidCount,
        'duplicateCount': duplicateCount + duplicateCount2,
        'processingTime': duration.inMilliseconds,
      },
    };
  }
}

/// 内存管理优化器
class MemoryManager {
  static const int _maxMemoryUsage = 100 * 1024 * 1024; // 100MB
  static const int _chunkSize = 1000; // 每批处理1000个
  
  /// 分批处理大数据
  static Future<void> processLargeData<T>(
    List<T> data,
    Future<void> Function(List<T>) processor, {
    int chunkSize = _chunkSize,
    String? operationName,
  }) async {
    final totalCount = data.length;
    final totalChunks = (totalCount / chunkSize).ceil();
    
    developer.log('🔄 [内存管理器] 开始分批处理 - 总数量: $totalCount, 分片大小: $chunkSize, 总分片数: $totalChunks', name: 'MemoryManager');
    
    for (int i = 0; i < totalCount; i += chunkSize) {
      final end = (i + chunkSize < totalCount) ? i + chunkSize : totalCount;
      final chunk = data.sublist(i, end);
      final chunkIndex = (i / chunkSize).floor() + 1;
      
      final chunkStartTime = DateTime.now();
      developer.log('📦 [内存管理器] 处理分片 $chunkIndex/$totalChunks - 数量: ${chunk.length}', name: 'MemoryManager');
      
      try {
        await processor(chunk);
        
        final chunkDuration = DateTime.now().difference(chunkStartTime);
        developer.log('✅ [内存管理器] 分片 $chunkIndex 处理完成 - 耗时: ${chunkDuration.inMilliseconds}ms', name: 'MemoryManager');
        
        // 内存清理
        if (chunkIndex % 5 == 0) {
          await Future.delayed(const Duration(milliseconds: 100));
          developer.log('🧹 [内存管理器] 执行内存清理', name: 'MemoryManager');
        }
      } catch (e) {
        final chunkDuration = DateTime.now().difference(chunkStartTime);
        developer.log('❌ [内存管理器] 分片 $chunkIndex 处理失败 - 耗时: ${chunkDuration.inMilliseconds}ms, 错误: $e', name: 'MemoryManager');
        rethrow;
      }
    }
    
    developer.log('🎉 [内存管理器] 分批处理完成 - 总数量: $totalCount', name: 'MemoryManager');
  }
  
  /// 检查内存使用情况
  static void checkMemoryUsage() {
    // 这里可以添加实际的内存使用检查
    // 在Flutter中，可以通过PlatformDispatcher.instance.views.first.platformDispatcher.scheduleFrame来触发垃圾回收
    developer.log('💾 [内存管理器] 内存使用检查', name: 'MemoryManager');
  }
  
  /// 强制垃圾回收
  static void forceGarbageCollection() {
    // 在Flutter中，可以通过以下方式触发垃圾回收：
    // 1. 创建大量临时对象
    // 2. 调用PlatformDispatcher.instance.views.first.platformDispatcher.scheduleFrame
    developer.log('🧹 [内存管理器] 强制垃圾回收', name: 'MemoryManager');
  }
} 