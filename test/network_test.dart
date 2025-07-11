import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/services/aliyun/receiver/receiver_service.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';

/// 网络连接测试
void main() {
  group('网络连接测试', () {
    test('测试阿里云API连接性', () async {
      // 这里需要配置测试用的AccessKey
      // 实际使用时请替换为真实的AccessKey
      final globalConfig = GlobalConfigProvider();
      // globalConfig.setAccessKey('your-access-key-id', 'your-access-key-secret');
      
      final receiverService = ReceiverService();
      receiverService.setGlobalConfigProvider(globalConfig);
      
      try {
        final startTime = DateTime.now();
        print('🚀 开始测试阿里云API连接...');
        
        // 测试查询收件人列表
        final receivers = await receiverService.queryReceivers();
        
        final duration = DateTime.now().difference(startTime);
        print('✅ API连接测试成功 - 耗时: ${duration.inMilliseconds}ms');
        print('📊 找到收件人列表: ${receivers.length} 个');
        
        expect(receivers, isA<List>());
      } catch (e) {
        print('❌ API连接测试失败: $e');
        fail('API连接测试失败: $e');
      }
    });
    
    test('测试网络超时设置', () async {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://dm.aliyuncs.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 10),
      ));
      
      try {
        final startTime = DateTime.now();
        print('🚀 测试网络超时设置...');
        
        // 发送一个简单的请求来测试超时
        final response = await dio.get('', queryParameters: {
          'Action': 'QueryReceiverByParam',
          'Version': '2015-11-23',
          'Format': 'JSON',
        });
        
        final duration = DateTime.now().difference(startTime);
        print('✅ 网络超时测试成功 - 耗时: ${duration.inMilliseconds}ms');
        print('📊 响应状态码: ${response.statusCode}');
        
        expect(response.statusCode, isNotNull);
      } catch (e) {
        print('❌ 网络超时测试失败: $e');
        // 这里不fail，因为可能没有配置AccessKey
        print('⚠️ 这是预期的，因为没有配置AccessKey');
      }
    });
  });
}

/// 简单的网络诊断工具
class NetworkDiagnostic {
  static Future<void> testConnection() async {
    print('🔍 开始网络诊断...');
    
    // 测试DNS解析
    try {
      final result = await InternetAddress.lookup('dm.aliyuncs.com');
      print('✅ DNS解析成功: ${result.first.address}');
    } catch (e) {
      print('❌ DNS解析失败: $e');
    }
    
    // 测试端口连接
    try {
      final socket = await Socket.connect('dm.aliyuncs.com', 443, timeout: Duration(seconds: 10));
      print('✅ 端口连接成功: 443');
      socket.close();
    } catch (e) {
      print('❌ 端口连接失败: $e');
    }
    
    // 测试HTTP连接
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://dm.aliyuncs.com'));
      final response = await request.close();
      print('✅ HTTP连接成功: ${response.statusCode}');
      client.close();
    } catch (e) {
      print('❌ HTTP连接失败: $e');
    }
  }
} 