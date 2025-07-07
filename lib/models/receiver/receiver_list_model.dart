class ReceiverListModel {
  final String receiverId;
  final String receiversName;
  final String receiversAlias;
  final String? desc;
  final int count;
  final String createTime;
  final bool isDeletable;

  ReceiverListModel({
    required this.receiverId,
    required this.receiversName,
    required this.receiversAlias,
    this.desc,
    required this.count,
    required this.createTime,
    this.isDeletable = true,
  });

  factory ReceiverListModel.fromMap(Map<String, dynamic> map) {
    return ReceiverListModel(
      receiverId: map['ReceiverId']?.toString() ?? '',
      receiversName: map['ReceiversName']?.toString() ?? '',
      receiversAlias: map['ReceiversAlias']?.toString() ?? '',
      desc: map['Desc']?.toString(),
      count: map['Count'] as int? ?? 0,
      createTime: map['CreateTime']?.toString() ?? '',
      isDeletable: map['IsDeletable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ReceiverId': receiverId,
      'ReceiversName': receiversName,
      'ReceiversAlias': receiversAlias,
      'Desc': desc,
      'Count': count,
      'CreateTime': createTime,
      'IsDeletable': isDeletable,
    };
  }

  @override
  String toString() {
    return 'ReceiverListModel(receiverId: $receiverId, receiversName: $receiversName, receiversAlias: $receiversAlias, desc: $desc, count: $count, createTime: $createTime, isDeletable: $isDeletable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiverListModel &&
        other.receiverId == receiverId &&
        other.receiversName == receiversName;
  }

  @override
  int get hashCode {
    return receiverId.hashCode ^ receiversName.hashCode;
  }
  
  // 添加copyWith方法
  ReceiverListModel copyWith({
    String? receiverId,
    String? receiversName,
    String? receiversAlias,
    String? desc,
    int? count,
    String? createTime,
    bool? isDeletable,
  }) {
    return ReceiverListModel(
      receiverId: receiverId ?? this.receiverId,
      receiversName: receiversName ?? this.receiversName,
      receiversAlias: receiversAlias ?? this.receiversAlias,
      desc: desc ?? this.desc,
      count: count ?? this.count,
      createTime: createTime ?? this.createTime,
      isDeletable: isDeletable ?? this.isDeletable,
    );
  }
} 