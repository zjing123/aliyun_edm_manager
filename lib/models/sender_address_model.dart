class SenderAddressModel {
  final String mailAddress;
  final String accountName;
  final String sendType;
  final String dailyCount;
  final String monthCount;
  final String status;
  final String createTime;
  final String domainStatus;
  final String mailAddressId;
  final String dailyReqCount;
  final String monthReqCount;

  SenderAddressModel({
    required this.mailAddress,
    required this.accountName,
    required this.sendType,
    required this.dailyCount,
    required this.monthCount,
    required this.status,
    required this.createTime,
    required this.domainStatus,
    required this.mailAddressId,
    required this.dailyReqCount,
    required this.monthReqCount,
  });

  factory SenderAddressModel.fromJson(Map<String, dynamic> json) {
    return SenderAddressModel(
      mailAddress: json['AccountName'] ?? '',
      accountName: json['AccountName'] ?? '',
      sendType: json['Sendtype'] ?? '',
      dailyCount: json['DailyCount']?.toString() ?? '0',
      monthCount: json['MonthCount']?.toString() ?? '0',
      status: json['AccountStatus']?.toString() ?? '0',
      createTime: json['CreateTime'] ?? '',
      domainStatus: json['DomainStatus']?.toString() ?? '0',
      mailAddressId: json['MailAddressId']?.toString() ?? '',
      dailyReqCount: json['DailyReqCount']?.toString() ?? '0',
      monthReqCount: json['MonthReqCount']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AccountName': accountName,
      'Sendtype': sendType,
      'DailyCount': dailyCount,
      'MonthCount': monthCount,
      'AccountStatus': status,
      'CreateTime': createTime,
      'DomainStatus': domainStatus,
      'MailAddressId': mailAddressId,
      'DailyReqCount': dailyReqCount,
      'MonthReqCount': monthReqCount,
    };
  }

  @override
  String toString() {
    return 'SenderAddressModel(mailAddress: $mailAddress, accountName: $accountName, status: $status)';
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