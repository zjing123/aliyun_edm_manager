import 'package:aliyun_edm_manager/services/aliyun/receiver/receiver_service.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_detail.dart';
import 'package:flutter/foundation.dart';

/// 性能测试工具类
class PerformanceTest {
  static final PerformanceTest _instance = PerformanceTest._internal();
  factory PerformanceTest() => _instance;
  PerformanceTest._internal();

  /// 测试添加500个收件人数据的性能
  static Future<Map<String, dynamic>> testBatchSavePerformance({
    required GlobalConfigProvider globalConfig,
    int batchSize = 500,
  }) async {
    final results = <String, dynamic>{};
    
    try {
      debugPrint('🚀 开始性能测试: 添加 $batchSize 个收件人数据');
      
      // 初始化服务
      final receiverService = ReceiverService();
      receiverService.setGlobalConfigProvider(globalConfig);
      
      // 1. 创建测试收件人列表
      final testListName = '性能测试_${DateTime.now().millisecondsSinceEpoch}';
      final testAlias = 'perf_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      debugPrint('📝 创建测试收件人列表: $testListName');
      final createStartTime = DateTime.now();
      final createResponse = await receiverService.createReceiver(testListName, alias: testAlias);
      final createDuration = DateTime.now().difference(createStartTime);
      
      debugPrint('✅ 收件人列表创建成功 - 耗时: ${createDuration.inMilliseconds}ms');
      debugPrint('📋 列表ID: ${createResponse.receiverId}');
      
      // 2. 生成测试邮箱数据
      final testEmails = <String>[];
      for (int i = 1; i <= batchSize; i++) {
        testEmails.add('test${i.toString().padLeft(3, '0')}@example.com');
      }
      
      debugPrint('📧 生成测试邮箱数据: ${testEmails.length} 个');
      
      // 3. 创建收件人参数列表
      final receiverParamsList = testEmails.map((email) => 
        ReceiverDetailParams(email: email, fieldValues: {})
      ).toList();
      
      debugPrint('📋 创建收件人参数列表完成');
      
      // 4. 测试批量保存性能
      debugPrint('💾 开始批量保存 $batchSize 个收件人...');
      final saveStartTime = DateTime.now();
      
      final saveResponse = await receiverService.saveReceiverDetails(
        createResponse.receiverId, 
        receiverParamsList
      );
      
      final saveDuration = DateTime.now().difference(saveStartTime);
      
      // 5. 收集性能数据
      results['success'] = true;
      results['createDuration'] = createDuration.inMilliseconds;
      results['saveDuration'] = saveDuration.inMilliseconds;
      results['totalDuration'] = (createDuration + saveDuration).inMilliseconds;
      results['batchSize'] = batchSize;
      results['avgTimePerEmail'] = saveDuration.inMilliseconds / batchSize;
      results['successCount'] = saveResponse.successCount;
      results['errorCount'] = saveResponse.errorCount;
      results['existCount'] = saveResponse.existList?.length ?? 0;
      results['receiverId'] = createResponse.receiverId;
      
      // 6. 输出详细性能报告
      debugPrint('\n📊 === 性能测试结果 ===');
      debugPrint('📈 总体统计:');
      debugPrint('   - 收件人列表创建耗时: ${createDuration.inMilliseconds}ms');
      debugPrint('   - 批量保存总耗时: ${saveDuration.inMilliseconds}ms');
      debugPrint('   - 总耗时: ${(createDuration + saveDuration).inMilliseconds}ms');
      debugPrint('   - 测试数据量: $batchSize 个');
      debugPrint('   - 平均每收件人耗时: ${(saveDuration.inMilliseconds / batchSize).toStringAsFixed(2)}ms');
      
      debugPrint('\n📋 保存结果统计:');
      debugPrint('   - 成功数量: ${saveResponse.successCount} 个');
      debugPrint('   - 失败数量: ${saveResponse.errorCount} 个');
      debugPrint('   - 已存在数量: ${saveResponse.existList?.length ?? 0} 个');
      
      if (saveResponse.hasFailed && saveResponse.failList != null) {
        debugPrint('   - 失败列表: ${saveResponse.failList!.take(5).join(', ')}${saveResponse.failList!.length > 5 ? '...' : ''}');
      }
      
      // 7. 性能评估
      debugPrint('\n🎯 性能评估:');
      final avgTimePerEmail = saveDuration.inMilliseconds / batchSize;
      if (avgTimePerEmail < 10) {
        debugPrint('   ✅ 性能优秀: 平均每收件人 ${avgTimePerEmail.toStringAsFixed(2)}ms');
        results['performanceRating'] = '优秀';
      } else if (avgTimePerEmail < 50) {
        debugPrint('   ⚠️ 性能良好: 平均每收件人 ${avgTimePerEmail.toStringAsFixed(2)}ms');
        results['performanceRating'] = '良好';
      } else if (avgTimePerEmail < 100) {
        debugPrint('   ⚠️ 性能一般: 平均每收件人 ${avgTimePerEmail.toStringAsFixed(2)}ms');
        results['performanceRating'] = '一般';
      } else {
        debugPrint('   ❌ 性能较差: 平均每收件人 ${avgTimePerEmail.toStringAsFixed(2)}ms');
        results['performanceRating'] = '较差';
      }
      
      // 8. 清理测试数据（可选）
      debugPrint('\n🗑️ 清理测试数据...');
      try {
        await receiverService.deleteReceiver(createResponse.receiverId);
        debugPrint('✅ 测试数据清理成功');
        results['cleanupSuccess'] = true;
      } catch (e) {
        debugPrint('⚠️ 测试数据清理失败: $e');
        results['cleanupSuccess'] = false;
        results['cleanupError'] = e.toString();
      }
      
      debugPrint('\n✅ 性能测试完成！');
      
    } catch (e) {
      debugPrint('❌ 性能测试失败: $e');
      results['success'] = false;
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// 测试不同批量大小的性能
  static Future<Map<String, dynamic>> testBatchSizePerformance({
    required GlobalConfigProvider globalConfig,
    List<int> batchSizes = const [100, 200, 300, 400, 500],
  }) async {
    final results = <String, dynamic>{};
    final batchResults = <int, Map<String, dynamic>>{};
    
    debugPrint('🚀 开始测试不同批量大小的性能...');
    
    for (final batchSize in batchSizes) {
      try {
        debugPrint('\n📊 测试批量大小: $batchSize');
        
        final batchResult = await testBatchSavePerformance(
          globalConfig: globalConfig,
          batchSize: batchSize,
        );
        
        if (batchResult['success'] == true) {
          batchResults[batchSize] = batchResult;
          debugPrint('✅ 批量大小 $batchSize 测试成功');
        } else {
          debugPrint('❌ 批量大小 $batchSize 测试失败: ${batchResult['error']}');
          batchResults[batchSize] = {
            'success': false,
            'error': batchResult['error'],
          };
        }
        
        // 等待一段时间避免频率限制
        if (batchSize != batchSizes.last) {
          debugPrint('⏳ 等待3秒后继续下一个测试...');
          await Future.delayed(Duration(seconds: 3));
        }
        
      } catch (e) {
        debugPrint('❌ 批量大小 $batchSize 测试异常: $e');
        batchResults[batchSize] = {
          'success': false,
          'error': e.toString(),
        };
      }
    }
    
    // 输出性能对比结果
    debugPrint('\n📊 === 批量大小性能对比结果 ===');
    debugPrint('批量大小\t总耗时(ms)\t平均耗时(ms/个)\t成功数\t失败数\t性能评级');
    debugPrint('--------\t--------\t------------\t------\t------\t--------');
    
    batchResults.forEach((batchSize, result) {
      if (result['success'] == true) {
        final totalDuration = result['totalDuration'];
        final avgTimePerEmail = result['avgTimePerEmail'];
        final successCount = result['successCount'];
        final errorCount = result['errorCount'];
        final performanceRating = result['performanceRating'];
        
        debugPrint('$batchSize\t\t$totalDuration\t\t${avgTimePerEmail.toStringAsFixed(2)}\t\t$successCount\t\t$errorCount\t\t$performanceRating');
      } else {
        debugPrint('$batchSize\t\t失败\t\t-\t\t-\t\t-\t\t-');
      }
    });
    
    // 找出最佳批量大小
    final validResults = batchResults.entries
        .where((e) => e.value['success'] == true)
        .toList();
    
    if (validResults.isNotEmpty) {
      final bestBatchSize = validResults.reduce((a, b) => 
        a.value['avgTimePerEmail'] < b.value['avgTimePerEmail'] ? a : b
      );
      
      debugPrint('\n🎯 推荐批量大小: ${bestBatchSize.key} (平均耗时: ${bestBatchSize.value['avgTimePerEmail'].toStringAsFixed(2)}ms/个)');
      
      results['bestBatchSize'] = bestBatchSize.key;
      results['bestAvgTimePerEmail'] = bestBatchSize.value['avgTimePerEmail'];
    }
    
    results['batchResults'] = batchResults;
    results['success'] = true;
    
    return results;
  }

  /// 格式化性能报告
  static String formatPerformanceReport(Map<String, dynamic> results) {
    if (results['success'] != true) {
      return '❌ 性能测试失败: ${results['error']}';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('📊 性能测试报告');
    buffer.writeln('==============');
    buffer.writeln('📈 总体统计:');
    buffer.writeln('   - 总耗时: ${results['totalDuration']}ms');
    buffer.writeln('   - 批量大小: ${results['batchSize']} 个');
    buffer.writeln('   - 平均每收件人耗时: ${results['avgTimePerEmail'].toStringAsFixed(2)}ms');
    buffer.writeln('   - 性能评级: ${results['performanceRating']}');
    buffer.writeln('');
    buffer.writeln('📋 保存结果:');
    buffer.writeln('   - 成功数量: ${results['successCount']} 个');
    buffer.writeln('   - 失败数量: ${results['errorCount']} 个');
    buffer.writeln('   - 已存在数量: ${results['existCount']} 个');
    
    return buffer.toString();
  }
} 