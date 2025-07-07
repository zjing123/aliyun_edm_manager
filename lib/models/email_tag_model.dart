class EmailTagModel {
  final String tagId;
  final String tagName;
  final String? description;
  final String createTime;
  final int? templateCount;

  EmailTagModel({
    required this.tagId,
    required this.tagName,
    this.description,
    required this.createTime,
    this.templateCount,
  });

  factory EmailTagModel.fromJson(Map<String, dynamic> json) {
    return EmailTagModel(
      tagId: json['TagId']?.toString() ?? '',
      tagName: json['TagName']?.toString() ?? '',
      description: json['Description']?.toString(),
      createTime: json['CreateTime']?.toString() ?? '',
      templateCount: json['TemplateCount'] != null 
          ? int.tryParse(json['TemplateCount'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TagId': tagId,
      'TagName': tagName,
      'Description': description,
      'CreateTime': createTime,
      'TemplateCount': templateCount,
    };
  }

  @override
  String toString() {
    return 'EmailTagModel(tagId: $tagId, tagName: $tagName, description: $description, createTime: $createTime, templateCount: $templateCount)';
  }
}

class QueryTagByParamResponse {
  final String requestId;
  final int totalCount;
  final int pageNo;
  final int pageSize;
  final List<EmailTagModel> tags;

  QueryTagByParamResponse({
    required this.requestId,
    required this.totalCount,
    required this.pageNo,
    required this.pageSize,
    required this.tags,
  });

  factory QueryTagByParamResponse.fromJson(Map<String, dynamic> json) {
    final data = json['Data'] as Map<String, dynamic>? ?? {};
    final tagList = data['tag'] as List<dynamic>? ?? [];
    
    return QueryTagByParamResponse(
      requestId: json['RequestId']?.toString() ?? '',
      totalCount: int.tryParse(data['TotalCount']?.toString() ?? '0') ?? 0,
      pageNo: int.tryParse(data['PageNo']?.toString() ?? '1') ?? 1,
      pageSize: int.tryParse(data['PageSize']?.toString() ?? '10') ?? 10,
      tags: tagList.map((tag) => EmailTagModel.fromJson(tag as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RequestId': requestId,
      'Data': {
        'TotalCount': totalCount,
        'PageNo': pageNo,
        'PageSize': pageSize,
        'tag': tags.map((tag) => tag.toJson()).toList(),
      },
    };
  }

  @override
  String toString() {
    return 'QueryTagByParamResponse(requestId: $requestId, totalCount: $totalCount, pageNo: $pageNo, pageSize: $pageSize, tags: $tags)';
  }
} 