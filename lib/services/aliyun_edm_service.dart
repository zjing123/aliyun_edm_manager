import 'dart:math';
import 'package:dio/dio.dart';
import '../utils/aliyun_signer.dart';
import '../models/receiver_detail.dart';
import '../models/batch_send_task_model.dart';
import '../models/template_model.dart';
import '../models/sender_address_model.dart';
import '../providers/global_config_provider.dart';
import '../constants/template_constants.dart';

class AliyunEdmService {
  GlobalConfigProvider? _globalConfigProvider;

  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://dm.aliyuncs.com'));

  // 设置全局配置Provider
  void setGlobalConfigProvider(GlobalConfigProvider provider) {
    _globalConfigProvider = provider;
  }

  // 检查配置是否完整
  bool _isConfigured() {
    return _globalConfigProvider?.isConfigured ?? false;
  }
  
  // 获取Access Key ID
  String _getAccessKeyId() {
    if (!_isConfigured()) {
      throw Exception('阿里云AccessKey未配置，请先配置');
    }
    final accessKeyId = _globalConfigProvider!.accessKeyId;
    print('AliyunEDMService._getAccessKeyId: $accessKeyId'); // 添加调试信息
    if (accessKeyId == null || accessKeyId.isEmpty) {
      throw Exception('Access Key ID未配置，请先在设置中配置阿里云AccessKey');
    }
    return accessKeyId;
  }
  
  // 获取Access Key Secret
  String _getAccessKeySecret() {
    if (!_isConfigured()) {
      throw Exception('阿里云AccessKey未配置，请先配置');
    }
    final accessKeySecret = _globalConfigProvider!.accessKeySecret;
    print('AliyunEDMService._getAccessKeySecret: ${accessKeySecret != null ? '已配置' : '未配置'}'); // 添加调试信息
    if (accessKeySecret == null || accessKeySecret.isEmpty) {
      throw Exception('Access Key Secret未配置，请先在设置中配置阿里云AccessKey');
    }
    return accessKeySecret;
  }
  
  // 检查配置是否完整
  bool isConfigured() {
    return _isConfigured();
  }

  Future<List<Map<String, dynamic>>> queryReceivers() async {
    final params = await _buildCommonParams("QueryReceiverByParam");
    final accessKeySecret = _getAccessKeySecret();

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
    final accessKeySecret = _getAccessKeySecret();

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
    final accessKeySecret = _getAccessKeySecret();

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

  Future<CreateReceiverResponse> createReceiver(String name, {String? alias, String? desc}) async {
    final params = await _buildCommonParams("CreateReceiver");
    params['ReceiversName'] = name;
    if (alias != null && alias.isNotEmpty) {
      params['ReceiversAlias'] = alias;
    }
    params['Desc'] = desc ?? "新建收件人列表";
    final accessKeySecret = _getAccessKeySecret();

    final signature = AliyunSigner.sign(params, accessKeySecret, 'GET');
    params['Signature'] = signature;

    print('CreateReceiver 请求参数:');
    params.forEach((key, value) {
      print('  $key: $value');
    });

    try {
      final response = await _dio.get('', queryParameters: params);
      print('CreateReceiver 响应: ${response.data}');
      return CreateReceiverResponse.fromJson(response.data as Map<String, dynamic>);
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
    final accessKeySecret = _getAccessKeySecret();

    final signature = AliyunSigner.sign(params, accessKeySecret, 'GET');
    params['Signature'] = signature;

    await _dio.get('', queryParameters: params);
  }

  Future<SaveReceiverDetailResponse> saveReceiverDetail(String receiverId, ReceiverDetailParams receiverParams) async {
    final params = await _buildCommonParams("SaveReceiverDetail");
    params['ReceiverId'] = receiverId;
    params['Detail'] = receiverParams.toDetailJson();
    final accessKeySecret = _getAccessKeySecret();

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

  Future<SaveReceiverDetailResponse> saveReceiverDetails(String receiverId, List<ReceiverDetailParams> receiverParamsList) async {
    final params = await _buildCommonParams("SaveReceiverDetail");
    params['ReceiverId'] = receiverId;
    params['Detail'] = ReceiverDetailParams.toBatchDetailJson(receiverParamsList);
    final accessKeySecret = _getAccessKeySecret();

    final signature = AliyunSigner.sign(params, accessKeySecret, 'POST');
    params['Signature'] = signature;

    print('SaveReceiverDetail 批量请求参数:');
    params.forEach((key, value) {
      print('  $key: $value');
    });

    try {
      final response = await _dio.post('', queryParameters: params);
      print('SaveReceiverDetail 批量响应: ${response.data}');
      return SaveReceiverDetailResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('SaveReceiverDetail 批量错误: $e');
      if (e is DioException) {
        print('错误详情: ${e.response?.data}');
        print('状态码: ${e.response?.statusCode}');
        print('错误信息: ${e.message}');
      }
      rethrow;
    }
  }

  Future<Map<String, String>> _buildCommonParams(String action) async {
    final accessKeyId = _getAccessKeyId();
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

  // 查询邮件模板
  Future<QueryTemplateResponse> queryTemplateByParam({
    String? templateName,
    String? templateStatus,
    String? templateType,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    // 参数验证
    if (pageNo < 1) {
      pageNo = 1;
    }
    if (pageSize > 50) {
      pageSize = 50;
    }
    if (pageSize < 1) {
      pageSize = 10;
    }

    final params = await _buildCommonParams("QueryTemplateByParam");
    
    // 添加可选参数
    if (templateName != null && templateName.isNotEmpty) {
      params['TemplateName'] = templateName;
    }
    if (templateStatus != null && templateStatus.isNotEmpty) {
      params['TemplateStatus'] = templateStatus;
    }
    if (templateType != null && templateType.isNotEmpty) {
      params['TemplateType'] = templateType;
    }
    
    params['PageNo'] = pageNo.toString();
    params['PageSize'] = pageSize.toString();
    
    final accessKeySecret = _getAccessKeySecret();
    final signature = AliyunSigner.sign(params, accessKeySecret, 'GET');
    params['Signature'] = signature;

    print('QueryTemplateByParam 请求参数:');
    params.forEach((key, value) {
      print('  $key: $value');
    });

    try {
      final response = await _dio.get('', queryParameters: params);
      print('QueryTemplateByParam 响应: ${response.data}');
      return QueryTemplateResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('QueryTemplateByParam 错误: $e');
      if (e is DioException) {
        print('错误详情: ${e.response?.data}');
        print('状态码: ${e.response?.statusCode}');
        print('错误信息: ${e.message}');
      }
      rethrow;
    }
  }

  // 获取所有模板（包括审核中、审核通过、审核未通过）
  Future<List<TemplateModel>> getAllTemplates({
    String? templateName,
    String? templateStatus = TemplateConstants.STATUS_APPROVED, // 默认只获取审核通过的模板
    String? templateType,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await queryTemplateByParam(
        templateName: templateName,
        templateStatus: templateStatus,
        templateType: templateType,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      return response.templates;
    } catch (e) {
      print('获取可用模板失败: $e');
      return [];
    }
  }

  // 获取可用的邮件模板
  Future<List<TemplateModel>> getAvailableTemplates({
    String? templateName,
    String? templateType,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    return await getAllTemplates(
      templateName: templateName,
      templateStatus: TemplateConstants.STATUS_APPROVED, // 过滤审核通过的模板
      templateType: templateType,
      pageNo: pageNo,
      pageSize: pageSize,
    );
  }

  // 查询发信地址
  Future<QuerySenderAddressResponse> queryMailAddressByParam({
    String? keyWord,
    String? sendType,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    // 参数验证
    if (pageNo < 1) {
      pageNo = 1;
    }
    if (pageSize > 50) {
      pageSize = 50;
    }
    if (pageSize < 1) {
      pageSize = 10;
    }

    final params = await _buildCommonParams("QueryMailAddressByParam");
    
    // 必填参数
    params['PageNo'] = pageNo.toString();
    params['PageSize'] = pageSize.toString();
    
    // 可选参数
    if (keyWord != null && keyWord.isNotEmpty) {
      params['KeyWord'] = keyWord;
    }
    if (sendType != null && sendType.isNotEmpty) {
      params['SendType'] = sendType;
    }
    
    final accessKeySecret = _getAccessKeySecret();
    final signature = AliyunSigner.sign(params, accessKeySecret, 'GET');
    params['Signature'] = signature;

    print('QueryMailAddressByParam 请求参数:');
    params.forEach((key, value) {
      print('  $key: $value');
    });

    try {
      final response = await _dio.get('', queryParameters: params);
      print('QueryMailAddressByParam 响应: ${response.data}');
      return QuerySenderAddressResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('QueryMailAddressByParam 错误: $e');
      if (e is DioException) {
        print('错误详情: ${e.response?.data}');
        print('状态码: ${e.response?.statusCode}');
        print('错误信息: ${e.message}');
      }
      rethrow;
    }
  }

  // 获取所有发信地址
  Future<List<SenderAddressModel>> getAllSenderAddresses({
    String? keyWord,
    String? sendType,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await queryMailAddressByParam(
        keyWord: keyWord,
        sendType: sendType,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      return response.addresses;
    } catch (e) {
      print('获取发信地址失败: $e');
      return [];
    }
  }

  // 获取可用的发信地址（状态为正常的）
  Future<List<SenderAddressModel>> getAvailableSenderAddresses({
    String? keyWord,
    String? sendType,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    try {
      final allAddresses = await getAllSenderAddresses(
        keyWord: keyWord,
        sendType: sendType,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      // 过滤状态为正常的发信地址
      return allAddresses.where((address) => address.status == '1').toList();
    } catch (e) {
      print('获取可用发信地址失败: $e');
      return [];
    }
  }

  // 批量发送任务相关方法
  Future<List<BatchSendTaskModel>> getBatchSendTasks() async {
    // 这里应该调用阿里云API获取批量发送任务列表
    // 目前返回空列表，实际实现时需要调用相应的API
    return [];
  }

  Future<bool> createBatchSendTask(BatchSendTaskModel task) async {
    // 这里应该调用阿里云API创建批量发送任务
    // 目前返回true，实际实现时需要调用相应的API
    return true;
  }

  Future<bool> deleteBatchSendTask(String taskId) async {
    // 这里应该调用阿里云API删除批量发送任务
    // 目前返回true，实际实现时需要调用相应的API
    return true;
  }

  Future<bool> updateBatchSendTaskStatus(String taskId, String status) async {
    // 这里应该调用阿里云API更新批量发送任务状态
    // 目前返回true，实际实现时需要调用相应的API
    return true;
  }
}