import 'package:dio/dio.dart';
import 'package:aliyun_edm_manager/utils/aliyun_signer.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/constants/pagination_constants.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

/// 阿里云服务基础类
/// 提供通用的配置管理和API请求功能
abstract class BaseAliyunService {
  GlobalConfigProvider? _globalConfigProvider;
  late final Dio _dio;

  BaseAliyunService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://dm.aliyuncs.com',
      connectTimeout: const Duration(seconds: 60), // 增加连接超时时间
      receiveTimeout: const Duration(seconds: 120), // 增加接收超时时间，特别是批量操作
      sendTimeout: const Duration(seconds: 60), // 增加发送超时时间
      // 设置连接池
      maxRedirects: 3,
      // 添加重试配置
      validateStatus: (status) {
        return status != null && status < 500; // 只对5xx错误重试
      },
    ));
    
    // 设置拦截器用于日志
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));
    
    // 添加重试拦截器
    _dio.interceptors.add(RetryInterceptor());
  }

  /// 设置全局配置Provider
  void setGlobalConfigProvider(GlobalConfigProvider provider) {
    _globalConfigProvider = provider;
  }

  /// 检查配置是否完整
  bool _isConfigured() {
    return _globalConfigProvider?.isConfigured ?? false;
  }
  
  /// 获取Access Key ID
  String _getAccessKeyId() {
    if (!_isConfigured()) {
      throw Exception('阿里云AccessKey未配置，请先配置');
    }
    final accessKeyId = _globalConfigProvider!.accessKeyId;
    if (accessKeyId == null || accessKeyId.isEmpty) {
      throw Exception('Access Key ID未配置，请先在设置中配置阿里云AccessKey');
    }
    return accessKeyId;
  }
  
  /// 获取Access Key Secret
  String _getAccessKeySecret() {
    if (!_isConfigured()) {
      throw Exception('阿里云AccessKey未配置，请先配置');
    }
    final accessKeySecret = _globalConfigProvider!.accessKeySecret;
    if (accessKeySecret == null || accessKeySecret.isEmpty) {
      throw Exception('Access Key Secret未配置，请先在设置中配置阿里云AccessKey');
    }
    return accessKeySecret;
  }
  
  /// 检查配置是否完整（公开方法）
  bool isConfigured() {
    return _isConfigured();
  }

  /// 配置检查装饰器 - 自动检查配置并执行方法
  /// 使用示例:
  /// Future<T> myMethod() async {
  ///   return await withConfigCheck(() async {
  ///     // 你的服务逻辑
  ///     return result;
  ///   });
  /// }
  Future<T> withConfigCheck<T>(Future<T> Function() method) async {
    if (!_isConfigured()) {
      throw Exception('阿里云AccessKey未配置，请先配置');
    }
    return await method();
  }

  /// 配置检查装饰器 - 同步版本
  T withConfigCheckSync<T>(T Function() method) {
    if (!_isConfigured()) {
      throw Exception('阿里云AccessKey未配置，请先配置');
    }
    return method();
  }

  /// 构建通用请求参数
  Map<String, String> _buildCommonParams(String action) {
    final params = <String, String>{};
    
    // 必填参数
    params['Action'] = action;
    params['Version'] = '2015-11-23';
    params['AccessKeyId'] = _getAccessKeyId();
    params['SignatureMethod'] = 'HMAC-SHA1';
    params['SignatureVersion'] = '1.0';
    params['SignatureNonce'] = _generateNonce();
    params['Timestamp'] = _generateTimestamp();
    params['Format'] = 'JSON';
    
    return params;
  }

  /// 生成随机数
  String _generateNonce() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 生成时间戳
  String _generateTimestamp() {
    // 格式: 2023-01-01T12:00:00Z
    return DateTime.now().toUtc().toIso8601String();
  }

  /// 执行GET请求
  Future<Response> get(String action, Map<String, String> params) async {
    final requestStartTime = DateTime.now();
    final requestId = _generateRequestId();
    
    debugPrint('🚀 [API请求开始] $action (ID: $requestId) - ${requestStartTime.toIso8601String()}');
    
    final commonParams = _buildCommonParams(action);
    commonParams.addAll(params);
    
    final accessKeySecret = _getAccessKeySecret();
    final signature = AliyunSigner.sign(commonParams, accessKeySecret, 'GET');
    commonParams['Signature'] = signature;

    _logRequest(action, commonParams, requestId);

    try {
      final response = await _dio.get('', queryParameters: commonParams);
      final requestEndTime = DateTime.now();
      final duration = requestEndTime.difference(requestStartTime);
      
      _logResponse(action, response.data, requestId, duration);
      debugPrint('✅ [API请求成功] $action (ID: $requestId) - 耗时: ${duration.inMilliseconds}ms');
      
      return response;
    } catch (e) {
      final requestEndTime = DateTime.now();
      final duration = requestEndTime.difference(requestStartTime);
      
      _logError(action, e, requestId, duration);
      debugPrint('❌ [API请求失败] $action (ID: $requestId) - 耗时: ${duration.inMilliseconds}ms - 错误: $e');
      rethrow;
    }
  }

  /// 执行POST请求
  Future<Response> post(String action, Map<String, String> params) async {
    final requestStartTime = DateTime.now();
    final requestId = _generateRequestId();
    
    debugPrint('🚀 [API请求开始] $action (ID: $requestId) - ${requestStartTime.toIso8601String()}');
    
    final commonParams = _buildCommonParams(action);
    commonParams.addAll(params);
    
    final accessKeySecret = _getAccessKeySecret();
    final signature = AliyunSigner.sign(commonParams, accessKeySecret, 'POST');
    commonParams['Signature'] = signature;

    _logRequest(action, commonParams, requestId);

    try {
      final response = await _dio.post('', queryParameters: commonParams);
      final requestEndTime = DateTime.now();
      final duration = requestEndTime.difference(requestStartTime);
      
      _logResponse(action, response.data, requestId, duration);
      debugPrint('✅ [API请求成功] $action (ID: $requestId) - 耗时: ${duration.inMilliseconds}ms');
      
      return response;
    } catch (e) {
      final requestEndTime = DateTime.now();
      final duration = requestEndTime.difference(requestStartTime);
      
      _logError(action, e, requestId, duration);
      debugPrint('❌ [API请求失败] $action (ID: $requestId) - 耗时: ${duration.inMilliseconds}ms - 错误: $e');
      rethrow;
    }
  }

  /// 生成请求ID
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 记录请求日志
  void _logRequest(String action, Map<String, String> params, String requestId) {
    debugPrint('📤 [请求参数] $action (ID: $requestId):');
    params.forEach((key, value) {
      if (key != 'AccessKeyId' && key != 'AccessKeySecret') { // 不记录敏感信息
        debugPrint('  $key: $value');
      }
    });
  }

  /// 记录响应日志
  void _logResponse(String action, dynamic data, String requestId, Duration duration) {
    debugPrint('📥 [响应数据] $action (ID: $requestId) - 耗时: ${duration.inMilliseconds}ms:');
    debugPrint('  $data');
  }

  /// 记录错误日志
  void _logError(String action, dynamic error, String requestId, Duration duration) {
    debugPrint('💥 [错误详情] $action (ID: $requestId) - 耗时: ${duration.inMilliseconds}ms:');
    debugPrint('  错误: $error');
    if (error is DioException) {
      debugPrint('  状态码: ${error.response?.statusCode}');
      debugPrint('  错误类型: ${error.type}');
      debugPrint('  错误信息: ${error.message}');
      debugPrint('  响应数据: ${error.response?.data}');
    }
  }

  /// 参数验证：分页参数
  void validatePagination(int pageNo, int pageSize, {int maxPageSize = PaginationConstants.defaultMaxPageSize}) {
    if (pageNo < 1) {
      throw ArgumentError('页码必须大于0');
    }
    if (pageSize > maxPageSize) {
      throw ArgumentError('每页数量不能超过$maxPageSize');
    }
    if (pageSize < 1) {
      throw ArgumentError('每页数量必须大于0');
    }
  }

  /// 参数验证：字符串长度
  void validateStringLength(String value, String fieldName, int maxLength) {
    if (value.length > maxLength) {
      throw ArgumentError('$fieldName 长度不能超过$maxLength字符');
    }
  }
}

/// 重试拦截器
class RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final retryCount = requestOptions.extra['retryCount'] ?? 0;
    
    if (retryCount < maxRetries && _shouldRetry(err)) {
      debugPrint('🔄 [重试] 请求失败，准备重试 (${retryCount + 1}/$maxRetries) - ${requestOptions.path}');
      
      // 等待一段时间后重试
      await Future.delayed(retryDelay);
      
      // 更新重试计数
      requestOptions.extra['retryCount'] = retryCount + 1;
      
      try {
        final response = await Dio().fetch(requestOptions);
        debugPrint('✅ [重试成功] 请求重试成功 - ${requestOptions.path}');
        handler.resolve(response);
        return;
      } catch (e) {
        debugPrint('❌ [重试失败] 请求重试失败 - ${requestOptions.path}, 错误: $e');
        handler.reject(err);
        return;
      }
    }
    
    handler.reject(err);
  }

  /// 判断是否应该重试
  bool _shouldRetry(DioException err) {
    // 网络错误、超时错误、服务器错误都应该重试
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.connectionError ||
           (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
} 