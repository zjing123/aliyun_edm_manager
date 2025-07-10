import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/sender/sender_address_model.dart';
import 'package:aliyun_edm_manager/constants/pagination_constants.dart';

/// 发信地址管理服务
/// 提供发信地址的查询、创建和删除功能
class SenderAddressService extends BaseAliyunService {
  
  /// 查询发信地址
  Future<QuerySenderAddressResponse> queryMailAddressByParam({
    String? keyWord,
    String? sendType,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    if (pageSize > PaginationConstants.senderAddressMaxPageSize) {
      pageSize = PaginationConstants.senderAddressMaxPageSize;
    }

    // 参数验证
    validatePagination(pageNo, pageSize, maxPageSize: PaginationConstants.senderAddressMaxPageSize);

    final params = <String, String>{
      'PageNo': pageNo.toString(),
      'PageSize': pageSize.toString(),
    };
    
    // 可选参数
    if (keyWord != null && keyWord.isNotEmpty) {
      params['KeyWord'] = keyWord;
    }
    if (sendType != null && sendType.isNotEmpty) {
      params['Sendtype'] = sendType;
    }

    print('QueryMailAddressByParam API 请求参数: $params');
    final response = await get("QueryMailAddressByParam", params);
    print('QueryMailAddressByParam API 返回数据: ${response.data}');
    
    return QuerySenderAddressResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 创建发信地址
  Future<CreateSenderAddressResponse> createMailAddress({
    required String accountName,
    String? replyAddress,
    required String sendType,
    String? password,
  }) async {
    // 参数验证
    if (accountName.isEmpty) {
      throw Exception('发信邮箱地址不能为空');
    }
    if (sendType.isEmpty || (sendType != 'batch' && sendType != 'trigger')) {
      throw Exception('发信类型必须为 batch 或 trigger');
    }

    final params = <String, String>{
      'AccountName': accountName,
      'Sendtype': sendType,
    };
    
    // 可选参数
    if (replyAddress != null && replyAddress.isNotEmpty) {
      params['ReplyAddress'] = replyAddress;
    }
    if (password != null && password.isNotEmpty) {
      params['Password'] = password;
    }

    print('CreateMailAddress API 请求参数: $params');
    final response = await get("CreateMailAddress", params);
    print('CreateMailAddress API 返回数据: ${response.data}');
    
    return CreateSenderAddressResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 删除发信地址
  Future<DeleteSenderAddressResponse> deleteMailAddress({
    required int mailAddressId,
  }) async {
    // 参数验证
    if (mailAddressId <= 0) {
      throw Exception('发信地址ID无效');
    }

    final params = <String, String>{
      'MailAddressId': mailAddressId.toString(),
    };

    print('DeleteMailAddress API 请求参数: $params');
    final response = await get("DeleteMailAddress", params);
    print('DeleteMailAddress API 返回数据: ${response.data}');
    
    return DeleteSenderAddressResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取所有发信地址
  Future<List<SenderAddressModel>> getAllSenderAddresses({
    String? keyWord,
    String? sendType,
    int pageNo = 1,
    int pageSize = PaginationConstants.senderAddressMaxPageSize,
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

  /// 获取可用的发信地址（状态为正常的）
  Future<List<SenderAddressModel>> getAvailableSenderAddresses({
    String? keyWord,
    String? sendType,
    int pageNo = 1,
    int pageSize = PaginationConstants.senderAddressDefaultPageSize,
  }) async {
    if (pageSize > PaginationConstants.senderAddressMaxPageSize) {
      pageSize = PaginationConstants.senderAddressMaxPageSize;
    }

    try {
      final allAddresses = await getAllSenderAddresses(
        keyWord: keyWord,
        sendType: sendType,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      
      // 过滤状态为正常的发信地址（AccountStatus为0表示正常）
      return allAddresses.where((address) => address.status == '0').toList();
    } catch (e) {
      print('获取可用发信地址失败: $e');
      return [];
    }
  }
}

/// 创建发信地址响应模型
class CreateSenderAddressResponse {
  final String requestId;
  final String? mailAddressId;
  final String? accountName;
  final String? errorCode;
  final String? errorMessage;

  CreateSenderAddressResponse({
    required this.requestId,
    this.mailAddressId,
    this.accountName,
    this.errorCode,
    this.errorMessage,
  });

  factory CreateSenderAddressResponse.fromJson(Map<String, dynamic> json) {
    return CreateSenderAddressResponse(
      requestId: json['RequestId'] ?? '',
      mailAddressId: json['MailAddressId']?.toString(),
      accountName: json['AccountName'],
      errorCode: json['Code'],
      errorMessage: json['Message'],
    );
  }

  bool get isSuccess => errorCode == null && mailAddressId != null;
}

/// 删除发信地址响应模型
class DeleteSenderAddressResponse {
  final String requestId;
  final String? errorCode;
  final String? errorMessage;

  DeleteSenderAddressResponse({
    required this.requestId,
    this.errorCode,
    this.errorMessage,
  });

  factory DeleteSenderAddressResponse.fromJson(Map<String, dynamic> json) {
    return DeleteSenderAddressResponse(
      requestId: json['RequestId'] ?? '',
      errorCode: json['Code'],
      errorMessage: json['Message'],
    );
  }

  bool get isSuccess => errorCode == null;
} 