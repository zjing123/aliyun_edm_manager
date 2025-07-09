class SendingStatisticsModel {
  final int totalCount;
  final String requestId;
  final List<StatisticsRecord> records;

  SendingStatisticsModel({
    required this.totalCount,
    required this.requestId,
    required this.records,
  });

  factory SendingStatisticsModel.fromJson(Map<String, dynamic> json) {
    return SendingStatisticsModel(
      totalCount: _parseInt(json['TotalCount']) ?? 0,
      requestId: json['RequestId']?.toString() ?? '',
      records: (json['data']?['stat'] as List<dynamic>?)
          ?.map((record) => StatisticsRecord.fromJson(record))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TotalCount': totalCount,
      'RequestId': requestId,
      'data': {
        'stat': records.map((record) => record.toJson()).toList(),
      },
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class StatisticsRecord {
  final String unavailablePercent;
  final String createTime;
  final String succeededPercent;
  final String faildCount;
  final String unavailableCount;
  final String successCount;
  final String requestCount;

  StatisticsRecord({
    required this.unavailablePercent,
    required this.createTime,
    required this.succeededPercent,
    required this.faildCount,
    required this.unavailableCount,
    required this.successCount,
    required this.requestCount,
  });

  factory StatisticsRecord.fromJson(Map<String, dynamic> json) {
    return StatisticsRecord(
      unavailablePercent: _parseString(json['unavailablePercent']) ?? '0%',
      createTime: _parseString(json['CreateTime']) ?? '',
      succeededPercent: _parseString(json['succeededPercent']) ?? '0%',
      faildCount: _parseString(json['faildCount']) ?? '0',
      unavailableCount: _parseString(json['unavailableCount']) ?? '0',
      successCount: _parseString(json['successCount']) ?? '0',
      requestCount: _parseString(json['requestCount']) ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unavailablePercent': unavailablePercent,
      'CreateTime': createTime,
      'succeededPercent': succeededPercent,
      'faildCount': faildCount,
      'unavailableCount': unavailableCount,
      'successCount': successCount,
      'requestCount': requestCount,
    };
  }

  // 便利方法
  int get successCountInt => int.tryParse(successCount) ?? 0;
  int get faildCountInt => int.tryParse(faildCount) ?? 0;
  int get unavailableCountInt => int.tryParse(unavailableCount) ?? 0;
  int get requestCountInt => int.tryParse(requestCount) ?? 0;
  
  double get successRate {
    final success = successCountInt;
    final total = requestCountInt;
    return total > 0 ? (success / total) * 100 : 0.0;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }
} 