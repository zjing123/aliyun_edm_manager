import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/sender/sender_address_model.dart';

/// 发信地址管理服务
/// 提供发信地址的查询和管理功能
class SenderAddressService extends BaseAliyunService {
  
  /// 查询发信地址
  Future<QuerySenderAddressResponse> queryMailAddressByParam({
    String? keyWord,
    String? sendType,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    // 参数验证
    validatePagination(pageNo, pageSize);

    final params = <String, String>{
      'PageNo': pageNo.toString(),
      'PageSize': pageSize.toString(),
    };
    
    // 可选参数
    if (keyWord != null && keyWord.isNotEmpty) {
      params['KeyWord'] = keyWord;
    }
    if (sendType != null && sendType.isNotEmpty) {
      params['SendType'] = sendType;
    }

    final response = await get("QueryMailAddressByParam", params);
    return QuerySenderAddressResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取所有发信地址
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

  /// 获取可用的发信地址（状态为正常的）
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
      
      // 过滤状态为正常的发信地址（AccountStatus为0表示正常）
      return allAddresses.where((address) => address.status == '0').toList();
    } catch (e) {
      print('获取可用发信地址失败: $e');
      return [];
    }
  }
} 