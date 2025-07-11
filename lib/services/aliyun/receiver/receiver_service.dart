import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_detail.dart';
import 'package:aliyun_edm_manager/constants/pagination_constants.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert'; // Added for jsonEncode
import 'dart:core'; // Added for Stopwatch

/// 收件人管理服务
/// 提供收件人列表和收件人详情的增删改查功能
class ReceiverService extends BaseAliyunService {
  
  /// 查询收件人列表
  Future<List<Map<String, dynamic>>> queryReceivers() async {
    final startTime = DateTime.now();
    debugPrint('🔍 [收件人服务] 开始查询收件人列表 - ${startTime.toIso8601String()}');
    
    try {
      final response = await get("QueryReceiverByParam", {});
      final responseData = response.data;
      final data = responseData['data'];
      final receivers = data != null ? data['receiver'] : null;

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      final count = receivers != null && receivers is List ? receivers.length : 0;
      
      debugPrint('✅ [收件人服务] 查询收件人列表完成 - 耗时: ${duration.inMilliseconds}ms, 找到: $count 个列表');

      if (receivers != null && receivers is List) {
        return List<Map<String, dynamic>>.from(receivers);
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('❌ [收件人服务] 查询收件人列表失败 - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      rethrow;
    }
  }

  /// 创建收件人列表
  Future<CreateReceiverResponse> createReceiver(String name, {String? alias, String? desc}) async {
    final startTime = DateTime.now();
    debugPrint('➕ [收件人服务] 开始创建收件人列表: $name - ${startTime.toIso8601String()}');
    
    final params = <String, String>{
      'ReceiversName': name,
      'Desc': desc ?? "新建收件人列表",
    };
    
    if (alias != null && alias.isNotEmpty) {
      params['ReceiversAlias'] = alias;
    }

    try {
      final response = await get("CreateReceiver", params);
      final result = CreateReceiverResponse.fromJson(response.data as Map<String, dynamic>);
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('✅ [收件人服务] 创建收件人列表成功: $name - 耗时: ${duration.inMilliseconds}ms, ID: ${result.receiverId}');
      
      return result;
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('❌ [收件人服务] 创建收件人列表失败: $name - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      rethrow;
    }
  }

  /// 删除收件人列表
  Future<void> deleteReceiver(String receiverName) async {
    final startTime = DateTime.now();
    debugPrint('🗑️ [收件人服务] 开始删除收件人列表: $receiverName - ${startTime.toIso8601String()}');
    
    try {
      await get("DeleteReceiver", {'ReceiverId': receiverName});
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('✅ [收件人服务] 删除收件人列表成功: $receiverName - 耗时: ${duration.inMilliseconds}ms');
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('❌ [收件人服务] 删除收件人列表失败: $receiverName - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      rethrow;
    }
  }

  /// 查询收件人详情
  Future<ReceiverDetail?> getReceiverDetail(
    String receiverId, {
    String keyWord = '',
    int pageSize = 50,
    String nextStart = '',
  }) async {
    final startTime = DateTime.now();
    debugPrint('🔍 [收件人服务] 开始查询收件人详情: $receiverId - ${startTime.toIso8601String()}');
    
    // 参数验证
    validateStringLength(keyWord, 'Email', 50);
    validatePagination(1, pageSize, maxPageSize: PaginationConstants.receiverDetailMaxPageSize);

    final params = <String, String>{
      'ReceiverId': receiverId,
      'PageSize': pageSize.toString(),
    };
    
    if (keyWord.isNotEmpty) params['KeyWord'] = keyWord;
    if (nextStart.isNotEmpty) params['NextStart'] = nextStart;

    try {
      final response = await get("QueryReceiverDetail", params);
      final detail = ReceiverDetail.fromJson(response.data);
      
      // 如果返回的数据总数小于pageSize,说明已经没有更多数据了
      if (detail.members.length < pageSize) {
        detail.setNextStart(null);
      }
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('✅ [收件人服务] 查询收件人详情成功: $receiverId - 耗时: ${duration.inMilliseconds}ms, 找到: ${detail.members.length} 个收件人');
      
      return detail;
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('❌ [收件人服务] 查询收件人详情失败: $receiverId - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      return null;
    }
  }

  /// 保存单个收件人详情
  Future<SaveReceiverDetailResponse> saveReceiverDetail(String receiverId, ReceiverDetailParams receiverParams) async {
    final startTime = DateTime.now();
    debugPrint('💾 [收件人服务] 开始保存单个收件人详情: $receiverId, 邮箱: ${receiverParams.email} - ${startTime.toIso8601String()}');
    
    final detailJson = receiverParams.toDetailJson();
    debugPrint('📋 [收件人服务] 数据JSON大小: ${detailJson.length} 字符');
    
    final params = <String, String>{
      'ReceiverId': receiverId,
      'Detail': detailJson,
    };

    try {
      final response = await post("SaveReceiverDetail", params);
      
      // 检查响应中是否包含错误信息
      final responseData = response.data as Map<String, dynamic>;
      
      // 检查是否有错误码
      if (responseData.containsKey('Code') && responseData['Code'] != 'OK') {
        final errorCode = responseData['Code'] as String;
        final errorMessage = responseData['Message'] as String? ?? '未知错误';
        
        debugPrint('❌ [收件人服务] API返回错误: $errorCode - $errorMessage');
        
        // 处理特定的错误类型
        if (errorCode == 'InvalidReceiverId.Malformed') {
          debugPrint('⚠️ [收件人服务] 检测到InvalidReceiverId.Malformed错误');
          debugPrint('📝 [收件人服务] 错误说明: 收件人列表ID不存在或格式错误');
          debugPrint('💡 [收件人服务] 建议: 检查收件人列表ID: $receiverId');
          throw Exception('收件人列表ID不存在或格式错误: $receiverId');
        } else if (errorCode == 'InvalidReceiverDetailMax.Malformed') {
          debugPrint('⚠️ [收件人服务] 检测到InvalidReceiverDetailMax.Malformed错误');
          debugPrint('📝 [收件人服务] 错误说明: 收件人详情中的地址数量超过了最大值');
          throw Exception('收件人详情中的地址数量超过了最大值');
        } else {
          throw Exception('API错误: $errorCode - $errorMessage');
        }
      }
      
      final result = SaveReceiverDetailResponse.fromJson(responseData);
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('✅ [收件人服务] 保存单个收件人详情成功: $receiverId - 耗时: ${duration.inMilliseconds}ms, 成功: ${result.successCount}, 失败: ${result.errorCount}');
      
      return result;
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('❌ [收件人服务] 保存单个收件人详情失败: $receiverId - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      rethrow;
    }
  }

  /// 批量保存收件人详情
  Future<SaveReceiverDetailResponse> saveReceiverDetails(String receiverId, List<ReceiverDetailParams> receiverParamsList) async {
    final startTime = DateTime.now();
    final batchSize = receiverParamsList.length;
    debugPrint('💾 [收件人服务] 开始批量保存收件人详情: $receiverId, 数量: $batchSize - ${startTime.toIso8601String()}');
    
    // 检查收件人列表总数量限制（每个列表最多2000个收件人）
    const maxReceiversPerList = ReceiverConstants.maxReceiversPerList;
    
    // 首先查询当前收件人列表中的收件人数量
    try {
      final currentDetail = await getReceiverDetail(receiverId, pageSize: 1);
      final currentCount = currentDetail?.members.length ?? 0;
      
      debugPrint('📊 [收件人服务] 当前收件人列表状态:');
      debugPrint('   - 收件人列表ID: $receiverId');
      debugPrint('   - 当前收件人数量: $currentCount');
      debugPrint('   - 本次添加数量: $batchSize');
      debugPrint('   - 添加后总数量: ${currentCount + batchSize}');
      debugPrint('   - 最大允许数量: $maxReceiversPerList');
      
      // 检查是否会超过限制
      if (currentCount + batchSize > maxReceiversPerList) {
        final canAddCount = maxReceiversPerList - currentCount;
        debugPrint('⚠️ [收件人服务] 警告: 添加后将超过收件人列表限制');
        debugPrint('📝 [收件人服务] 当前列表已有: $currentCount 个收件人');
        debugPrint('📝 [收件人服务] 本次尝试添加: $batchSize 个收件人');
        debugPrint('📝 [收件人服务] 最多还能添加: $canAddCount 个收件人');
        
        if (canAddCount <= 0) {
          throw Exception('收件人列表已达到最大限制($maxReceiversPerList个)，无法添加更多收件人');
        }
        
        // 如果超过限制，只添加能添加的部分
        debugPrint('🔄 [收件人服务] 自动调整批量大小: $batchSize -> $canAddCount');
        final adjustedList = receiverParamsList.take(canAddCount.toInt()).toList();
        
        // 递归调用，只添加能添加的部分
        final result = await saveReceiverDetails(receiverId, adjustedList);
        
        // 返回调整后的结果，并提示用户
        debugPrint('⚠️ [收件人服务] 由于列表限制，只添加了 $canAddCount 个收件人，剩余 ${batchSize - canAddCount} 个未添加');
        
        return SaveReceiverDetailResponse(
          requestId: result.requestId,
          successCount: result.successCount,
          errorCount: result.errorCount + (batchSize - canAddCount.toInt()), // 将未添加的计入失败
          existList: result.existList,
          failList: result.failList,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [收件人服务] 无法查询当前收件人数量，继续执行: $e');
      // 如果无法查询当前数量，继续执行，但给出警告
      debugPrint('⚠️ [收件人服务] 建议: 检查收件人列表是否存在或网络连接是否正常');
    }
    
    final detailJson = ReceiverDetailParams.toBatchDetailJson(receiverParamsList);
    final jsonSize = detailJson.length;
    final jsonSizeKB = (jsonSize / 1024).toStringAsFixed(2);
    
    debugPrint('📋 [收件人服务] 批量数据JSON大小: $jsonSize 字符 (${jsonSizeKB}KB)');
    
    // 检查批量大小是否符合API限制（500条记录）
    if (batchSize > ReceiverConstants.maxBatchSize) {
      debugPrint('⚠️ [收件人服务] 警告: 批量大小超过API限制 (${ReceiverConstants.maxBatchSize}条记录)，当前: $batchSize');
      throw Exception('批量大小超过API限制，每次最多${ReceiverConstants.maxBatchSize}条记录');
    }
    
    // 检查数据大小是否超过1MB限制
    if (jsonSize > ReceiverConstants.maxDataSizeBytes) {
      debugPrint('⚠️ [收件人服务] 警告: 数据大小超过1MB限制 (${jsonSizeKB}KB)');
      throw Exception('数据大小超过1MB限制，请减少批量大小');
    }
    
    // 如果数据大小接近1MB，给出警告
    if (jsonSize > ReceiverConstants.dataSizeWarningThresholdBytes) {
      debugPrint('⚠️ [收件人服务] 警告: 数据大小接近1MB限制 (${jsonSizeKB}KB)，建议减少批量大小');
    }
    
    final params = <String, String>{
      'ReceiverId': receiverId,
      'Detail': detailJson,
    };

    // 智能重试机制
    int retryCount = 0;
    const maxRetries = 3;
    Duration retryDelay = const Duration(seconds: 2);
    
    while (retryCount <= maxRetries) {
      try {
        // 添加请求间隔，避免频率限制
        if (retryCount > 0) {
          debugPrint('⏳ [收件人服务] 等待${retryDelay.inSeconds}秒后重试...');
          await Future.delayed(retryDelay);
        }
        
        final response = await post("SaveReceiverDetail", params);
        
        // 检查响应中是否包含错误信息
        final responseData = response.data as Map<String, dynamic>;
        
        // 检查是否有错误码
        if (responseData.containsKey('Code') && responseData['Code'] != 'OK') {
          final errorCode = responseData['Code'] as String;
          final errorMessage = responseData['Message'] as String? ?? '未知错误';
          
          debugPrint('❌ [收件人服务] API返回错误: $errorCode - $errorMessage');
          
          // 处理特定的错误类型
          if (errorCode == 'InvalidReceiverDetailMax.Malformed') {
            debugPrint('⚠️ [收件人服务] 检测到InvalidReceiverDetailMax.Malformed错误');
            debugPrint('📝 [收件人服务] 错误说明: 收件人详情中的地址数量超过了最大值');
            debugPrint('💡 [收件人服务] 建议: 减少批量大小，当前批量大小: $batchSize');
            
            // 智能调整批量大小
            if (batchSize > 100) {
              final newBatchSize = (batchSize / 2).round();
              debugPrint('🔄 [收件人服务] 自动减少批量大小: $batchSize -> $newBatchSize');
              
              // 分割数据并递归调用
              final firstHalf = receiverParamsList.take(newBatchSize).toList();
              final secondHalf = receiverParamsList.skip(newBatchSize).toList();
              
              // 先处理前半部分
              final firstResult = await saveReceiverDetails(receiverId, firstHalf);
              
              // 如果还有后半部分，继续处理
              if (secondHalf.isNotEmpty) {
                // 添加更长的间隔，避免频率限制
                await Future.delayed(const Duration(seconds: 3));
                final secondResult = await saveReceiverDetails(receiverId, secondHalf);
                
                // 合并结果
                return SaveReceiverDetailResponse(
                  requestId: firstResult.requestId,
                  successCount: firstResult.successCount + secondResult.successCount,
                  errorCount: firstResult.errorCount + secondResult.errorCount,
                  existList: [...?firstResult.existList, ...?secondResult.existList],
                  failList: [...?firstResult.failList, ...?secondResult.failList],
                );
              }
              
              return firstResult;
            } else {
              debugPrint('⚠️ [收件人服务] 批量大小已经很小($batchSize)，无法进一步减少');
              debugPrint('💡 [收件人服务] 建议: 检查收件人数据格式是否正确');
              
              // 增加重试间隔
              retryDelay = const Duration(seconds: 5);
            }
          } else if (errorCode == 'InvalidReceiverId.Malformed') {
            debugPrint('⚠️ [收件人服务] 检测到InvalidReceiverId.Malformed错误');
            debugPrint('📝 [收件人服务] 错误说明: 收件人列表ID不存在或格式错误');
            debugPrint('💡 [收件人服务] 建议: 检查收件人列表ID: $receiverId');
            
            // 这个错误通常无法通过重试解决，直接抛出异常
            throw Exception('收件人列表ID不存在或格式错误: $receiverId');
          } else if (errorCode == 'Throttling' || errorCode == 'RequestLimitExceeded') {
            debugPrint('⚠️ [收件人服务] 检测到频率限制错误');
            debugPrint('💡 [收件人服务] 建议: 增加请求间隔');
            
            // 增加重试间隔
            retryDelay = Duration(seconds: 5 + (retryCount * 2));
          } else {
            // 其他错误，记录并重试
            debugPrint('⚠️ [收件人服务] 检测到其他API错误: $errorCode');
            debugPrint('💡 [收件人服务] 错误信息: $errorMessage');
            
            // 增加重试间隔
            retryDelay = Duration(seconds: 3 + retryCount);
          }
          
          // 如果不是致命错误，继续重试
          if (errorCode != 'InvalidReceiverId.Malformed') {
            if (retryCount < maxRetries) {
              retryCount++;
              continue;
            } else {
              throw Exception('API错误: $errorCode - $errorMessage');
            }
          } else {
            throw Exception('API错误: $errorCode - $errorMessage');
          }
        }
        
        // 正常响应，解析结果
        final result = SaveReceiverDetailResponse.fromJson(responseData);
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        final avgTimePerItem = batchSize > 0 ? duration.inMilliseconds / batchSize : 0;
        
        debugPrint('✅ [收件人服务] 批量保存收件人详情成功: $receiverId');
        debugPrint('   📊 统计信息:');
        debugPrint('   - 总耗时: ${duration.inMilliseconds}ms');
        debugPrint('   - 批量大小: $batchSize 个');
        debugPrint('   - 平均耗时: ${avgTimePerItem.toStringAsFixed(2)}ms/个');
        debugPrint('   - 成功数量: ${result.successCount} 个');
        debugPrint('   - 失败数量: ${result.errorCount} 个');
        debugPrint('   - 已存在数量: ${result.existList?.length ?? 0} 个');
        debugPrint('   - 数据大小: ${jsonSizeKB}KB');
        debugPrint('   - 重试次数: $retryCount');
        
        // 处理重复收件人的情况
        if (result.errorCount > 0 && result.existList != null && result.existList!.isNotEmpty) {
          debugPrint('   ⚠️ 检测到重复收件人: ${result.existList!.length} 个');
          debugPrint('   📋 重复邮箱列表: ${result.existList!.take(3).join(', ')}${result.existList!.length > 3 ? '...' : ''}');
        }
        
        if (result.hasFailed && result.failList != null) {
          debugPrint('   ❌ 失败列表: ${result.failList!.take(5).join(', ')}${result.failList!.length > 5 ? '...' : ''}');
        }
        
        return result;
      } catch (e) {
        retryCount++;
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        
        debugPrint('❌ [收件人服务] 批量保存收件人详情失败: $receiverId - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
        debugPrint('🔄 [收件人服务] 重试 ${retryCount}/$maxRetries');
        
        // 检查是否是网络或超时错误
        if (e.toString().contains('Timeout') || 
            e.toString().contains('Connection') ||
            e.toString().contains('Network')) {
          debugPrint('⚠️ [收件人服务] 检测到网络或超时错误');
          debugPrint('💡 [收件人服务] 建议: 检查网络连接');
          
          // 增加重试间隔
          retryDelay = Duration(seconds: 3 + (retryCount * 2));
        }
        
        if (retryCount <= maxRetries) {
          debugPrint('⏳ [收件人服务] 等待${retryDelay.inSeconds}秒后重试...');
          await Future.delayed(retryDelay);
        } else {
          debugPrint('💥 [收件人服务] 达到最大重试次数，放弃重试');
          rethrow;
        }
      }
    }
    
    throw Exception('批量保存收件人详情失败，已重试$maxRetries次');
  }

  /// 删除收件人详情
  Future<void> deleteReceiverDetail(String receiverId, String email) async {
    final startTime = DateTime.now();
    debugPrint('🗑️ [收件人服务] 开始删除收件人详情: $receiverId, 邮箱: $email - ${startTime.toIso8601String()}');
    
    try {
      await get("DeleteReceiverDetail", {
        'ReceiverId': receiverId,
        'Email': email,
      });
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('✅ [收件人服务] 删除收件人详情成功: $receiverId, 邮箱: $email - 耗时: ${duration.inMilliseconds}ms');
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('❌ [收件人服务] 删除收件人详情失败: $receiverId, 邮箱: $email - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      rethrow;
    }
  }
} 