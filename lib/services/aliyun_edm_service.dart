import 'dart:math';
import 'package:dio/dio.dart';
import '../utils/aliyun_signer.dart';
import '../models/receiver_detail.dart';
import 'config_service.dart';

class AliyunEDMService {
  ConfigService? _configService;

  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://dm.aliyuncs.com'));

  // 初始化配置服务
  Future<void> _initConfigService() async {
    _configService ??= await ConfigService.getInstance();
  }
  
  // 获取Access Key ID
  Future<String> _getAccessKeyId() async {
    await _initConfigService();
    final accessKeyId = _configService!.getAccessKeyId();
    if (accessKeyId == null || accessKeyId.isEmpty) {
      throw Exception('Access Key ID未配置，请先在设置中配置阿里云AccessKey');
    }
    return accessKeyId;
  }
  
  // 获取Access Key Secret
  Future<String> _getAccessKeySecret() async {
    await _initConfigService();
    final accessKeySecret = _configService!.getAccessKeySecret();
    if (accessKeySecret == null || accessKeySecret.isEmpty) {
      throw Exception('Access Key Secret未配置，请先在设置中配置阿里云AccessKey');
    }
    return accessKeySecret;
  }
  
  // 检查配置是否完整
  Future<bool> isConfigured() async {
    await _initConfigService();
    return _configService!.isConfigured();
  }

  Future<List<Map<String, dynamic>>> queryReceivers() async {
    final params = await _buildCommonParams("QueryReceiverByParam");
    final accessKeySecret = await _getAccessKeySecret();

    final signature = AliyunSigner.sign(params, accessKeySecret, 'GET');
    params['Signature'] = signature;

    final response = await _dio.get('', queryParameters: params);
    final responseData = response.data;
    final data = responseData['data'];
    final receivers = data != null ? data['receiver'] : null;

    if (receivers != null && receivers is List) {
      return List<Map<String, dynamic>>.from(receivers);
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> deleteReceiver(String receiverName) async {
    final params = await _buildCommonParams("DeleteReceiver");
    params['ReceiverId'] = receiverName;
    final accessKeySecret = await _getAccessKeySecret();

    final signature = AliyunSigner.sign(params, accessKeySecret, 'GET');
    params['Signature'] = signature;

    await _dio.get('', queryParameters: params);
  }

  Future<ReceiverDetail?> getReceiverDetail(
    String receiverId, {
    String keyWord = '',
    int pageSize = 50,
    String nextStart = '',
  }) async {
    // 校验 keyWord 长度
    if (keyWord.length > 50) {
      throw ArgumentError('Email 长度不能超过50字符');
    }

    // 校验 pageSize
    if (pageSize > 50) {
      pageSize = 50;
    }

    final params = await _buildCommonParams("QueryReceiverDetail");
    params['ReceiverId'] = receiverId;
    params['PageSize'] = pageSize.toString();
    if (keyWord.isNotEmpty) params['KeyWord'] = keyWord;
    if (nextStart.isNotEmpty) params['NextStart'] = nextStart;
    final accessKeySecret = await _getAccessKeySecret();

    final signature = AliyunSigner.sign(params, accessKeySecret, 'GET');
    params['Signature'] = signature;

    try {
    final response = await _dio.get('', queryParameters: params);
      final detail = ReceiverDetail.fromJson(response.data);
      
      // 如果返回的数据总数小于pageSize,说明已经没有更多数据了
      if (detail.members.length < pageSize) {
        detail.setNextStart(null);
      }
      
      return detail;
    } catch (e) {
        if (e is DioException) {
          print('获取收件人详情失败: ${e.message}');
          print('响应内容: ${e.response?.data}');
        } else {
          print('获取收件人详情失败: $e');
        }
    }

    return null;
  }

  Future<void> createReceiver(String name, {String? alias, String? desc}) async {
    final params = await _buildCommonParams("CreateReceiver");
    params['ReceiversName'] = name;
    if (alias != null && alias.isNotEmpty) {
      params['ReceiversAlias'] = alias;
    }
    params['Desc'] = desc ?? "新建收件人列表";
    final accessKeySecret = await _getAccessKeySecret();

    final signature = AliyunSigner.sign(params, accessKeySecret, 'GET');
    params['Signature'] = signature;

    print('CreateReceiver 请求参数:');
    params.forEach((key, value) {
      print('  $key: $value');
    });

    try {
      final response = await _dio.get('', queryParameters: params);
      print('CreateReceiver 响应: ${response.data}');
    } catch (e) {
      print('CreateReceiver 错误: $e');
      if (e is DioException) {
        print('错误详情: ${e.response?.data}');
        print('状态码: ${e.response?.statusCode}');
        print('错误信息: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> deleteReceiverDetail(String receiverId, String email) async {
    final params = await _buildCommonParams("DeleteReceiverDetail");
    params['ReceiverId'] = receiverId;
    params['Email'] = email;
    final accessKeySecret = await _getAccessKeySecret();

    final signature = AliyunSigner.sign(params, accessKeySecret, 'GET');
    params['Signature'] = signature;

    await _dio.get('', queryParameters: params);
  }

  Future<SaveReceiverDetailResponse> saveReceiverDetail(String receiverId, ReceiverDetailParams receiverParams) async {
    final params = await _buildCommonParams("SaveReceiverDetail");
    params['ReceiverId'] = receiverId;
    params['Detail'] = receiverParams.toDetailJson();
    final accessKeySecret = await _getAccessKeySecret();

    final signature = AliyunSigner.sign(params, accessKeySecret, 'POST');
    params['Signature'] = signature;

    print('SaveReceiverDetail 请求参数:');
    params.forEach((key, value) {
      print('  $key: $value');
    });

    try {
      final response = await _dio.post('', queryParameters: params);
      print('SaveReceiverDetail 响应: ${response.data}');
      return SaveReceiverDetailResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('SaveReceiverDetail 错误: $e');
      if (e is DioException) {
        print('错误详情: ${e.response?.data}');
        print('状态码: ${e.response?.statusCode}');
        print('错误信息: ${e.message}');
      }
      rethrow;
    }
  }

  Future<Map<String, String>> _buildCommonParams(String action) async {
    final accessKeyId = await _getAccessKeyId();
    return {
      'Action': action,
      'Format': 'JSON',
      'Version': '2015-11-23',
      'AccessKeyId': accessKeyId,
      'SignatureMethod': 'HMAC-SHA1',
      'Timestamp': DateTime.now().toUtc().toIso8601String(),
      'SignatureVersion': '1.0',
      'SignatureNonce': Random().nextInt(999999).toString(),
    };
  }
}