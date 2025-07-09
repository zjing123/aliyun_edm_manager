import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_statistics_model.dart';
import 'package:aliyun_edm_manager/models/sender_statistics/sending_detail_model.dart';

class SenderStatisticsService extends BaseAliyunService {
  SenderStatisticsService();

  /// 获取指定条件下的发送数据
  /// 对应API: SenderStatisticsByTagNameAndBatchID
  Future<SendingStatisticsModel> getSendingStatistics({
    String? accountName,
    required DateTime startTime,
    required DateTime endTime,
    String? tagName,
    String? dedicatedIpPoolId,
    String? dedicatedIp,
    String? esp,
  }) async {
    try {
      // 验证时间范围
      _validateTimeRange(startTime, endTime);
      
      final params = <String, String>{
        'StartTime': _formatDate(startTime),
        'EndTime': _formatDate(endTime),
      };

      if (accountName != null && accountName.isNotEmpty) {
        params['AccountName'] = accountName;
      }
      if (tagName != null && tagName.isNotEmpty) {
        params['TagName'] = tagName;
      }
      if (dedicatedIpPoolId != null && dedicatedIpPoolId.isNotEmpty) {
        params['DedicatedIpPoolId'] = dedicatedIpPoolId;
      }
      if (dedicatedIp != null && dedicatedIp.isNotEmpty) {
        params['DedicatedIp'] = dedicatedIp;
      }
      if (esp != null && esp.isNotEmpty) {
        params['Esp'] = esp;
      }

      print('发送统计API请求参数: $params');
      final response = await get('SenderStatisticsByTagNameAndBatchID', params);
      
      print('发送统计API响应: ${response.data}');
      
      // 解析API响应
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        try {
          return SendingStatisticsModel.fromJson(responseData);
        } catch (e) {
          print('数据模型解析错误: $e');
          print('响应数据结构: $responseData');
          throw Exception('数据模型解析失败: $e');
        }
      } else {
        print('API响应格式错误，期望Map<String, dynamic>，实际类型: ${responseData.runtimeType}');
        throw Exception('API响应格式错误，期望Map类型');
      }
    } catch (e) {
      print('获取发送统计数据失败: $e');
      throw Exception('获取发送统计数据失败: $e');
    }
  }

  /// 获取发送详情列表
  /// 注意：这个API可能需要使用其他接口，当前使用模拟数据
  Future<List<SendingDetailModel>> getSendingDetails({
    String? recipient,
    SendingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // 这里应该调用相应的API，但目前使用模拟数据
      // 实际实现时需要根据具体的API接口调整
      
      return [
        SendingDetailModel(
          recipient: 'user1@example.com',
          subject: '欢迎注册我们的服务',
          status: SendingStatus.sent,
          sendTime: DateTime.now().subtract(const Duration(hours: 2)),
          openTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        ),
        SendingDetailModel(
          recipient: 'user2@example.com',
          subject: '密码重置提醒',
          status: SendingStatus.opened,
          sendTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
          openTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 10)),
        ),
        SendingDetailModel(
          recipient: 'user3@example.com',
          subject: '订单确认',
          status: SendingStatus.failed,
          sendTime: DateTime.now().subtract(const Duration(hours: 4, minutes: 40)),
        ),
        SendingDetailModel(
          recipient: 'user4@example.com',
          subject: '月度账单',
          status: SendingStatus.sent,
          sendTime: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ];
    } catch (e) {
      throw Exception('获取发送详情失败: $e');
    }
  }

  /// 获取发送趋势数据
  /// 通过多次调用SenderStatisticsByTagNameAndBatchID获取趋势数据
  Future<List<SendingStatisticsModel>> getSendingTrend({
    required int days,
    String? accountName,
    String? tagName,
  }) async {
    try {
      final List<SendingStatisticsModel> trend = [];
      final now = DateTime.now();
      
      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startTime = date;
        final endTime = date;
        
        try {
          final statistics = await getSendingStatistics(
            accountName: accountName,
            startTime: startTime,
            endTime: endTime,
            tagName: tagName,
          );
          trend.add(statistics);
        } catch (e) {
          // 如果某天没有数据，跳过
          print('获取${_formatDate(date)}的数据失败: $e');
        }
      }
      
      return trend;
    } catch (e) {
      throw Exception('获取发送趋势数据失败: $e');
    }
  }

  /// 格式化日期为yyyy-MM-dd格式
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 验证时间范围
  void _validateTimeRange(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sevenDaysLater = startTime.add(const Duration(days: 7));
    
    if (startTime.isBefore(thirtyDaysAgo)) {
      throw ArgumentError('起始时间不能早于30天前');
    }
    
    if (endTime.isAfter(sevenDaysLater)) {
      throw ArgumentError('时间跨度不能超过7天');
    }
    
    if (endTime.isBefore(startTime)) {
      throw ArgumentError('结束时间不能早于起始时间');
    }
  }
} 