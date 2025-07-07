import '../constants/template_constants.dart';

class TemplateModel {
  final String templateId;
  final String templateName;
  final String templateNickName;
  final String templateSubject;
  final String templateType;
  final String templateStatus;
  final String createTime;
  final String utcCreateTime;
  final String? remark;

  TemplateModel({
    required this.templateId,
    required this.templateName,
    required this.templateNickName,
    required this.templateSubject,
    required this.templateType,
    required this.templateStatus,
    required this.createTime,
    required this.utcCreateTime,
    this.remark,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      templateId: json['TemplateId']?.toString() ?? '',
      templateName: json['TemplateName']?.toString() ?? '',
      templateNickName: json['TemplateNickName']?.toString() ?? '',
      templateSubject: json['TemplateSubject']?.toString() ?? '',
      templateType: json['TemplateType']?.toString() ?? '',
      templateStatus: json['TemplateStatus']?.toString() ?? '',
      createTime: json['CreateTime']?.toString() ?? '',
      utcCreateTime: json['UtcCreateTime']?.toString() ?? '',
      remark: json['Remark']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TemplateId': templateId,
      'TemplateName': templateName,
      'TemplateNickName': templateNickName,
      'TemplateSubject': templateSubject,
      'TemplateType': templateType,
      'TemplateStatus': templateStatus,
      'CreateTime': createTime,
      'UtcCreateTime': utcCreateTime,
      'Remark': remark,
    };
  }

  // 获取模板状态的中文描述
  String get statusDescription {
    return TemplateConstants.getStatusDescription(templateStatus);
  }

  // 获取模板类型的中文描述
  String get typeDescription {
    return TemplateConstants.getTypeDescription(templateType);
  }

  // 判断模板是否可用
  bool get isAvailable {
    return TemplateConstants.isTemplateAvailable(templateStatus);
  }
}

class QueryTemplateResponse {
  final List<TemplateModel> templates;
  final int totalCount;
  final int pageNo;
  final int pageSize;

  QueryTemplateResponse({
    required this.templates,
    required this.totalCount,
    required this.pageNo,
    required this.pageSize,
  });

  factory QueryTemplateResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final templateList = data['template'] ?? [];
    
    List<TemplateModel> templates = [];
    if (templateList is List) {
      templates = templateList
          .map((item) => TemplateModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return QueryTemplateResponse(
      templates: templates,
      totalCount: data['totalCount'] ?? 0,
      pageNo: data['pageNo'] ?? 1,
      pageSize: data['pageSize'] ?? 10,
    );
  }

  // 获取总页数
  int get totalPages {
    if (pageSize <= 0) return 0;
    return (totalCount + pageSize - 1) ~/ pageSize; // 向上取整
  }

  // 判断是否有下一页
  bool get hasNextPage {
    return pageNo < totalPages;
  }

  // 判断是否有上一页
  bool get hasPreviousPage {
    return pageNo > 1;
  }

  // 获取下一页页码
  int? get nextPageNo {
    return hasNextPage ? pageNo + 1 : null;
  }

  // 获取上一页页码
  int? get previousPageNo {
    return hasPreviousPage ? pageNo - 1 : null;
  }

  // 获取分页信息摘要
  String get paginationSummary {
    final start = (pageNo - 1) * pageSize + 1;
    final end = (pageNo * pageSize < totalCount) ? pageNo * pageSize : totalCount;
    return '第 $start-$end 条，共 $totalCount 条，第 $pageNo/$totalPages 页';
  }
} 