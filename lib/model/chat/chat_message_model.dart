enum ChatMessageType { text, image, file }

class ChatMessageModel {
  final String name;
  final String chatGroup;
  final String sender;
  final String senderName;
  final String? message;
  final ChatMessageType messageType;
  final String? attachment;
  final DateTime? sentAt;
  final bool isDeleted;
  final bool isMine;

  const ChatMessageModel({
    required this.name,
    required this.chatGroup,
    required this.sender,
    required this.senderName,
    this.message,
    required this.messageType,
    this.attachment,
    this.sentAt,
    required this.isDeleted,
    required this.isMine,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        name: _string(json['name']),
        chatGroup: _string(json['chat_group']),
        sender: _string(json['sender']),
        senderName: _string(json['sender_name'], fallback: _string(json['sender'])),
        message: _optional(json['message']),
        messageType: _type(json['message_type']),
        attachment: _optional(json['attachment']),
        sentAt: _date(json['sent_at']),
        isDeleted: _bool(json['is_deleted']),
        isMine: _bool(json['is_mine']),
      );

  String get messageTypeValue => switch (messageType) {
        ChatMessageType.text => 'Text',
        ChatMessageType.image => 'Image',
        ChatMessageType.file => 'File',
      };

  ChatMessageModel copyWith({bool? isDeleted}) => ChatMessageModel(
        name: name,
        chatGroup: chatGroup,
        sender: sender,
        senderName: senderName,
        message: isDeleted == true ? null : message,
        messageType: messageType,
        attachment: isDeleted == true ? null : attachment,
        sentAt: sentAt,
        isDeleted: isDeleted ?? this.isDeleted,
        isMine: isMine,
      );
}

class ChatMessagePageModel {
  final List<ChatMessageModel> messages;
  final bool hasMore;
  final String? nextBefore;

  const ChatMessagePageModel({
    required this.messages,
    required this.hasMore,
    this.nextBefore,
  });

  factory ChatMessagePageModel.fromJson(Map<String, dynamic> json) {
    final rows = json['messages'] is List ? json['messages'] as List : const [];
    return ChatMessagePageModel(
      messages: rows
          .whereType<Map>()
          .map((row) => ChatMessageModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false),
      hasMore: _bool(json['has_more']),
      nextBefore: _optional(json['next_before']),
    );
  }
}

ChatMessageType _type(dynamic value) {
  switch (value?.toString().toLowerCase()) {
    case 'image':
      return ChatMessageType.image;
    case 'file':
      return ChatMessageType.file;
    default:
      return ChatMessageType.text;
  }
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _optional(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return {'1', 'true', 'yes', 'on'}.contains(value?.toString().toLowerCase());
}

DateTime? _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text.replaceFirst(' ', 'T'));
}
