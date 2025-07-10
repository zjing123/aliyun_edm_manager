import 'package:aliyun_edm_manager/services/aliyun/base_aliyun_service.dart';
import 'package:aliyun_edm_manager/models/track/track_model.dart';
import 'package:aliyun_edm_manager/constants/pagination_constants.dart';

/// 跟踪数据管理服务
/// 提供邮件跟踪数据的查询功能
class TrackService extends BaseAliyunService {
  
  /// 获取跟踪数据列表
  Future<GetTrackListResponse> getTrackList({
    String? startTime,
    String? endTime,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    // 参数验证
    validatePagination(pageNo, pageSize, maxPageSize: PaginationConstants.trackMaxPageSize);

    final params = <String, String>{
      'PageNo': pageNo.toString(),
      'PageSize': pageSize.toString(),
    };
    
    // 可选参数
    if (startTime != null && startTime.isNotEmpty) {
      params['StartTime'] = startTime;
    }
    if (endTime != null && endTime.isNotEmpty) {
      params['EndTime'] = endTime;
    }

    print('GetTrackList API 请求参数: $params');
    final response = await get("GetTrackList", params);
    print('GetTrackList API 返回数据: ${response.data}');
    
    return GetTrackListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 根据发信地址和标签获取跟踪数据
  Future<GetTrackListByMailFromAndTagNameResponse> getTrackListByMailFromAndTagName({
    required String startTime,
    required String endTime,
    String? accountName,
    String? tagName,
    String? dedicatedIpPoolId,
    String? dedicatedIp,
    String? esp,
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    // 参数验证
    validatePagination(pageNo, pageSize, maxPageSize: PaginationConstants.trackMaxPageSize);

    final params = <String, String>{
      'StartTime': startTime,
      'EndTime': endTime,
      'PageNumber': pageNo.toString(),
      'PageSize': pageSize.toString(),
    };
    
    // 可选参数
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

    print('GetTrackListByMailFromAndTagName API 请求参数: $params');
    final response = await get("GetTrackListByMailFromAndTagName", params);
    print('GetTrackListByMailFromAndTagName API 返回数据: ${response.data}');
    
    return GetTrackListByMailFromAndTagNameResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取跟踪数据统计信息
  Future<Map<String, dynamic>> getTrackStatistics({
    String? startTime,
    String? endTime,
    String? accountName,
    String? tagName,
  }) async {
    try {
      final response = await getTrackListByMailFromAndTagName(
        startTime: startTime ?? _getDefaultStartTime(),
        endTime: endTime ?? _getDefaultEndTime(),
        accountName: accountName,
        tagName: tagName,
        pageSize: 1000, // 获取更多数据用于统计
      );
      
      if (response.trackList.isEmpty) {
        return {
          'totalSent': 0,
          'totalOpened': 0,
          'totalClicked': 0,
          'openRate': 0.0,
          'clickRate': 0.0,
        };
      }

      int totalSent = 0;
      int totalOpened = 0;
      int totalClicked = 0;

      for (final record in response.trackList) {
        totalSent += int.tryParse(record.totalNumber) ?? 0;
        totalOpened += int.tryParse(record.rcptOpenCount) ?? 0;
        totalClicked += int.tryParse(record.rcptClickCount) ?? 0;
      }

      final openRate = totalSent > 0 ? (totalOpened / totalSent * 100) : 0.0;
      final clickRate = totalSent > 0 ? (totalClicked / totalSent * 100) : 0.0;

      return {
        'totalSent': totalSent,
        'totalOpened': totalOpened,
        'totalClicked': totalClicked,
        'openRate': openRate,
        'clickRate': clickRate,
      };
    } catch (e) {
      print('获取跟踪数据统计信息失败: $e');
      return {
        'totalSent': 0,
        'totalOpened': 0,
        'totalClicked': 0,
        'openRate': 0.0,
        'clickRate': 0.0,
      };
    }
  }

  /// 获取默认开始时间（30天前）
  String _getDefaultStartTime() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';
  }

  /// 获取默认结束时间（今天）
  String _getDefaultEndTime() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}