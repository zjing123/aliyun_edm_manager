import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/services/aliyun/receiver/receiver_service.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_detail.dart';

/// 批量保存性能测试
void main() {
  group('批量保存性能测试', () {
    late AliyunServiceManager serviceManager;
    late ReceiverService receiverService;
    late GlobalConfigProvider globalConfig;

    setUp(() {
      globalConfig = GlobalConfigProvider();
      serviceManager = AliyunServiceManager();
      receiverService = ReceiverService();
      receiverService.setGlobalConfigProvider(globalConfig);
    });

    test('测试添加500个收件人数据的耗时', () async {
      // 注意：这个测试需要配置有效的AccessKey
      // 请在运行前配置你的AccessKey
      // globalConfig.setAccessKey('your-access-key-id', 'your-access-key-secret');
      
      print('🚀 开始测试添加500个收件人数据的性能...');
      
      try {
        // 1. 创建测试用的收件人列表
        final testListName = '性能测试列表_${DateTime.now().millisecondsSinceEpoch}';
        final testAlias = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        print('📝 创建测试收件人列表: $testListName');
        final createStartTime = DateTime.now();
        final createResponse = await receiverService.createReceiver(testListName, alias: testAlias);
        final createDuration = DateTime.now().difference(createStartTime);
        
        print('✅ 收件人列表创建成功 - 耗时: ${createDuration.inMilliseconds}ms');
        print('📋 列表ID: ${createResponse.receiverId}');
        
        // 2. 生成500个测试邮箱
        final testEmails = <String>[];
        for (int i = 1; i <= 500; i++) {
          testEmails.add('test${i.toString().padLeft(3, '0')}@example.com');
        }
        
        print('📧 生成测试邮箱数据: ${testEmails.length} 个');
        
        // 3. 创建收件人参数列表
        final receiverParamsList = testEmails.map((email) => 
          ReceiverDetailParams(email: email, fieldValues: {})
        ).toList();
        
        print('📋 创建收件人参数列表完成');
        
        // 4. 测试批量保存性能
        print('💾 开始批量保存500个收件人...');
        final saveStartTime = DateTime.now();
        
        final saveResponse = await receiverService.saveReceiverDetails(
          createResponse.receiverId, 
          receiverParamsList
        );
        
        final saveDuration = DateTime.now().difference(saveStartTime);
        
        // 5. 输出详细的性能统计
        print('\n📊 === 批量保存性能测试结果 ===');
        print('📈 总体统计:');
        print('   - 收件人列表创建耗时: ${createDuration.inMilliseconds}ms');
        print('   - 批量保存总耗时: ${saveDuration.inMilliseconds}ms');
        print('   - 总耗时: ${(createDuration + saveDuration).inMilliseconds}ms');
        print('   - 测试数据量: ${testEmails.length} 个');
        print('   - 平均每收件人耗时: ${(saveDuration.inMilliseconds / testEmails.length).toStringAsFixed(2)}ms');
        
        print('\n📋 保存结果统计:');
        print('   - 成功数量: ${saveResponse.successCount} 个');
        print('   - 失败数量: ${saveResponse.errorCount} 个');
        print('   - 已存在数量: ${saveResponse.existList?.length ?? 0} 个');
        
        if (saveResponse.hasFailed && saveResponse.failList != null) {
          print('   - 失败列表: ${saveResponse.failList!.take(10).join(', ')}${saveResponse.failList!.length > 10 ? '...' : ''}');
        }
        
        // 6. 性能评估
        print('\n🎯 性能评估:');
        final avgTimePerEmail = saveDuration.inMilliseconds / testEmails.length;
        if (avgTimePerEmail < 10) {
          print('   ✅ 性能优秀: 平均每收件人 ${avgTimePerEmail.toStringAsFixed(2)}ms');
        } else if (avgTimePerEmail < 50) {
          print('   ⚠️ 性能一般: 平均每收件人 ${avgTimePerEmail.toStringAsFixed(2)}ms');
        } else {
          print('   ❌ 性能较差: 平均每收件人 ${avgTimePerEmail.toStringAsFixed(2)}ms');
        }
        
        // 7. 清理测试数据（可选）
        print('\n🗑️ 清理测试数据...');
        try {
          await receiverService.deleteReceiver(createResponse.receiverId);
          print('✅ 测试数据清理成功');
        } catch (e) {
          print('⚠️ 测试数据清理失败: $e');
        }
        
        // 8. 断言测试结果
        expect(saveResponse.successCount, greaterThan(0));
        expect(saveDuration.inMilliseconds, lessThan(60000)); // 应该不超过60秒
        
        print('\n✅ 性能测试完成！');
        
      } catch (e) {
        print('❌ 性能测试失败: $e');
        fail('性能测试失败: $e');
      }
    });

    test('测试不同批量大小的性能对比', () async {
      // 测试不同批量大小的性能
      final batchSizes = [100, 200, 300, 400, 500];
      final results = <int, Map<String, dynamic>>{};
      
      print('🚀 开始测试不同批量大小的性能对比...');
      
      for (final batchSize in batchSizes) {
        try {
          // 创建测试列表
          final testListName = '性能对比测试_${batchSize}_${DateTime.now().millisecondsSinceEpoch}';
          final testAlias = 'test_${batchSize}_${DateTime.now().millisecondsSinceEpoch}@example.com';
          
          final createResponse = await receiverService.createReceiver(testListName, alias: testAlias);
          
          // 生成测试数据
          final testEmails = <String>[];
          for (int i = 1; i <= batchSize; i++) {
            testEmails.add('test${i.toString().padLeft(3, '0')}@example.com');
          }
          
          final receiverParamsList = testEmails.map((email) => 
            ReceiverDetailParams(email: email, fieldValues: {})
          ).toList();
          
          // 测试保存性能
          final startTime = DateTime.now();
          final saveResponse = await receiverService.saveReceiverDetails(
            createResponse.receiverId, 
            receiverParamsList
          );
          final duration = DateTime.now().difference(startTime);
          
          results[batchSize] = {
            'duration': duration.inMilliseconds,
            'successCount': saveResponse.successCount,
            'errorCount': saveResponse.errorCount,
            'avgTimePerEmail': duration.inMilliseconds / batchSize,
          };
          
          print('📊 批量大小 $batchSize: ${duration.inMilliseconds}ms (${(duration.inMilliseconds / batchSize).toStringAsFixed(2)}ms/个)');
          
          // 清理测试数据
          try {
            await receiverService.deleteReceiver(createResponse.receiverId);
          } catch (e) {
            // 忽略清理错误
          }
          
          // 等待一段时间避免频率限制
          await Future.delayed(Duration(seconds: 2));
          
        } catch (e) {
          print('❌ 批量大小 $batchSize 测试失败: $e');
          results[batchSize] = {
            'duration': -1,
            'successCount': 0,
            'errorCount': 0,
            'avgTimePerEmail': -1,
          };
        }
      }
      
      // 输出性能对比结果
      print('\n📊 === 批量大小性能对比结果 ===');
      print('批量大小\t总耗时(ms)\t平均耗时(ms/个)\t成功数\t失败数');
      print('--------\t--------\t------------\t------\t------');
      
      results.forEach((batchSize, result) {
        if (result['duration'] > 0) {
          print('$batchSize\t\t${result['duration']}\t\t${result['avgTimePerEmail'].toStringAsFixed(2)}\t\t${result['successCount']}\t\t${result['errorCount']}');
        } else {
          print('$batchSize\t\t失败\t\t-\t\t-\t\t-');
        }
      });
      
      // 找出最佳批量大小
      final validResults = results.entries.where((e) => e.value['duration'] > 0).toList();
      if (validResults.isNotEmpty) {
        final bestBatchSize = validResults.reduce((a, b) => 
          a.value['avgTimePerEmail'] < b.value['avgTimePerEmail'] ? a : b
        );
        print('\n🎯 推荐批量大小: ${bestBatchSize.key} (平均耗时: ${bestBatchSize.value['avgTimePerEmail'].toStringAsFixed(2)}ms/个)');
      }
    });
  });
}

/// 性能测试工具类
class PerformanceTestUtil {
  /// 生成测试邮箱列表
  static List<String> generateTestEmails(int count, {String prefix = 'test'}) {
    final emails = <String>[];
    for (int i = 1; i <= count; i++) {
      emails.add('${prefix}${i.toString().padLeft(3, '0')}@example.com');
    }
    return emails;
  }
  
  /// 格式化耗时显示
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inMilliseconds}ms';
    } else {
      return '${duration.inSeconds}s ${duration.inMilliseconds % 1000}ms';
    }
  }
  
  /// 计算性能评分
  static String getPerformanceRating(double avgTimePerEmail) {
    if (avgTimePerEmail < 10) return '优秀';
    if (avgTimePerEmail < 50) return '良好';
    if (avgTimePerEmail < 100) return '一般';
    return '较差';
  }
} 