import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_detail.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';

/// 后台收件人处理服务
/// 用于在后台执行批量添加收件人的操作，避免阻塞UI
class BackgroundReceiverService {
  static BackgroundReceiverService? _instance;
  static BackgroundReceiverService get instance => _instance ??= BackgroundReceiverService._();
  
  BackgroundReceiverService._();

  /// 后台处理任务的状态
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// 处理进度回调
  Function(String status, int processed, int total)? _progressCallback;
  Function(List<String> successLists, List<String> failedLists)? _completionCallback;
  Function(String error)? _errorCallback;

  /// 设置进度回调
  void setProgressCallback(Function(String status, int processed, int total) callback) {
    _progressCallback = callback;
  }

  /// 设置完成回调
  void setCompletionCallback(Function(List<String> successLists, List<String> failedLists) callback) {
    _completionCallback = callback;
  }

  /// 设置错误回调
  void setErrorCallback(Function(String error) callback) {
    _errorCallback = callback;
  }

  /// 开始后台处理
  Future<void> startBackgroundProcessing({
    required GlobalConfigProvider globalConfig,
    required List<List<String>> emailBatches,
    required String prefix,
    required String suffix,
    required List<String> existingNames,
    int batchSize = 500, // 修正为500，符合阿里云API限制
    int maxConcurrent = 3,
    bool enablePerformanceMode = true,
  }) async {
    if (_isProcessing) {
      throw Exception('已有任务正在处理中');
    }

    _isProcessing = true;

    try {
      // 在后台执行处理
      await _processInBackground(
        globalConfig: globalConfig,
        emailBatches: emailBatches,
        prefix: prefix,
        suffix: suffix,
        existingNames: existingNames,
        batchSize: batchSize,
        maxConcurrent: maxConcurrent,
        enablePerformanceMode: enablePerformanceMode,
      );
    } catch (e) {
      _errorCallback?.call('后台处理失败: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// 在后台执行处理
  Future<void> _processInBackground({
    required GlobalConfigProvider globalConfig,
    required List<List<String>> emailBatches,
    required String prefix,
    required String suffix,
    required List<String> existingNames,
    int batchSize = 500, // 修正为500，符合阿里云API限制
    int maxConcurrent = 3,
    bool enablePerformanceMode = true,
  }) async {
    final successLists = <String>[];
    final failedLists = <String>[];
    int processedEmails = 0;
    int totalEmails = emailBatches.fold(0, (sum, batch) => sum + batch.length);
    
    // 性能监控
    final startTime = DateTime.now();
    final performanceLog = <String, Duration>{};

    try {
      // 初始化服务管理器
      final serviceStartTime = DateTime.now();
      _progressCallback?.call('正在查询现有收件人列表...', 0, totalEmails);
      final serviceManager = AliyunServiceManager();
      serviceManager.initialize(globalConfig);
      final receiverService = serviceManager.receiverService;
      final existingReceivers = await receiverService.queryReceivers();
      performanceLog['服务初始化'] = DateTime.now().difference(serviceStartTime);

      // 处理每个批次
      for (int i = 0; i < emailBatches.length; i++) {
        final batchStartTime = DateTime.now();
        final batch = emailBatches[i];
        final listName = '${prefix}${i + 1}';
        final alias = '${_getCurrentDate()}${(i + 1).toString().padLeft(2, '0')}$suffix';

        _progressCallback?.call(
          '正在处理收件人列表: $listName (${i + 1}/${emailBatches.length})',
          processedEmails,
          totalEmails,
        );

        try {
          // 检查收件人列表是否存在
          final existingReceiver = _findExistingReceiver(existingReceivers, listName);
          
          if (existingReceiver == null) {
            // 列表不存在，直接创建
            await _createNewReceiverList(
              receiverService, 
              listName, 
              alias, 
              batch,
              batchSize: batchSize,
              maxConcurrent: maxConcurrent,
              enablePerformanceMode: enablePerformanceMode,
            );
          } else {
            // 列表存在，检查是否有收件人数据
            final hasReceivers = existingReceiver['Count'] > 0;
            
            if (!hasReceivers) {
              // 列表存在但无收件人数据，直接写入
              await _addReceiversToExistingList(
                receiverService, 
                existingReceiver['ReceiverId'], 
                batch,
                batchSize: batchSize,
                maxConcurrent: maxConcurrent,
                enablePerformanceMode: enablePerformanceMode,
              );
            } else {
              // 列表存在且有收件人数据，跳过（在后台处理中，我们选择跳过冲突的列表）
              failedLists.add('$listName (列表已存在且有数据)');
              continue;
            }
          }
          
          successLists.add(listName);
          processedEmails += batch.length;
          performanceLog['批次${i + 1}'] = DateTime.now().difference(batchStartTime);
        } catch (e) {
          debugPrint('处理收件人列表失败: $listName, 错误: $e');
          failedLists.add(listName);
        }
      }

      // 输出性能日志
      final totalTime = DateTime.now().difference(startTime);
      debugPrint('=== 性能监控报告 ===');
      debugPrint('总耗时: ${totalTime.inSeconds}秒');
      performanceLog.forEach((key, duration) {
        debugPrint('$key: ${duration.inMilliseconds}毫秒');
      });
      debugPrint('平均每批次: ${totalTime.inMilliseconds / emailBatches.length}毫秒');

      // 处理完成
      _completionCallback?.call(successLists, failedLists);
    } catch (e) {
      _errorCallback?.call('后台处理失败: $e');
    }
  }

  /// 创建新的收件人列表
  Future<void> _createNewReceiverList(
    dynamic receiverService, 
    String listName, 
    String alias, 
    List<String> emails, {
    int batchSize = 500, // 修正为500，符合阿里云API限制
    int maxConcurrent = 3,
    bool enablePerformanceMode = true,
  }) async {
    _progressCallback?.call('正在创建收件人列表: $listName', 0, 0);
    
    final createResponse = await receiverService.createReceiver(listName, alias: alias);
    final receiverId = createResponse.receiverId;
    
    await _addReceiversToExistingList(
      receiverService, 
      receiverId, 
      emails,
      batchSize: batchSize,
      maxConcurrent: maxConcurrent,
      enablePerformanceMode: enablePerformanceMode,
    );
  }

  /// 向现有收件人列表添加收件人
  Future<void> _addReceiversToExistingList(
    dynamic receiverService, 
    String receiverId, 
    List<String> emails, {
    int batchSize = 500, // 修正为500，符合阿里云API限制
    int maxConcurrent = 3,
    bool enablePerformanceMode = true,
  }) async {
    // 使用配置的批量大小
    final emailChunks = _chunkEmails(emails, batchSize);
    
    if (enablePerformanceMode && maxConcurrent > 1) {
      // 使用并发处理
      final semaphore = Lock(); // 使用Lock来控制并发
      int currentConcurrent = 0;
      
      final futures = <Future<void>>[];
      
      for (int j = 0; j < emailChunks.length; j++) {
        final chunk = emailChunks[j];
        final chunkIndex = j;
        
        final future = semaphore.synchronized(() async {
          // 等待有可用的并发槽位
          while (currentConcurrent >= maxConcurrent) {
            await Future.delayed(Duration(milliseconds: 100));
          }
          currentConcurrent++;
          
          try {
            _progressCallback?.call(
              '正在添加收件人到列表 (${chunkIndex + 1}/${emailChunks.length})',
              0,
              0,
            );
            
            // 为每个邮箱创建收件人参数
            final receiverParamsList = chunk.map((email) => 
              ReceiverDetailParams(email: email, fieldValues: {})
            ).toList();
            
            // 批量添加收件人
            await receiverService.saveReceiverDetails(receiverId, receiverParamsList);
          } finally {
            currentConcurrent--;
          }
        });
        
        futures.add(future);
      }
      
      // 等待所有请求完成
      await Future.wait(futures);
    } else {
      // 串行处理
      for (int j = 0; j < emailChunks.length; j++) {
        final chunk = emailChunks[j];
        _progressCallback?.call(
          '正在添加收件人到列表 (${j + 1}/${emailChunks.length})',
          0,
          0,
        );
        
        // 为每个邮箱创建收件人参数
        final receiverParamsList = chunk.map((email) => 
          ReceiverDetailParams(email: email, fieldValues: {})
        ).toList();
        
        // 批量添加收件人
        await receiverService.saveReceiverDetails(receiverId, receiverParamsList);
      }
    }
  }

  /// 查找现有的收件人列表
  Map<String, dynamic>? _findExistingReceiver(List<Map<String, dynamic>> existingReceivers, String listName) {
    try {
      return existingReceivers.firstWhere(
        (receiver) => receiver['ReceiversName'] == listName,
      );
    } catch (e) {
      return null;
    }
  }

  /// 分批处理邮箱
  List<List<String>> _chunkEmails(List<String> emails, int chunkSize) {
    final chunks = <List<String>>[];
    for (int i = 0; i < emails.length; i += chunkSize) {
      final end = (i + chunkSize < emails.length) ? i + chunkSize : emails.length;
      chunks.add(emails.sublist(i, end));
    }
    return chunks;
  }

  /// 获取当前日期字符串
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
           '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
           '${now.second.toString().padLeft(2, '0')}';
  }

  /// 停止处理
  void stopProcessing() {
    _isProcessing = false;
  }
} 