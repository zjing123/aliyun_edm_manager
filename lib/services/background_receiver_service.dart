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
    final overallStartTime = DateTime.now();
    
    debugPrint('🚀 [后台处理] 开始批量处理收件人列表');
    debugPrint('   📊 配置信息:');
    debugPrint('   - 总批次数量: ${emailBatches.length}');
    debugPrint('   - 总收件人数量: ${emailBatches.fold(0, (sum, batch) => sum + batch.length)}');
    debugPrint('   - 批量大小: $batchSize');
    debugPrint('   - 最大并发数: $maxConcurrent');
    debugPrint('   - 性能模式: ${enablePerformanceMode ? "启用" : "禁用"}');
    debugPrint('   - 开始时间: ${overallStartTime.toIso8601String()}');

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
      
      final overallEndTime = DateTime.now();
      final overallDuration = overallEndTime.difference(overallStartTime);
      debugPrint('✅ [后台处理] 批量处理完成 - 总耗时: ${overallDuration.inSeconds}秒 (${overallDuration.inMilliseconds}ms)');
    } catch (e) {
      final overallEndTime = DateTime.now();
      final overallDuration = overallEndTime.difference(overallStartTime);
      debugPrint('❌ [后台处理] 批量处理失败 - 总耗时: ${overallDuration.inSeconds}秒 (${overallDuration.inMilliseconds}ms), 错误: $e');
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
    final batchPerformanceLog = <String, Map<String, dynamic>>{};

    try {
      // 初始化服务管理器
      final serviceStartTime = DateTime.now();
      debugPrint('🔧 [后台处理] 正在初始化服务管理器...');
      _progressCallback?.call('正在查询现有收件人列表...', 0, totalEmails);
      
      final serviceManager = AliyunServiceManager();
      serviceManager.initialize(globalConfig);
      final receiverService = serviceManager.receiverService;
      final existingReceivers = await receiverService.queryReceivers();
      
      final serviceInitDuration = DateTime.now().difference(serviceStartTime);
      performanceLog['服务初始化'] = serviceInitDuration;
      debugPrint('✅ [后台处理] 服务初始化完成 - 耗时: ${serviceInitDuration.inMilliseconds}ms, 找到现有列表: ${existingReceivers.length} 个');

      // 处理每个批次
      for (int i = 0; i < emailBatches.length; i++) {
        final batchStartTime = DateTime.now();
        final batch = emailBatches[i];
        final listName = '${prefix}${i + 1}';
        final alias = '${_getCurrentDate()}${(i + 1).toString().padLeft(2, '0')}$suffix';

        debugPrint('📦 [后台处理] 开始处理批次 ${i + 1}/${emailBatches.length}: $listName (${batch.length} 个收件人)');

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
            debugPrint('➕ [后台处理] 创建新收件人列表: $listName');
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
              debugPrint('📝 [后台处理] 向现有空列表添加收件人: $listName');
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
              debugPrint('⚠️ [后台处理] 跳过已存在的收件人列表: $listName (已有 ${existingReceiver['Count']} 个收件人)');
              failedLists.add('$listName (列表已存在且有数据)');
              continue;
            }
          }
          
          successLists.add(listName);
          processedEmails += batch.length;
          
          final batchDuration = DateTime.now().difference(batchStartTime);
          performanceLog['批次${i + 1}'] = batchDuration;
          
          // 记录详细的批次性能信息
          batchPerformanceLog['批次${i + 1}'] = {
            'listName': listName,
            'batchSize': batch.length,
            'duration': batchDuration.inMilliseconds,
            'avgTimePerEmail': batch.length > 0 ? batchDuration.inMilliseconds / batch.length : 0,
            'status': 'success',
          };
          
          debugPrint('✅ [后台处理] 批次 ${i + 1} 处理完成: $listName - 耗时: ${batchDuration.inMilliseconds}ms, 平均: ${(batchDuration.inMilliseconds / batch.length).toStringAsFixed(2)}ms/个');
        } catch (e) {
          final batchDuration = DateTime.now().difference(batchStartTime);
          debugPrint('❌ [后台处理] 批次 ${i + 1} 处理失败: $listName - 耗时: ${batchDuration.inMilliseconds}ms, 错误: $e');
          failedLists.add(listName);
          
          // 记录失败的批次性能信息
          batchPerformanceLog['批次${i + 1}'] = {
            'listName': listName,
            'batchSize': batch.length,
            'duration': batchDuration.inMilliseconds,
            'avgTimePerEmail': batch.length > 0 ? batchDuration.inMilliseconds / batch.length : 0,
            'status': 'failed',
            'error': e.toString(),
          };
        }
      }

      // 输出详细的性能监控报告
      final totalTime = DateTime.now().difference(startTime);
      debugPrint('📊 [后台处理] === 详细性能监控报告 ===');
      debugPrint('📈 总体统计:');
      debugPrint('   - 总耗时: ${totalTime.inSeconds}秒 (${totalTime.inMilliseconds}ms)');
      debugPrint('   - 总批次: ${emailBatches.length} 个');
      debugPrint('   - 成功批次: ${successLists.length} 个');
      debugPrint('   - 失败批次: ${failedLists.length} 个');
      debugPrint('   - 总收件人: $totalEmails 个');
      debugPrint('   - 处理收件人: $processedEmails 个');
      debugPrint('   - 平均每批次: ${(totalTime.inMilliseconds / emailBatches.length).toStringAsFixed(2)}ms');
      debugPrint('   - 平均每收件人: ${(totalTime.inMilliseconds / totalEmails).toStringAsFixed(2)}ms');
      
      debugPrint('📋 各阶段耗时:');
      performanceLog.forEach((key, duration) {
        debugPrint('   - $key: ${duration.inMilliseconds}ms');
      });
      
      debugPrint('📦 批次详细统计:');
      batchPerformanceLog.forEach((key, info) {
        final status = info['status'] == 'success' ? '✅' : '❌';
        debugPrint('   $status $key: ${info['listName']} - ${info['duration']}ms (${info['avgTimePerEmail'].toStringAsFixed(2)}ms/个)');
        if (info['status'] == 'failed') {
          debugPrint('     错误: ${info['error']}');
        }
      });

      // 处理完成
      _completionCallback?.call(successLists, failedLists);
    } catch (e) {
      debugPrint('💥 [后台处理] 处理过程中发生错误: $e');
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
    final startTime = DateTime.now();
    debugPrint('➕ [后台处理] 开始创建收件人列表: $listName (${emails.length} 个收件人)');
    
    _progressCallback?.call('正在创建收件人列表: $listName', 0, 0);
    
    try {
      final createResponse = await receiverService.createReceiver(listName, alias: alias);
      final receiverId = createResponse.receiverId;
      
      final createDuration = DateTime.now().difference(startTime);
      debugPrint('✅ [后台处理] 收件人列表创建成功: $listName - 耗时: ${createDuration.inMilliseconds}ms, ID: $receiverId');
      
      await _addReceiversToExistingList(
        receiverService, 
        receiverId, 
        emails,
        batchSize: batchSize,
        maxConcurrent: maxConcurrent,
        enablePerformanceMode: enablePerformanceMode,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [后台处理] 创建收件人列表失败: $listName - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      rethrow;
    }
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
    final startTime = DateTime.now();
    final totalEmails = emails.length;
    debugPrint('📝 [后台处理] 开始添加收件人到列表: $receiverId (${totalEmails} 个收件人)');
    
    // 使用配置的批量大小
    final emailChunks = _chunkEmails(emails, batchSize);
    debugPrint('📦 [后台处理] 数据分片完成: ${emailChunks.length} 个分片, 每片最多 $batchSize 个');
    
    if (enablePerformanceMode && maxConcurrent > 1) {
      // 使用并发处理
      debugPrint('⚡ [后台处理] 启用并发处理模式: 最大并发数 $maxConcurrent');
      final semaphore = Lock(); // 使用Lock来控制并发
      int currentConcurrent = 0;
      int completedChunks = 0;
      
      final futures = <Future<void>>[];
      final chunkPerformanceLog = <int, Duration>{};
      
      for (int j = 0; j < emailChunks.length; j++) {
        final chunk = emailChunks[j];
        final chunkIndex = j;
        
        final future = semaphore.synchronized(() async {
          final chunkStartTime = DateTime.now();
          
          // 等待有可用的并发槽位
          while (currentConcurrent >= maxConcurrent) {
            await Future.delayed(Duration(milliseconds: 100));
          }
          currentConcurrent++;
          
          try {
            debugPrint('🔄 [后台处理] 开始处理分片 ${chunkIndex + 1}/${emailChunks.length}: ${chunk.length} 个收件人 (当前并发: $currentConcurrent)');
            
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
            
            completedChunks++;
            final chunkDuration = DateTime.now().difference(chunkStartTime);
            chunkPerformanceLog[chunkIndex] = chunkDuration;
            
            debugPrint('✅ [后台处理] 分片 ${chunkIndex + 1} 处理完成: ${chunk.length} 个收件人 - 耗时: ${chunkDuration.inMilliseconds}ms (平均: ${(chunkDuration.inMilliseconds / chunk.length).toStringAsFixed(2)}ms/个)');
            
            // 添加请求间隔，避免触发阿里云频率限制
            if (chunkIndex < emailChunks.length - 1) {
              debugPrint('⏳ [后台处理] 等待100ms避免频率限制...');
              await Future.delayed(Duration(milliseconds: 100));
            }
          } catch (e) {
            final chunkDuration = DateTime.now().difference(chunkStartTime);
            debugPrint('❌ [后台处理] 分片 ${chunkIndex + 1} 处理失败: ${chunk.length} 个收件人 - 耗时: ${chunkDuration.inMilliseconds}ms, 错误: $e');
            
            // 如果是网络错误或超时，等待更长时间后重试
            if (e.toString().contains('timeout') || e.toString().contains('connection')) {
              debugPrint('🔄 [后台处理] 检测到网络问题，等待5秒后重试...');
              await Future.delayed(Duration(seconds: 5));
              
              try {
                debugPrint('🔄 [后台处理] 重试分片 ${chunkIndex + 1}...');
                // 重新创建收件人参数列表用于重试
                final retryReceiverParamsList = chunk.map((email) => 
                  ReceiverDetailParams(email: email, fieldValues: {})
                ).toList();
                await receiverService.saveReceiverDetails(receiverId, retryReceiverParamsList);
                debugPrint('✅ [后台处理] 分片 ${chunkIndex + 1} 重试成功');
              } catch (retryError) {
                debugPrint('❌ [后台处理] 分片 ${chunkIndex + 1} 重试失败: $retryError');
                rethrow;
              }
            } else {
              rethrow;
            }
          } finally {
            currentConcurrent--;
          }
        });
        
        futures.add(future);
      }
      
      // 等待所有请求完成
      await Future.wait(futures);
      
      final totalDuration = DateTime.now().difference(startTime);
      debugPrint('✅ [后台处理] 并发处理完成: $receiverId');
      debugPrint('   📊 并发处理统计:');
      debugPrint('   - 总分片数: ${emailChunks.length}');
      debugPrint('   - 完成分片数: $completedChunks');
      debugPrint('   - 总耗时: ${totalDuration.inMilliseconds}ms');
      debugPrint('   - 平均每分片: ${(totalDuration.inMilliseconds / emailChunks.length).toStringAsFixed(2)}ms');
      
      // 输出分片性能详情
      chunkPerformanceLog.forEach((index, duration) {
        final chunkSize = emailChunks[index].length;
        debugPrint('   - 分片${index + 1}: ${duration.inMilliseconds}ms (${chunkSize}个, ${(duration.inMilliseconds / chunkSize).toStringAsFixed(2)}ms/个)');
      });
    } else {
      // 串行处理
      debugPrint('📋 [后台处理] 启用串行处理模式');
      for (int j = 0; j < emailChunks.length; j++) {
        final chunk = emailChunks[j];
        final chunkStartTime = DateTime.now();
        
        debugPrint('🔄 [后台处理] 开始处理分片 ${j + 1}/${emailChunks.length}: ${chunk.length} 个收件人');
        
        _progressCallback?.call(
          '正在添加收件人到列表 (${j + 1}/${emailChunks.length})',
          0,
          0,
        );
        
        try {
          // 为每个邮箱创建收件人参数
          final receiverParamsList = chunk.map((email) => 
            ReceiverDetailParams(email: email, fieldValues: {})
          ).toList();
          
          // 批量添加收件人
          await receiverService.saveReceiverDetails(receiverId, receiverParamsList);
          
          final chunkDuration = DateTime.now().difference(chunkStartTime);
          debugPrint('✅ [后台处理] 分片 ${j + 1} 处理完成: ${chunk.length} 个收件人 - 耗时: ${chunkDuration.inMilliseconds}ms (平均: ${(chunkDuration.inMilliseconds / chunk.length).toStringAsFixed(2)}ms/个)');
          
          // 添加请求间隔，避免触发阿里云频率限制
          if (j < emailChunks.length - 1) {
            debugPrint('⏳ [后台处理] 等待200ms避免频率限制...');
            await Future.delayed(Duration(milliseconds: 200));
          }
        } catch (e) {
          final chunkDuration = DateTime.now().difference(chunkStartTime);
          debugPrint('❌ [后台处理] 分片 ${j + 1} 处理失败: ${chunk.length} 个收件人 - 耗时: ${chunkDuration.inMilliseconds}ms, 错误: $e');
          
          // 如果是网络错误或超时，等待更长时间后重试
          if (e.toString().contains('timeout') || e.toString().contains('connection')) {
            debugPrint('🔄 [后台处理] 检测到网络问题，等待5秒后重试...');
            await Future.delayed(Duration(seconds: 5));
            
            try {
              debugPrint('🔄 [后台处理] 重试分片 ${j + 1}...');
              // 重新创建收件人参数列表用于重试
              final retryReceiverParamsList = chunk.map((email) => 
                ReceiverDetailParams(email: email, fieldValues: {})
              ).toList();
              await receiverService.saveReceiverDetails(receiverId, retryReceiverParamsList);
              debugPrint('✅ [后台处理] 分片 ${j + 1} 重试成功');
            } catch (retryError) {
              debugPrint('❌ [后台处理] 分片 ${j + 1} 重试失败: $retryError');
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      }
    }
    
    final totalDuration = DateTime.now().difference(startTime);
    debugPrint('✅ [后台处理] 收件人添加完成: $receiverId - 总耗时: ${totalDuration.inMilliseconds}ms, 总收件人: $totalEmails 个');
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
    debugPrint('⏹️ [后台处理] 处理已停止');
  }
} 