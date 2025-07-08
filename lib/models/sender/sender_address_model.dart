import 'package:aliyun_edm_manager/utils/time_formatter.dart';

class SenderAddressModel {
  final String mailAddressId;
  final String accountName;
  final String replyAddress;
  final String sendType;
  final String accountStatus;
  final String replyStatus;
  final String domainStatus;
  final String createTime;
  final String dailyCount;
  final String monthCount;
  final String dailyReqCount;
  final String monthReqCount;

  SenderAddressModel({
    required this.mailAddressId,
    required this.accountName,
    required this.replyAddress,
    required this.sendType,
    required this.accountStatus,
    required this.replyStatus,
    required this.domainStatus,
    required this.createTime,
    required this.dailyCount,
    required this.monthCount,
    required this.dailyReqCount,
    required this.monthReqCount,
  });

  /// 获取格式化后的创建时间
  String formattedCreateTime({String timeZone = TimeFormatter.defaultTimeZone}) {
    return TimeFormatter.formatDateTime(
      timeString: createTime,
      timeZone: timeZone,
    );
  }

  /// 获取格式化后的创建日期（仅日期部分）
  String formattedCreateDate({String timeZone = TimeFormatter.defaultTimeZone}) {
    return TimeFormatter.formatDate(
      timeString: createTime,
      timeZone: timeZone,
    );
  }

  /// 获取相对时间（如：刚刚、5分钟前等）
  String relativeCreateTime({String timeZone = TimeFormatter.defaultTimeZone}) {
    return TimeFormatter.formatRelativeTime(
      timeString: createTime,
      timeZone: timeZone,
    );
  }

  /// 获取发信类型描述
  String get sendTypeDescription {
    switch (sendType) {
      case 'batch':
        return '批量';
      case 'trigger':
        return '触发';
      default:
        return '未知';
    }
  }

  /// 获取账号状态描述
  String get accountStatusDescription {
    switch (accountStatus) {
      case '0':
        return '正常';
      case '1':
        return '冻结';
      default:
        return '未知';
    }
  }

  /// 获取额度限制描述
  String get quotaDescription {
    final daily = dailyCount == '-1' ? '无限制' : dailyCount;
    final monthly = monthCount == '-1' ? '无限制' : monthCount;
    return '日: $daily, 月: $monthly';
  }

  /// 检查账号是否正常
  bool get isAccountNormal => accountStatus == '0';

  /// 检查域名是否正常
  bool get isDomainNormal => domainStatus == '0';

  factory SenderAddressModel.fromJson(Map<String, dynamic> json) {
    return SenderAddressModel(
      mailAddressId: json['MailAddressId']?.toString() ?? '',
      accountName: json['AccountName'] ?? '',
      replyAddress: json['ReplyAddress'] ?? '',
      sendType: json['Sendtype'] ?? '',
      accountStatus: json['AccountStatus']?.toString() ?? '0',
      replyStatus: json['ReplyStatus']?.toString() ?? '0',
      domainStatus: json['DomainStatus']?.toString() ?? '0',
      createTime: json['CreateTime'] ?? '',
      dailyCount: json['DailyCount']?.toString() ?? '0',
      monthCount: json['MonthCount']?.toString() ?? '0',
      dailyReqCount: json['DailyReqCount']?.toString() ?? '0',
      monthReqCount: json['MonthReqCount']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MailAddressId': mailAddressId,
      'AccountName': accountName,
      'ReplyAddress': replyAddress,
      'Sendtype': sendType,
      'AccountStatus': accountStatus,
      'ReplyStatus': replyStatus,
      'DomainStatus': domainStatus,
      'CreateTime': createTime,
      'DailyCount': dailyCount,
      'MonthCount': monthCount,
      'DailyReqCount': dailyReqCount,
      'MonthReqCount': monthReqCount,
    };
  }

  @override
  String toString() {
    return 'SenderAddressModel(mailAddressId: $mailAddressId, accountName: $accountName, status: $accountStatus)';
  }
}

class QuerySenderAddressResponse {
  final int totalCount;
  final List<SenderAddressModel> addresses;
  final int pageNumber;
  final int pageSize;
  final String requestId;

  QuerySenderAddressResponse({
    required this.totalCount,
    required this.addresses,
    required this.pageNumber,
    required this.pageSize,
    required this.requestId,
  });

  factory QuerySenderAddressResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final addressList = data['mailAddress'] as List<dynamic>? ?? [];
    
    return QuerySenderAddressResponse(
      totalCount: json['TotalCount'] ?? 0,
      pageNumber: json['PageNumber'] ?? 1,
      pageSize: json['PageSize'] ?? 10,
      requestId: json['RequestId'] ?? '',
      addresses: addressList.map((item) => SenderAddressModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // 分页辅助方法
  int get totalPages => (totalCount / pageSize).ceil();
  bool get hasNextPage => pageNumber < totalPages;
  bool get hasPreviousPage => pageNumber > 1;
  int? get nextPageNo => hasNextPage ? pageNumber + 1 : null;
  int? get previousPageNo => hasPreviousPage ? pageNumber - 1 : null;
  
  String get paginationSummary => '第 $pageNumber 页，共 $totalPages 页，总计 $totalCount 个发信地址';
} 