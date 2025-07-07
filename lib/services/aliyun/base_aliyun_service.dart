import 'package:dio/dio.dart';
import 'package:aliyun_edm_manager/utils/aliyun_signer.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';

/// 阿里云服务基础类
/// 提供通用的配置管理和API请求功能
abstract class BaseAliyunService {
  GlobalConfigProvider? _globalConfigProvider;
  late final Dio _dio;

  BaseAliyunService() {
    _dio = Dio(BaseOptions(baseUrl: 'https://dm.aliyuncs.com'));
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
    final commonParams = _buildCommonParams(action);
    commonParams.addAll(params);
    
    final accessKeySecret = _getAccessKeySecret();
    final signature = AliyunSigner.sign(commonParams, accessKeySecret, 'GET');
    commonParams['Signature'] = signature;

    _logRequest(action, commonParams);

    try {
      final response = await _dio.get('', queryParameters: commonParams);
      _logResponse(action, response.data);
      return response;
    } catch (e) {
      _logError(action, e);
      rethrow;
    }
  }

  /// 执行POST请求
  Future<Response> post(String action, Map<String, String> params) async {
    final commonParams = _buildCommonParams(action);
    commonParams.addAll(params);
    
    final accessKeySecret = _getAccessKeySecret();
    final signature = AliyunSigner.sign(commonParams, accessKeySecret, 'POST');
    commonParams['Signature'] = signature;

    _logRequest(action, commonParams);

    try {
      final response = await _dio.post('', queryParameters: commonParams);
      _logResponse(action, response.data);
      return response;
    } catch (e) {
      _logError(action, e);
      rethrow;
    }
  }

  /// 记录请求日志
  void _logRequest(String action, Map<String, String> params) {
    print('$action 请求参数:');
    params.forEach((key, value) {
      print('  $key: $value');
    });
  }

  /// 记录响应日志
  void _logResponse(String action, dynamic data) {
    print('$action 响应: $data');
  }

  /// 记录错误日志
  void _logError(String action, dynamic error) {
    print('$action 错误: $error');
    if (error is DioException) {
      print('错误详情: ${error.response?.data}');
      print('状态码: ${error.response?.statusCode}');
      print('错误信息: ${error.message}');
    }
  }

  /// 参数验证：分页参数
  void validatePagination(int pageNo, int pageSize, {int maxPageSize = 50}) {
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