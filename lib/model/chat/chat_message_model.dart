import 'chat_reaction_model.dart';

enum ChatMessageType { text, image, file }

class ChatMentionModel {
  final String user;
  final String employee;
  final String employeeName;
  final String? image;
  final String? designation;
  final String? department;

  const ChatMentionModel({
    required this.user,
    required this.employee,
    required this.employeeName,
    this.image,
    this.designation,
    this.department,
  });

  factory ChatMentionModel.fromJson(Map<String, dynamic> json) {
    final employee = _string(json['employee'], fallback: _string(json['name']));
    return ChatMentionModel(
      user: _string(json['user'], fallback: _string(json['user_id'])),
      employee: employee,
      employeeName: _string(json['employee_name'], fallback: employee),
      image: _optional(json['image']),
      designation: _optional(json['designation']),
      department: _optional(json['department']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'employee': employee,
    'employee_name': employeeName,
  };
}

class ChatReplyPreviewModel {
  final String name;
  final String sender;
  final String senderName;
  final String? senderImage;
  final String? message;
  final ChatMessageType messageType;
  final bool isDeleted;

  const ChatReplyPreviewModel({
    required this.name,
    required this.sender,
    required this.senderName,
    this.senderImage,
    this.message,
    required this.messageType,
    required this.isDeleted,
  });

  factory ChatReplyPreviewModel.fromJson(Map<String, dynamic> json) {
    return ChatReplyPreviewModel(
      name: _string(json['name']),
      sender: _string(json['sender']),
      senderName: _string(json['sender_name'], fallback: _string(json['sender'])),
      senderImage: _optional(json['sender_image']),
      message: _optional(json['message']),
      messageType: _type(json['message_type']),
      isDeleted: _bool(json['is_deleted']),
    );
  }
}

class ChatMessageReadStatusModel {
  final String user;
  final String employee;
  final String employeeName;
  final String? image;
  final String status;
  final DateTime? readAt;

  const ChatMessageReadStatusModel({
    required this.user,
    required this.employee,
    required this.employeeName,
    this.image,
    required this.status,
    this.readAt,
  });

  factory ChatMessageReadStatusModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageReadStatusModel(
      user: _string(json['user']),
      employee: _string(json['employee']),
      employeeName: _string(json['employee_name'], fallback: _string(json['employee'])),
      image: _optional(json['image']),
      status: _string(json['status'], fallback: 'Delivered'),
      readAt: _date(json['read_at']),
    );
  }

  bool get isRead => status.toLowerCase() == 'read';
}

class ChatMessageModel {
  final String name;
  final String chatGroup;
  final String sender;
  final String senderName;
  final String? senderImage;
  final String? message;
  final ChatMessageType messageType;
  final String? attachment;
  final DateTime? sentAt;
  final bool isDeleted;
  final bool isMine;
  final ChatReplyPreviewModel? replyTo;
  final String? forwardedFrom;
  final bool isForwarded;
  final List<ChatMentionModel> mentions;
  final DateTime? editedAt;
  final bool isEdited;
  final List<ChatReactionModel> reactions;
  final bool isBookmarked;
  final List<ChatMessageReadStatusModel> readStatuses;

  const ChatMessageModel({
    required this.name,
    required this.chatGroup,
    required this.sender,
    required this.senderName,
    this.senderImage,
    this.message,
    required this.messageType,
    this.attachment,
    this.sentAt,
    required this.isDeleted,
    required this.isMine,
    this.replyTo,
    this.forwardedFrom,
    this.isForwarded = false,
    this.mentions = const [],
    this.editedAt,
    this.isEdited = false,
    this.reactions = const [],
    this.isBookmarked = false,
    this.readStatuses = const [],
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final replyJson = json['reply_to'];
    return ChatMessageModel(
      name: _string(json['name']),
      chatGroup: _string(json['chat_group']),
      sender: _string(json['sender']),
      senderName: _string(json['sender_name'], fallback: _string(json['sender'])),
      senderImage: _optional(json['sender_image']),
      message: _optional(json['message']),
      messageType: _type(json['message_type']),
      attachment: _optional(json['attachment']),
      sentAt: _date(json['sent_at']),
      isDeleted: _bool(json['is_deleted']),
      isMine: _bool(json['is_mine']),
      replyTo: replyJson is Map
          ? ChatReplyPreviewModel.fromJson(Map<String, dynamic>.from(replyJson))
          : null,
      forwardedFrom: _optional(json['forwarded_from']),
      isForwarded: _bool(json['is_forwarded']) || _optional(json['forwarded_from']) != null,
      mentions: _modelList(json['mentions'], ChatMentionModel.fromJson),
      editedAt: _date(json['edited_at']),
      isEdited: _bool(json['is_edited']) || _date(json['edited_at']) != null,
      reactions: _modelList(json['reactions'], ChatReactionModel.fromJson),
      isBookmarked: _bool(json['is_bookmarked'] ?? json['bookmarked']),
      readStatuses: _modelList(json['read_statuses'] ?? json['statuses'], ChatMessageReadStatusModel.fromJson),
    );
  }

  String get messageTypeValue => switch (messageType) {
    ChatMessageType.text => 'Text',
    ChatMessageType.image => 'Image',
    ChatMessageType.file => 'File',
  };

  int get reactionCount => reactions.fold(0, (sum, item) => sum + item.count);

  ChatMessageModel copyWith({
    String? senderName,
    String? senderImage,
    String? message,
    String? attachment,
    bool? isDeleted,
    bool? isMine,
    ChatReplyPreviewModel? replyTo,
    String? forwardedFrom,
    bool? isForwarded,
    List<ChatMentionModel>? mentions,
    DateTime? editedAt,
    bool? isEdited,
    List<ChatReactionModel>? reactions,
    bool? isBookmarked,
    List<ChatMessageReadStatusModel>? readStatuses,
  }) {
    final deleted = isDeleted ?? this.isDeleted;
    return ChatMessageModel(
      name: name,
      chatGroup: chatGroup,
      sender: sender,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      message: deleted ? null : (message ?? this.message),
      messageType: messageType,
      attachment: deleted ? null : (attachment ?? this.attachment),
      sentAt: sentAt,
      isDeleted: deleted,
      isMine: isMine ?? this.isMine,
      replyTo: replyTo ?? this.replyTo,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      isForwarded: isForwarded ?? this.isForwarded,
      mentions: mentions ?? this.mentions,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      reactions: reactions ?? this.reactions,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      readStatuses: readStatuses ?? this.readStatuses,
    );
  }
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
    return ChatMessagePageModel(
      messages: _modelList(json['messages'], ChatMessageModel.fromJson),
      hasMore: _bool(json['has_more']),
      nextBefore: _optional(json['next_before']),
    );
  }
}

List<T> _modelList<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((row) => fromJson(Map<String, dynamic>.from(row)))
      .toList(growable: false);
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
  return const {'1', 'true', 'yes', 'on'}
      .contains(value?.toString().toLowerCase());
}

DateTime? _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text.replaceFirst(' ', 'T'));
}
