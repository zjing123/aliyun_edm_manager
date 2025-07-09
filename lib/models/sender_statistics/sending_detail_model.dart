enum SendingStatus {
  sent,
  opened,
  failed,
}

class SendingDetailModel {
  final String recipient;
  final String subject;
  final SendingStatus status;
  final DateTime sendTime;
  final DateTime? openTime;

  SendingDetailModel({
    required this.recipient,
    required this.subject,
    required this.status,
    required this.sendTime,
    this.openTime,
  });

  factory SendingDetailModel.fromJson(Map<String, dynamic> json) {
    return SendingDetailModel(
      recipient: json['recipient'] ?? '',
      subject: json['subject'] ?? '',
      status: _parseStatus(json['status'] ?? 'sent'),
      sendTime: DateTime.parse(json['sendTime'] ?? DateTime.now().toIso8601String()),
      openTime: json['openTime'] != null 
          ? DateTime.parse(json['openTime']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient': recipient,
      'subject': subject,
      'status': _statusToString(status),
      'sendTime': sendTime.toIso8601String(),
      'openTime': openTime?.toIso8601String(),
    };
  }

  static SendingStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'opened':
        return SendingStatus.opened;
      case 'failed':
        return SendingStatus.failed;
      default:
        return SendingStatus.sent;
    }
  }

  static String _statusToString(SendingStatus status) {
    switch (status) {
      case SendingStatus.opened:
        return 'opened';
      case SendingStatus.failed:
        return 'failed';
      default:
        return 'sent';
    }
  }

  String get statusText {
    switch (status) {
      case SendingStatus.sent:
        return '已发送';
      case SendingStatus.opened:
        return '已打开';
      case SendingStatus.failed:
        return '发送失败';
    }
  }
} 