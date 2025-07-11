import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_detail.dart';
import 'package:aliyun_edm_manager/constants/pagination_constants.dart';
import 'package:flutter/foundation.dart';

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
      final result = SaveReceiverDetailResponse.fromJson(response.data as Map<String, dynamic>);
      
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
    
    final detailJson = ReceiverDetailParams.toBatchDetailJson(receiverParamsList);
    final jsonSize = detailJson.length;
    final jsonSizeKB = (jsonSize / 1024).toStringAsFixed(2);
    
    debugPrint('📋 [收件人服务] 批量数据JSON大小: $jsonSize 字符 (${jsonSizeKB}KB)');
    
    // 检查数据大小是否超过1MB限制
    if (jsonSize > 1024 * 1024) {
      debugPrint('⚠️ [收件人服务] 警告: 数据大小超过1MB限制 (${jsonSizeKB}KB)');
      throw Exception('数据大小超过1MB限制，请减少批量大小');
    }
    
    // 如果数据大小接近1MB，给出警告
    if (jsonSize > 900 * 1024) {
      debugPrint('⚠️ [收件人服务] 警告: 数据大小接近1MB限制 (${jsonSizeKB}KB)，建议减少批量大小');
    }
    
    final params = <String, String>{
      'ReceiverId': receiverId,
      'Detail': detailJson,
    };

    // 添加重试机制
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    
    while (retryCount <= maxRetries) {
      try {
        final response = await post("SaveReceiverDetail", params);
        final result = SaveReceiverDetailResponse.fromJson(response.data as Map<String, dynamic>);
        
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