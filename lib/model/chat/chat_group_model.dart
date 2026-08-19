import 'chat_member_model.dart';

class ChatAccessModel {
  final String user;
  final bool isChatManager;

  const ChatAccessModel({required this.user, required this.isChatManager});

  factory ChatAccessModel.fromJson(Map<String, dynamic> json) => ChatAccessModel(
        user: _string(json['user']),
        isChatManager: _bool(json['is_chat_manager']),
      );
}

class ChatGroupModel {
  final String name;
  final String groupName;
  final String? description;
  final String? createdBy;
  final bool isActive;
  final bool canSend;
  final bool canManage;
  final int unreadCount;
  final int memberCount;
  final String? lastMessage;
  final String? lastMessageSender;
  final DateTime? lastMessageAt;
  final DateTime? activityAt;
  final List<ChatMemberModel> members;

  const ChatGroupModel({
    required this.name,
    required this.groupName,
    this.description,
    this.createdBy,
    required this.isActive,
    required this.canSend,
    required this.canManage,
    required this.unreadCount,
    required this.memberCount,
    this.lastMessage,
    this.lastMessageSender,
    this.lastMessageAt,
    this.activityAt,
    this.members = const [],
  });

  factory ChatGroupModel.fromJson(Map<String, dynamic> json) {
    final memberData = json['members'];
    final members = memberData is List
        ? memberData
            .whereType<Map>()
            .map((row) => ChatMemberModel.fromJson(Map<String, dynamic>.from(row)))
            .toList(growable: false)
        : const <ChatMemberModel>[];
    return ChatGroupModel(
      name: _string(json['name']),
      groupName: _string(json['group_name'], fallback: _string(json['name'])),
      description: _optional(json['description']),
      createdBy: _optional(json['created_by']),
      isActive: json.containsKey('is_active') ? _bool(json['is_active']) : true,
      canSend: _bool(json['can_send']),
      canManage: _bool(json['can_manage']),
      unreadCount: _int(json['unread_count']),
      memberCount: _int(json['member_count'], fallback: members.length),
      lastMessage: _optional(json['last_message']),
      lastMessageSender: _optional(json['last_message_sender']),
      lastMessageAt: _date(json['last_message_at']),
      activityAt: _date(json['activity_at']),
      members: members,
    );
  }

  ChatGroupModel copyWith({
    int? unreadCount,
    String? lastMessage,
    String? lastMessageSender,
    DateTime? lastMessageAt,
    DateTime? activityAt,
    bool? canSend,
    bool? isActive,
    List<ChatMemberModel>? members,
  }) =>
      ChatGroupModel(
        name: name,
        groupName: groupName,
        description: description,
        createdBy: createdBy,
        isActive: isActive ?? this.isActive,
        canSend: canSend ?? this.canSend,
        canManage: canManage,
        unreadCount: unreadCount ?? this.unreadCount,
        memberCount: members?.length ?? memberCount,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageSender: lastMessageSender ?? this.lastMessageSender,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        activityAt: activityAt ?? this.activityAt,
        members: members ?? this.members,
      );
}

class ChatGroupDetailsModel {
  final ChatGroupModel group;
  final List<ChatMemberModel> members;

  const ChatGroupDetailsModel({required this.group, required this.members});

  factory ChatGroupDetailsModel.fromJson(Map<String, dynamic> json) {
    final rows = json['members'] is List ? json['members'] as List : const [];
    final members = rows
        .whereType<Map>()
        .map((row) => ChatMemberModel.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
    final groupJson = json['group'] is Map
        ? Map<String, dynamic>.from(json['group'] as Map)
        : <String, dynamic>{};
    groupJson['members'] = rows;
    groupJson['member_count'] ??= members.length;
    return ChatGroupDetailsModel(
      group: ChatGroupModel.fromJson(groupJson),
      members: members,
    );
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

int _int(dynamic value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;

DateTime? _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text.replaceFirst(' ', 'T'));
}
