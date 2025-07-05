class SenderAddressModel {
  final String mailAddress;
  final String accountName;
  final String replyToAddress;
  final String sendType;
  final String dailyCount;
  final String monthCount;
  final String status;
  final String createTime;
  final String domainStatus;

  SenderAddressModel({
    required this.mailAddress,
    required this.accountName,
    required this.replyToAddress,
    required this.sendType,
    required this.dailyCount,
    required this.monthCount,
    required this.status,
    required this.createTime,
    required this.domainStatus,
  });

  factory SenderAddressModel.fromJson(Map<String, dynamic> json) {
    return SenderAddressModel(
      mailAddress: json['MailAddress'] ?? '',
      accountName: json['AccountName'] ?? '',
      replyToAddress: json['ReplyToAddress'] ?? '',
      sendType: json['SendType'] ?? '',
      dailyCount: json['DailyCount']?.toString() ?? '0',
      monthCount: json['MonthCount']?.toString() ?? '0',
      status: json['Status']?.toString() ?? '',
      createTime: json['CreateTime'] ?? '',
      domainStatus: json['DomainStatus']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MailAddress': mailAddress,
      'AccountName': accountName,
      'ReplyToAddress': replyToAddress,
      'SendType': sendType,
      'DailyCount': dailyCount,
      'MonthCount': monthCount,
      'Status': status,
      'CreateTime': createTime,
      'DomainStatus': domainStatus,
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
  final int pageNo;
  final int pageSize;

  QuerySenderAddressResponse({
    required this.totalCount,
    required this.addresses,
    required this.pageNo,
    required this.pageSize,
  });

  factory QuerySenderAddressResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final addressList = data['mailAddress'] as List<dynamic>? ?? [];
    
    return QuerySenderAddressResponse(
      totalCount: data['totalCount'] ?? 0,
      pageNo: data['pageNo'] ?? 1,
      pageSize: data['pageSize'] ?? 10,
      addresses: addressList.map((item) => SenderAddressModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // 分页辅助方法
  int get totalPages => (totalCount / pageSize).ceil();
  bool get hasNextPage => pageNo < totalPages;
  bool get hasPreviousPage => pageNo > 1;
  int? get nextPageNo => hasNextPage ? pageNo + 1 : null;
  int? get previousPageNo => hasPreviousPage ? pageNo - 1 : null;
  
  String get paginationSummary => '第 $pageNo 页，共 $totalPages 页，总计 $totalCount 个发信地址';
} 