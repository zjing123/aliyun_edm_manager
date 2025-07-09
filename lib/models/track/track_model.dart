/// 跟踪数据记录模型
class TrackRecord {
  final String createTime;
  final String rcptClickCount;
  final String rcptClickRate;
  final String rcptUniqueOpenCount;
  final String rcptUniqueOpenRate;
  final String rcptUniqueClickCount;
  final String rcptUniqueClickRate;
  final String rcptOpenCount;
  final String rcptOpenRate;
  final String totalNumber;

  TrackRecord({
    required this.createTime,
    required this.rcptClickCount,
    required this.rcptClickRate,
    required this.rcptUniqueOpenCount,
    required this.rcptUniqueOpenRate,
    required this.rcptUniqueClickCount,
    required this.rcptUniqueClickRate,
    required this.rcptOpenCount,
    required this.rcptOpenRate,
    required this.totalNumber,
  });

  factory TrackRecord.fromJson(Map<String, dynamic> json) {
    return TrackRecord(
      createTime: _parseString(json['CreateTime']) ?? '',
      rcptClickCount: _parseString(json['RcptClickCount']) ?? '0',
      rcptClickRate: _parseString(json['RcptClickRate']) ?? '0',
      rcptUniqueOpenCount: _parseString(json['RcptUniqueOpenCount']) ?? '0',
      rcptUniqueOpenRate: _parseString(json['RcptUniqueOpenRate']) ?? '0',
      rcptUniqueClickCount: _parseString(json['RcptUniqueClickCount']) ?? '0',
      rcptUniqueClickRate: _parseString(json['RcptUniqueClickRate']) ?? '0',
      rcptOpenCount: _parseString(json['RcptOpenCount']) ?? '0',
      rcptOpenRate: _parseString(json['RcptOpenRate']) ?? '0',
      totalNumber: _parseString(json['TotalNumber']) ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CreateTime': createTime,
      'RcptClickCount': rcptClickCount,
      'RcptClickRate': rcptClickRate,
      'RcptUniqueOpenCount': rcptUniqueOpenCount,
      'RcptUniqueOpenRate': rcptUniqueOpenRate,
      'RcptUniqueClickCount': rcptUniqueClickCount,
      'RcptUniqueClickRate': rcptUniqueClickRate,
      'RcptOpenCount': rcptOpenCount,
      'RcptOpenRate': rcptOpenRate,
      'TotalNumber': totalNumber,
    };
  }

  // 便利方法
  int get rcptClickCountInt => int.tryParse(rcptClickCount) ?? 0;
  int get rcptUniqueOpenCountInt => int.tryParse(rcptUniqueOpenCount) ?? 0;
  int get rcptUniqueClickCountInt => int.tryParse(rcptUniqueClickCount) ?? 0;
  int get rcptOpenCountInt => int.tryParse(rcptOpenCount) ?? 0;
  int get totalNumberInt => int.tryParse(totalNumber) ?? 0;
  
  double get rcptClickRateDouble => double.tryParse(rcptClickRate) ?? 0.0;
  double get rcptUniqueOpenRateDouble => double.tryParse(rcptUniqueOpenRate) ?? 0.0;
  double get rcptUniqueClickRateDouble => double.tryParse(rcptUniqueClickRate) ?? 0.0;
  double get rcptOpenRateDouble => double.tryParse(rcptOpenRate) ?? 0.0;

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  @override
  String toString() {
    return 'TrackRecord(createTime: $createTime, rcptClickCount: $rcptClickCount, rcptClickRate: $rcptClickRate, rcptUniqueOpenCount: $rcptUniqueOpenCount, rcptUniqueOpenRate: $rcptUniqueOpenRate, rcptUniqueClickCount: $rcptUniqueClickCount, rcptUniqueClickRate: $rcptUniqueClickRate, rcptOpenCount: $rcptOpenCount, rcptOpenRate: $rcptOpenRate, totalNumber: $totalNumber)';
  }
}

/// 跟踪数据响应模型
class GetTrackListResponse {
  final String requestId;
  final int pageNo;
  final int pageSize;
  final int total;
  final List<TrackRecord> trackList;

  GetTrackListResponse({
    required this.requestId,
    required this.pageNo,
    required this.pageSize,
    required this.total,
    required this.trackList,
  });

  factory GetTrackListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final stat = data?['stat'] as List<dynamic>? ?? [];
    
    return GetTrackListResponse(
      requestId: _parseString(json['RequestId']) ?? '',
      pageNo: _parseInt(json['PageNo']) ?? 1,
      pageSize: _parseInt(json['PageSize']) ?? 10,
      total: _parseInt(json['Total']) ?? 0,
      trackList: stat.map((item) => TrackRecord.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  @override
  String toString() {
    return 'GetTrackListResponse(requestId: $requestId, pageNo: $pageNo, pageSize: $pageSize, total: $total, trackList: $trackList)';
  }
}

/// 根据发信地址和标签获取跟踪数据响应模型
class GetTrackListByMailFromAndTagNameResponse {
  final String requestId;
  final int pageNo;
  final int pageSize;
  final int total;
  final List<TrackRecord> trackList;

  GetTrackListByMailFromAndTagNameResponse({
    required this.requestId,
    required this.pageNo,
    required this.pageSize,
    required this.total,
    required this.trackList,
  });

  factory GetTrackListByMailFromAndTagNameResponse.fromJson(Map<String, dynamic> json) {
    final trackListData = json['TrackList'] as Map<String, dynamic>?;
    final stat = trackListData?['Stat'] as List<dynamic>? ?? [];
    
    return GetTrackListByMailFromAndTagNameResponse(
      requestId: _parseString(json['RequestId']) ?? '',
      pageNo: _parseInt(json['PageNo']) ?? 1,
      pageSize: _parseInt(json['PageSize']) ?? 10,
      total: _parseInt(json['Total']) ?? 0,
      trackList: stat.map((item) => TrackRecord.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  @override
  String toString() {
    return 'GetTrackListByMailFromAndTagNameResponse(requestId: $requestId, pageNo: $pageNo, pageSize: $pageSize, total: $total, trackList: $trackList)';
  }
}