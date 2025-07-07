import 'dart:convert';

// 字段定义类
class ReceiverField {
  final String field;
  final String label;
  final String apiKey;

  const ReceiverField({
    required this.field,
    required this.label,
    required this.apiKey,
  });
}

class ReceiverDetailParams {
  // 固定的收件人数据字段
  static const List<ReceiverField> fields = [
    ReceiverField(field: 'UserName', label: '姓名', apiKey: 'u'),
    ReceiverField(field: 'NickName', label: '昵称', apiKey: 'n'),
    ReceiverField(field: 'Gender', label: '性别', apiKey: 'g'),
    ReceiverField(field: 'Birthday', label: '生日', apiKey: 'b'),
    ReceiverField(field: 'Mobile', label: '手机号', apiKey: 'm'),
  ];

  /// 获取字段的显示名称
  static String getDisplayName(String fieldName) {
    final field = getField(fieldName);
    return field?.label ?? fieldName;
  }

  /// 根据字段名获取字段对象
  static ReceiverField? getField(String fieldName) {
    try {
      return fields.firstWhere((f) => f.field == fieldName);
    } catch (e) {
      return null;
    }
  }

  final String email;
  final Map<String, String> fieldValues;

  ReceiverDetailParams({
    required this.email,
    Map<String, String>? fieldValues,
  }) : fieldValues = fieldValues ?? {};

  /// 便捷构造函数，使用命名参数
  ReceiverDetailParams.withFields({
    required this.email,
    String? userName,
    String? nickName,
    String? gender,
    String? birthday,
    String? mobile,
    Map<String, String>? customFields,
  }) : fieldValues = {
    if (userName?.isNotEmpty == true) 'UserName': userName!,
    if (nickName?.isNotEmpty == true) 'NickName': nickName!,
    if (gender?.isNotEmpty == true) 'Gender': gender!,
    if (birthday?.isNotEmpty == true) 'Birthday': birthday!,
    if (mobile?.isNotEmpty == true) 'Mobile': mobile!,
    ...?customFields,
  };

  /// 获取字段值
  String? getValue(String fieldName) => fieldValues[fieldName];

  /// 设置字段值
  void setValue(String fieldName, String value) {
    if (value.isNotEmpty) {
      fieldValues[fieldName] = value;
    } else {
      fieldValues.remove(fieldName);
    }
  }

  /// 转换为API需要的Detail JSON格式
  String toDetailJson() {
    final detailMap = <String, String>{'e': email};
    
    // 处理所有字段值
    fieldValues.forEach((fieldName, value) {
      if (value.isNotEmpty) {
        final field = getField(fieldName);
        if (field != null) {
          // 标准字段使用API映射
          detailMap[field.apiKey] = value;
        } else {
          // 自定义字段直接使用字段名
          detailMap[fieldName] = value;
        }
      }
    });
    
    return '[{${detailMap.entries.map((e) => '"${e.key}":"${e.value}"').join(',')}}]';
  }

  /// 批量转换为API需要的Detail JSON格式
  static String toBatchDetailJson(List<ReceiverDetailParams> paramsList) {
    final details = paramsList.map((params) {
      final detailMap = <String, String>{'e': params.email};
      
      // 处理所有字段值
      params.fieldValues.forEach((fieldName, value) {
        if (value.isNotEmpty) {
          final field = getField(fieldName);
          if (field != null) {
            // 标准字段使用API映射
            detailMap[field.apiKey] = value;
          } else {
            // 自定义字段直接使用字段名
            detailMap[fieldName] = value;
          }
        }
      });
      
      return '{${detailMap.entries.map((e) => '"${e.key}":"${e.value}"').join(',')}}';
    }).toList();
    
    return '[${details.join(',')}]';
  }

  /// 从Map创建
  factory ReceiverDetailParams.fromMap(String email, Map<String, String> data) {
    return ReceiverDetailParams(
      email: email,
      fieldValues: Map.from(data),
    );
  }

  @override
  String toString() {
    return 'ReceiverDetailParams(email: $email, fieldValues: $fieldValues)';
  }
}

class ReceiverDetail {
  final String receiverId;
  final List<MemberDetail> members;
  final List<String> dataSchema;
  String? nextStart;

  ReceiverDetail({
    required this.receiverId,
    required this.members,
    required this.dataSchema,
    this.nextStart,
  });

  void setNextStart(String? nextStart) {
    this.nextStart = nextStart;
  }

  factory ReceiverDetail.fromJson(Map<String, dynamic> json) {
    final receiverId = json['ReceiverId'] as String? ?? '';
    final schemaStr = json['DataSchema'] as String? ?? '';
    final schema = schemaStr.split(',').map((e) => e.trim()).toList();

    final data = json['data'] ?? {};
    final details = data['detail'] as List? ?? [];
    final members = details.map((e) => MemberDetail.fromJson(e)).toList();
    final nextStart = details.isEmpty ? null : json['NextStart'] as String?;

    return ReceiverDetail(
      receiverId: receiverId,
      members: members,
      dataSchema: schema,
      nextStart: nextStart,
    );
  }
}

class MemberDetail {
  final String? email;
  final String? createTime;
  final String? utcCreateTime;
  final String? data; // 逗号分隔的自定义字段

  MemberDetail({
    this.email,
    this.createTime,
    this.utcCreateTime,
    this.data,
  });

  factory MemberDetail.fromJson(Map<String, dynamic> json) {
    return MemberDetail(
      email: json['Email'] as String?,
      createTime: json['CreateTime'] as String?,
      utcCreateTime: json['UtcCreateTime']?.toString(),
      data: json['Data'] as String?,
    );
  }
}

/// SaveReceiverDetail API 响应模型
class SaveReceiverDetailResponse {
  final String requestId;
  final int successCount;
  final int errorCount;
  final List<String>? successList;
  final List<String>? existList;
  final List<String>? failList;

  SaveReceiverDetailResponse({
    required this.requestId,
    required this.successCount,
    required this.errorCount,
    this.successList,
    this.existList,
    this.failList,
  });

  factory SaveReceiverDetailResponse.fromJson(Map<String, dynamic> json) {
    return SaveReceiverDetailResponse(
      requestId: json['RequestId'] as String? ?? '',
      successCount: json['SuccessCount'] as int? ?? 0,
      errorCount: json['ErrorCount'] as int? ?? 0,
      successList: json['SuccessList'] != null 
          ? List<String>.from(json['SuccessList'] as List)
          : null,
      existList: json['ExistList'] != null
          ? List<String>.from(json['ExistList'] as List)
          : null,
      failList: json['FailList'] != null
          ? List<String>.from(json['FailList'] as List)
          : null,
    );
  }

  /// 是否完全成功
  bool get isSuccess => errorCount == 0;

  /// 是否有失败
  bool get hasFailed => errorCount > 0;

  /// 是否有已存在的记录
  bool get hasExisted => existList?.isNotEmpty ?? false;

  /// 获取状态描述
  String getStatusMessage() {
    if (isSuccess) {
      return '成功添加 $successCount 个收件人';
    } else if (hasFailed && hasExisted) {
      return '成功 $successCount 个，失败 $errorCount 个，已存在 ${existList?.length ?? 0} 个';
    } else if (hasFailed) {
      return '成功 $successCount 个，失败 $errorCount 个';
    } else if (hasExisted) {
      return '成功 $successCount 个，已存在 ${existList?.length ?? 0} 个';
    } else {
      return '添加完成';
    }
  }

  @override
  String toString() {
    return 'SaveReceiverDetailResponse(requestId: $requestId, success: $successCount, error: $errorCount)';
  }
}

/// CreateReceiver API 响应模型
class CreateReceiverResponse {
  final String requestId;
  final String receiverId;

  CreateReceiverResponse({
    required this.requestId,
    required this.receiverId,
  });

  factory CreateReceiverResponse.fromJson(Map<String, dynamic> json) {
    return CreateReceiverResponse(
      requestId: json['RequestId'] as String? ?? '',
      receiverId: json['ReceiverId'] as String? ?? '',
    );
  }
}