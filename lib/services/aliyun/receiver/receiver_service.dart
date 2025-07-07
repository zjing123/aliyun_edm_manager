import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_detail.dart';

/// 收件人管理服务
/// 提供收件人列表和收件人详情的增删改查功能
class ReceiverService extends BaseAliyunService {
  
  /// 查询收件人列表
  Future<List<Map<String, dynamic>>> queryReceivers() async {
    final response = await get("QueryReceiverByParam", {});
    final responseData = response.data;
    final data = responseData['data'];
    final receivers = data != null ? data['receiver'] : null;

    if (receivers != null && receivers is List) {
      return List<Map<String, dynamic>>.from(receivers);
    }
    return <Map<String, dynamic>>[];
  }

  /// 创建收件人列表
  Future<CreateReceiverResponse> createReceiver(String name, {String? alias, String? desc}) async {
    final params = <String, String>{
      'ReceiversName': name,
      'Desc': desc ?? "新建收件人列表",
    };
    
    if (alias != null && alias.isNotEmpty) {
      params['ReceiversAlias'] = alias;
    }

    final response = await get("CreateReceiver", params);
    return CreateReceiverResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 删除收件人列表
  Future<void> deleteReceiver(String receiverName) async {
    await get("DeleteReceiver", {'ReceiverId': receiverName});
  }

  /// 查询收件人详情
  Future<ReceiverDetail?> getReceiverDetail(
    String receiverId, {
    String keyWord = '',
    int pageSize = 50,
    String nextStart = '',
  }) async {
    // 参数验证
    validateStringLength(keyWord, 'Email', 50);
    validatePagination(1, pageSize);

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
      
      return detail;
    } catch (e) {
      print('获取收件人详情失败: $e');
      return null;
    }
  }

  /// 保存单个收件人详情
  Future<SaveReceiverDetailResponse> saveReceiverDetail(String receiverId, ReceiverDetailParams receiverParams) async {
    final params = <String, String>{
      'ReceiverId': receiverId,
      'Detail': receiverParams.toDetailJson(),
    };

    final response = await post("SaveReceiverDetail", params);
    return SaveReceiverDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 批量保存收件人详情
  Future<SaveReceiverDetailResponse> saveReceiverDetails(String receiverId, List<ReceiverDetailParams> receiverParamsList) async {
    final params = <String, String>{
      'ReceiverId': receiverId,
      'Detail': receiverParamsList.map((param) => param.toDetailJson()).join(','),
    };

    final response = await post("SaveReceiverDetail", params);
    return SaveReceiverDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 删除收件人详情
  Future<void> deleteReceiverDetail(String receiverId, String email) async {
    await get("DeleteReceiverDetail", {
      'ReceiverId': receiverId,
      'Email': email,
    });
  }
} 