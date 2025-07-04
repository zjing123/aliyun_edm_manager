class ReceiverListModel {
  final String receiverId;
  final String receiversName;
  final String receiversAlias;
  final String? desc;
  final int count;
  final String createTime;

  ReceiverListModel({
    required this.receiverId,
    required this.receiversName,
    required this.receiversAlias,
    this.desc,
    required this.count,
    required this.createTime,
  });

  factory ReceiverListModel.fromMap(Map<String, dynamic> map) {
    return ReceiverListModel(
      receiverId: map['ReceiverId']?.toString() ?? '',
      receiversName: map['ReceiversName']?.toString() ?? '',
      receiversAlias: map['ReceiversAlias']?.toString() ?? '',
      desc: map['Desc']?.toString(),
      count: map['Count'] as int? ?? 0,
      createTime: map['CreateTime']?.toString() ?? '',
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
    };
  }

  @override
  String toString() {
    return 'ReceiverListModel(receiverId: $receiverId, receiversName: $receiversName, receiversAlias: $receiversAlias, desc: $desc, count: $count, createTime: $createTime)';
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
} 