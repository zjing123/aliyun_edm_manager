import 'package:aliyun_edm_manager/utils/time_formatter.dart';

class SenderNameModel {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int isDefault;

  SenderNameModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = 0,
  });

  /// 获取格式化后的创建时间
  String formattedCreateTime({String timeZone = TimeFormatter.defaultTimeZone}) {
    return TimeFormatter.formatDateTime(
      timeString: createdAt,
      timeZone: timeZone,
    );
  }

  /// 获取格式化后的创建日期（仅日期部分）
  String formattedCreateDate({String timeZone = TimeFormatter.defaultTimeZone}) {
    return TimeFormatter.formatDate(
      timeString: createdAt,
      timeZone: timeZone,
    );
  }

  /// 获取相对时间（如：刚刚、5分钟前等）
  String relativeCreateTime({String timeZone = TimeFormatter.defaultTimeZone}) {
    return TimeFormatter.formatRelativeTime(
      timeString: createdAt,
      timeZone: timeZone,
    );
  }

  factory SenderNameModel.fromJson(Map<String, dynamic> json) {
    return SenderNameModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isDefault: (json['is_default'] is int)
        ? json['is_default'] as int
        : int.tryParse(json['is_default']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_default': isDefault,
    };
  }

  @override
  String toString() {
    return 'SenderNameModel(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SenderNameModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  SenderNameModel copyWith({
    String? id,
    String? name,
    String? createdAt,
    String? updatedAt,
    int? isDefault,
  }) {
    return SenderNameModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
} 