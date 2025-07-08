// 模板管理相关的Request和Response类
import 'package:aliyun_edm_manager/models/template/template_model.dart';

// QueryTemplateByParam API
class QueryTemplateByParamRequest {
  final int pageNo;
  final int pageSize;
  final String? keyWord;
  final int? status;
  final int? fromType;

  QueryTemplateByParamRequest({
    required this.pageNo,
    required this.pageSize,
    this.keyWord,
    this.status,
    this.fromType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> params = {
      'PageNo': pageNo,
      'PageSize': pageSize,
    };
    
    if (keyWord != null && keyWord!.isNotEmpty) {
      params['KeyWord'] = keyWord;
    }
    if (status != null) {
      params['Status'] = status;
    }
    if (fromType != null) {
      params['FromType'] = fromType;
    }
    
    return params;
  }
}

class QueryTemplateByParamResponse {
  final List<TemplateModel> templates;
  final int totalCount;
  final int pageNo;
  final int pageSize;
  final String requestId;

  QueryTemplateByParamResponse({
    required this.templates,
    required this.totalCount,
    required this.pageNo,
    required this.pageSize,
    required this.requestId,
  });

  // 获取总页数
  int get totalPages {
    if (pageSize <= 0) return 0;
    return (totalCount + pageSize - 1) ~/ pageSize; // 向上取整
  }

  factory QueryTemplateByParamResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final templateList = data['template'] ?? [];
    
    List<TemplateModel> templates = [];
    if (templateList is List) {
      templates = templateList
          .map((item) => TemplateModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return QueryTemplateByParamResponse(
      templates: templates,
      totalCount: json['TotalCount'] ?? 0,
      pageNo: json['PageNumber'] ?? 1,
      pageSize: json['PageSize'] ?? 10,
      requestId: json['RequestId'] ?? '',
    );
  }
}

// CreateTemplate API
class CreateTemplateRequest {
  final int templateType;
  final String templateName;
  final String? templateSubject;
  final String? templateNickName;
  final String? templateText;
  final int? fromType;

  CreateTemplateRequest({
    required this.templateType,
    required this.templateName,
    this.templateSubject,
    this.templateNickName,
    this.templateText,
    this.fromType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> params = {
      'TemplateType': templateType,
      'TemplateName': templateName,
    };
    
    if (templateSubject != null && templateSubject!.isNotEmpty) {
      params['TemplateSubject'] = templateSubject;
    }
    if (templateNickName != null && templateNickName!.isNotEmpty) {
      params['TemplateNickName'] = templateNickName;
    }
    if (templateText != null && templateText!.isNotEmpty) {
      params['TemplateText'] = templateText;
    }
    if (fromType != null) {
      params['FromType'] = fromType;
    }
    
    return params;
  }
}

class CreateTemplateResponse {
  final int templateId;
  final String requestId;

  CreateTemplateResponse({
    required this.templateId,
    required this.requestId,
  });

  factory CreateTemplateResponse.fromJson(Map<String, dynamic> json) {
    return CreateTemplateResponse(
      templateId: json['TemplateId'] ?? 0,
      requestId: json['RequestId'] ?? '',
    );
  }
}

// ModifyTemplate API
class ModifyTemplateRequest {
  final int templateId;
  final String templateName;
  final String? templateSubject;
  final String? templateNickName;
  final String? templateText;
  final int? fromType;

  ModifyTemplateRequest({
    required this.templateId,
    required this.templateName,
    this.templateSubject,
    this.templateNickName,
    this.templateText,
    this.fromType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> params = {
      'TemplateId': templateId,
      'TemplateName': templateName,
    };
    
    if (templateSubject != null && templateSubject!.isNotEmpty) {
      params['TemplateSubject'] = templateSubject;
    }
    if (templateNickName != null && templateNickName!.isNotEmpty) {
      params['TemplateNickName'] = templateNickName;
    }
    if (templateText != null && templateText!.isNotEmpty) {
      params['TemplateText'] = templateText;
    }
    if (fromType != null) {
      params['FromType'] = fromType;
    }
    
    return params;
  }
}

class ModifyTemplateResponse {
  final String requestId;

  ModifyTemplateResponse({
    required this.requestId,
  });

  factory ModifyTemplateResponse.fromJson(Map<String, dynamic> json) {
    return ModifyTemplateResponse(
      requestId: json['RequestId'] ?? '',
    );
  }
}

// DeleteTemplate API
class DeleteTemplateRequest {
  final int templateId;
  final int? fromType;

  DeleteTemplateRequest({
    required this.templateId,
    this.fromType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> params = {
      'TemplateId': templateId,
    };
    
    if (fromType != null) {
      params['FromType'] = fromType;
    }
    
    return params;
  }
}

class DeleteTemplateResponse {
  final String requestId;

  DeleteTemplateResponse({
    required this.requestId,
  });

  factory DeleteTemplateResponse.fromJson(Map<String, dynamic> json) {
    return DeleteTemplateResponse(
      requestId: json['RequestId'] ?? '',
    );
  }
}

// DescTemplate API
class DescTemplateRequest {
  final int templateId;
  final int? fromType;

  DescTemplateRequest({
    required this.templateId,
    this.fromType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> params = {
      'TemplateId': templateId,
    };
    
    if (fromType != null) {
      params['FromType'] = fromType;
    }
    
    return params;
  }
}

class DescTemplateResponse {
  final String requestId;
  final String createTime;
  final String templateSubject;
  final String templateStatus;
  final String templateNickName;
  final String templateType;
  final String templateName;
  final String templateText;

  DescTemplateResponse({
    required this.requestId,
    required this.createTime,
    required this.templateSubject,
    required this.templateStatus,
    required this.templateNickName,
    required this.templateType,
    required this.templateName,
    required this.templateText,
  });

  factory DescTemplateResponse.fromJson(Map<String, dynamic> json) {
    return DescTemplateResponse(
      requestId: json['RequestId'] ?? '',
      createTime: json['CreateTime'] ?? '',
      templateSubject: json['TemplateSubject'] ?? '',
      templateStatus: json['TemplateStatus'] ?? '',
      templateNickName: json['TemplateNickName'] ?? '',
      templateType: json['TemplateType'] ?? '',
      templateName: json['TemplateName'] ?? '',
      templateText: json['TemplateText'] ?? '',
    );
  }
} 