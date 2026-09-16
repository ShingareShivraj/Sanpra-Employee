import 'dart:convert';

import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../model/chat/chat_group_model.dart';
import '../model/chat/chat_member_model.dart';
import '../model/chat/chat_message_model.dart';
import '../model/chat/chat_reaction_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _api;

  ChatService({ApiService? api}) : _api = api ?? ApiService();

  Future<ChatAccessModel> getChatAccess() async =>
      ChatAccessModel.fromJson(await _get(ApiEndpoints.chatAccess));

  Future<List<ChatEmployeeModel>> getAvailableEmployees({
    String? search,
    int limit = 50,
  }) async {
    final data = await _get(
      ApiEndpoints.chatEmployees,
      query: {
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        'limit': limit.clamp(1, 100),
      },
    );
    return _list(data['employees'])
        .map((row) => ChatEmployeeModel.fromJson(_map(row)))
        .toList(growable: false);
  }

  Future<List<ChatGroupModel>> getMyGroups() async {
    final data = await _get(ApiEndpoints.myChatGroups);
    return _list(data['groups'])
        .map((row) => ChatGroupModel.fromJson(_map(row)))
        .toList(growable: false);
  }

  Future<ChatGroupDetailsModel> getGroupDetails(String group) async {
    _required(group, 'Chat group is required.');
    return ChatGroupDetailsModel.fromJson(
      await _get(ApiEndpoints.chatGroupDetails, query: {'group': group.trim()}),
    );
  }

  Future<ChatMessagePageModel> getMessages({
    required String group,
    int limit = 40,
    String? before,
  }) async {
    _required(group, 'Chat group is required.');
    return ChatMessagePageModel.fromJson(
      await _get(
        ApiEndpoints.chatMessages,
        query: {
          'group': group.trim(),
          'limit': limit.clamp(1, 100),
          if (before?.trim().isNotEmpty == true) 'before': before!.trim(),
        },
      ),
    );
  }

  Future<ChatMessageModel> sendMessage({
    required String group,
    String? message,
    ChatMessageType messageType = ChatMessageType.text,
    String? attachment,
    String? replyTo,
    String? forwardedFrom,
    List<ChatMentionModel> mentions = const [],
  }) async {
    _required(group, 'Chat group is required.');
    if (messageType == ChatMessageType.text) {
      _required(message ?? '', 'Please enter a message.');
    } else {
      _required(attachment ?? '', 'Please select an attachment.');
    }
    final data = await _post(
      ApiEndpoints.sendChatMessage,
      data: {
        'group': group.trim(),
        'message': message?.trim() ?? '',
        'message_type': _messageType(messageType),
        if (attachment?.trim().isNotEmpty == true) 'attachment': attachment!.trim(),
        if (replyTo?.trim().isNotEmpty == true) 'reply_to': replyTo!.trim(),
        if (forwardedFrom?.trim().isNotEmpty == true)
          'forwarded_from': forwardedFrom!.trim(),
        if (mentions.isNotEmpty)
          'mentions': mentions.map((mention) => mention.toJson()).toList(),
      },
    );
    return ChatMessageModel.fromJson(data);
  }

  Future<String> uploadAttachment({
    required String filePath,
    required String fileName,
    bool isPrivate = true,
  }) async {
    _required(filePath, 'File path is required.');
    _required(fileName, 'File name is required.');
    try {
      final response = await _api.postMultipart(
        url: ApiEndpoints.uploadFile,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: fileName),
          'is_private': isPrivate ? 1 : 0,
        }),
      );
      final data = _message(response.data);
      final fileUrl = data['file_url']?.toString().trim() ?? '';
      if (fileUrl.isEmpty) throw Exception('File upload did not return a file URL.');
      return fileUrl;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error));
    }
  }


  Future<String> downloadAttachment({
    required String fileUrl,
    String? fileName,
  }) async {
    _required(fileUrl, 'Attachment URL is required.');

    try {
      final directory = await getApplicationDocumentsDirectory();

      String name = fileName?.trim() ?? '';

      if (name.isEmpty) {
        final uri = Uri.tryParse(fileUrl);

        if (uri != null && uri.pathSegments.isNotEmpty) {
          name = uri.pathSegments.last;
        }
      }

      if (name.isEmpty) {
        name = 'chat_attachment';
      }

      name = name.split('?').first;

      final filePath = '${directory.path}/$name';

      await _api.download(
        url: fileUrl,
        savePath: filePath,
      );

      return filePath;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<void> markGroupRead(String group) async {
    _required(group, 'Chat group is required.');
    await _post(ApiEndpoints.markChatGroupRead, data: {'group': group.trim()});
  }

  Future<void> deleteMessage(String message) async {
    _required(message, 'Chat message is required.');
    await _post(ApiEndpoints.deleteChatMessage, data: {'message': message.trim()});
  }

  Future<ChatGroupDetailsModel> createGroup({
    required String groupName,
    String? description,
    required List<ChatMemberInput> members,
    File? groupImage,
  }) async {
    _required(groupName, 'Group name is required.');
    if (members.isEmpty) throw Exception('Select at least one employee.');

    // Upload the group image first, then send the returned Frappe file URL
    // to the create-group API.
    String? groupImageUrl;
    if (groupImage != null) {
      groupImageUrl = await uploadAttachment(
        filePath: groupImage.path,
        fileName: groupImage.uri.pathSegments.isNotEmpty
            ? groupImage.uri.pathSegments.last
            : 'group_image',
        isPrivate: false,
      );
    }

    final data = await _post(
      ApiEndpoints.createChatGroup,
      data: {
        'group_name': groupName.trim(),
        'description': description?.trim() ?? '',
        'members': members.map((member) => member.toJson()).toList(),
        if (groupImageUrl != null && groupImageUrl.isNotEmpty)
          'group_image': groupImageUrl,
      },
    );
    return ChatGroupDetailsModel.fromJson(data);
  }

  Future<ChatGroupDetailsModel> updateGroup({
    required String group,
    String? groupName,
    String? description,
    bool? isActive,
    File? groupImage,
  }) async {
    _required(group, 'Chat group is required.');
    if (groupName != null) _required(groupName, 'Group name is required.');

    // Upload the new image first, then pass its Frappe file URL to the
    // update-group API.
    String? groupImageUrl;
    if (groupImage != null) {
      groupImageUrl = await uploadAttachment(
        filePath: groupImage.path,
        fileName: groupImage.uri.pathSegments.isNotEmpty
            ? groupImage.uri.pathSegments.last
            : 'group_image',
        isPrivate: false,
      );
    }

    final data = await _post(
      ApiEndpoints.updateChatGroup,
      data: {
        'group': group.trim(),
        if (groupName != null) 'group_name': groupName.trim(),
        if (description != null) 'description': description.trim(),
        if (isActive != null) 'is_active': isActive ? 1 : 0,
        if (groupImageUrl != null && groupImageUrl.isNotEmpty)
          'group_image': groupImageUrl,
      },
    );
    return ChatGroupDetailsModel.fromJson(data);
  }

  Future<void> addMembers({
    required String group,
    required List<ChatMemberInput> members,
  }) async {
    _required(group, 'Chat group is required.');
    if (members.isEmpty) throw Exception('Select at least one employee.');
    await _post(
      ApiEndpoints.addChatMembers,
      data: {
        'group': group.trim(),
        'members': members.map((member) => member.toJson()).toList(),
      },
    );
  }

  Future<void> removeMember({required String group, required String employee}) async {
    _required(group, 'Chat group is required.');
    _required(employee, 'Employee is required.');
    await _post(
      ApiEndpoints.removeChatMember,
      data: {'group': group.trim(), 'employee': employee.trim()},
    );
  }

  Future<void> updateMemberPermission({
    required String group,
    required String employee,
    required bool canSend,
  }) async {
    _required(group, 'Chat group is required.');
    _required(employee, 'Employee is required.');
    await _post(
      ApiEndpoints.updateChatMemberPermission,
      data: {
        'group': group.trim(),
        'employee': employee.trim(),
        'can_send': canSend ? 1 : 0,
      },
    );
  }

  Future<List<ChatMentionModel>> searchGroupMembers({
    required String group,
    String? search,
    int limit = 30,
  }) async {
    _required(group, 'Chat group is required.');
    final data = await _get(
      _chatEndpoint('search_group_members'),
      query: {
        'group': group.trim(),
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        'limit': limit.clamp(1, 100),
      },
    );
    return _list(data['members'])
        .map((row) => ChatMentionModel.fromJson(_map(row)))
        .toList(growable: false);
  }

  Future<List<ChatGroupModel>> getForwardGroups() async {
    final data = await _get(_chatEndpoint('get_forward_groups'));
    return _list(data['groups'])
        .map((row) => ChatGroupModel.fromJson(_map(row)))
        .toList(growable: false);
  }

  Future<ChatMessagePageModel> searchMessages({
    required String group,
    required String search,
    int limit = 40,
    String? before,
  }) async {
    _required(group, 'Chat group is required.');
    _required(search, 'Enter text to search.');
    return ChatMessagePageModel.fromJson(
      await _get(
        _chatEndpoint('search_messages'),
        query: {
          'group': group.trim(),
          'search': search.trim(),
          'limit': limit.clamp(1, 100),
          if (before?.trim().isNotEmpty == true) 'before': before!.trim(),
        },
      ),
    );
  }

  Future<ChatMessageModel> editMessage({
    required String message,
    required String text,
  }) async {
    _required(message, 'Chat message is required.');
    _required(text, 'Please enter a message.');
    return ChatMessageModel.fromJson(
      await _post(
        _chatEndpoint('edit_message'),
        data: {'message': message.trim(), 'text': text.trim()},
      ),
    );
  }

  Future<List<ChatMessageModel>> forwardMessage({
    required String message,
    required List<String> groups,
  }) async {
    _required(message, 'Chat message is required.');
    final destinations = groups.map((item) => item.trim()).where((item) => item.isNotEmpty).toSet().toList();
    if (destinations.isEmpty) throw Exception('Select at least one destination group.');
    final data = await _post(
      _chatEndpoint('forward_message'),
      data: {'message': message.trim(), 'groups': destinations},
    );
    return _list(data['messages'])
        .map((row) => ChatMessageModel.fromJson(_map(row)))
        .toList(growable: false);
  }

  Future<List<ChatReactionModel>> setMessageReaction({
    required String message,
    required String reaction,
  }) async {
    _required(message, 'Chat message is required.');
    _required(reaction, 'Select a reaction.');
    final data = await _post(
      _chatEndpoint('set_message_reaction'),
      data: {'message': message.trim(), 'reaction': reaction.trim()},
    );
    return _parseReactions(data['reactions']);
  }

  Future<List<ChatReactionModel>> removeMessageReaction(String message) async {
    _required(message, 'Chat message is required.');
    final data = await _post(
      _chatEndpoint('remove_reaction'),
      data: {'message': message.trim()},
    );
    return _parseReactions(data['reactions']);
  }

  Future<bool> toggleBookmark({
    required String message,
    required bool bookmarked,
  }) async {
    _required(message, 'Chat message is required.');
    final data = await _post(
      _chatEndpoint('toggle_bookmark'),
      data: {'message': message.trim(), 'bookmarked': bookmarked ? 1 : 0},
    );
    return _bool(data['bookmarked']);
  }

  Future<ChatMessagePageModel> getBookmarkedMessages({
    int limit = 50,
    String? before,
  }) async {
    return ChatMessagePageModel.fromJson(
      await _get(
        _chatEndpoint('get_bookmarked_messages'),
        query: {
          'limit': limit.clamp(1, 100),
          if (before?.trim().isNotEmpty == true) 'before': before!.trim(),
        },
      ),
    );
  }

  Future<bool> pinMessage(String message) => _setPinned(message, true);

  Future<bool> unpinMessage(String message) => _setPinned(message, false);

  Future<bool> _setPinned(String message, bool pinned) async {
    _required(message, 'Chat message is required.');
    final data = await _post(
      _chatEndpoint('pin_message'),
      data: {'message': message.trim(), 'pinned': pinned ? 1 : 0},
    );
    return _bool(data['pinned']);
  }

  Future<List<ChatMessageModel>> getPinnedMessages(String group) async {
    _required(group, 'Chat group is required.');
    final data = await _get(
      _chatEndpoint('get_pinned_messages'),
      query: {'group': group.trim()},
    );
    return _list(data['messages'])
        .map((row) => ChatMessageModel.fromJson(_map(row)))
        .toList(growable: false);
  }

  Future<ChatGroupMuteSetting> setGroupMute({
    required String group,
    required String duration,
  }) async {
    _required(group, 'Chat group is required.');
    _required(duration, 'Mute duration is required.');
    return ChatGroupMuteSetting.fromJson(
      await _post(
        _chatEndpoint('set_group_mute'),
        data: {'group': group.trim(), 'duration': duration.trim()},
      ),
    );
  }

  Future<ChatGroupMuteSetting> getGroupNotificationSetting(String group) async {
    _required(group, 'Chat group is required.');
    return ChatGroupMuteSetting.fromJson(
      await _get(
        _chatEndpoint('get_group_notification_setting'),
        query: {'group': group.trim()},
      ),
    );
  }

  Future<Map<String, dynamic>> publishTyping({
    required String group,
    required bool isTyping,
  }) async {
    _required(group, 'Chat group is required.');
    return _post(
      _chatEndpoint('publish_typing'),
      data: {'group': group.trim(), 'is_typing': isTyping ? 1 : 0},
    );
  }

  Future<Map<String, dynamic>> publishPresence({
    required String group,
    required bool isOnline,
  }) async {
    _required(group, 'Chat group is required.');
    return _post(
      _chatEndpoint('publish_presence'),
      data: {'group': group.trim(), 'is_online': isOnline ? 1 : 0},
    );
  }

  Future<List<ChatMessageReadStatusModel>> getMessageReadStatus(String message) async {
    _required(message, 'Chat message is required.');
    final data = await _get(
      _chatEndpoint('get_message_read_status'),
      query: {'message': message.trim()},
    );
    return _list(data['statuses'])
        .map((row) => ChatMessageReadStatusModel.fromJson(_map(row)))
        .toList(growable: false);
  }

  Future<ChatMessagePageModel> getChatMedia({
    required String group,
    String mediaType = 'all',
    int limit = 50,
    String? before,
  }) async {
    _required(group, 'Chat group is required.');
    return ChatMessagePageModel.fromJson(
      await _get(
        _chatEndpoint('get_chat_media'),
        query: {
          'group': group.trim(),
          'media_type': mediaType.trim().toLowerCase(),
          'limit': limit.clamp(1, 100),
          if (before?.trim().isNotEmpty == true) 'before': before!.trim(),
        },
      ),
    );
  }

  String _chatEndpoint(String method) => '${ApiEndpoints.chatApi}.$method';

  List<ChatReactionModel> _parseReactions(dynamic value) => _list(value)
      .map((row) => ChatReactionModel.fromJson(_map(row)))
      .toList(growable: false);

  bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return const {'1', 'true', 'yes', 'on'}
        .contains(value?.toString().toLowerCase());
  }

  Future<Map<String, dynamic>> _get(
      String url, {
        Map<String, dynamic>? query,
      }) async {
    try {
      return _message((await _api.get(url: url, queryParameters: query)).data);
    } on DioException catch (error) {
      throw Exception(_dioMessage(error));
    }
  }

  Future<Map<String, dynamic>> _post(
      String url, {
        required Map<String, dynamic> data,
      }) async {
    try {
      return _message((await _api.post(url: url, data: data)).data);
    } on DioException catch (error) {
      throw Exception(_dioMessage(error));
    }
  }

  Map<String, dynamic> _message(dynamic value) {
    final root = _map(value);
    return root['message'] is Map ? _map(root['message']) : root;
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<dynamic> _list(dynamic value) => value is List ? value : const [];

  void _required(String value, String message) {
    if (value.trim().isEmpty) throw Exception(message);
  }

  String _messageType(ChatMessageType type) => switch (type) {
    ChatMessageType.text => 'Text',
    ChatMessageType.image => 'Image',
    ChatMessageType.file => 'File',
  };

  String _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final serverMessages = data['_server_messages'];
      if (serverMessages is String) {
        try {
          final messages = jsonDecode(serverMessages);
          if (messages is List && messages.isNotEmpty) {
            final first = jsonDecode(messages.first.toString());
            if (first is Map && first['message'] != null) return first['message'].toString();
          }
        } catch (_) {}
      }
      final message = data['message'];
      if (message is Map && message['message'] != null) return message['message'].toString();
      if (message is String && message.isNotEmpty) return message;
      if (data['exception'] != null) return data['exception'].toString();
    }
    return error.message ?? 'Unable to process the chat request.';
  }
}

class ChatGroupMuteSetting {
  final String group;
  final DateTime? mutedUntil;
  final bool isMuted;

  const ChatGroupMuteSetting({
    required this.group,
    this.mutedUntil,
    required this.isMuted,
  });

  factory ChatGroupMuteSetting.fromJson(Map<String, dynamic> json) {
    final rawDate = json['muted_until']?.toString().trim() ?? '';
    final mutedUntil = rawDate.isEmpty
        ? null
        : DateTime.tryParse(rawDate.replaceFirst(' ', 'T'));
    bool asBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      return const {'1', 'true', 'yes', 'on'}
          .contains(value?.toString().toLowerCase());
    }

    return ChatGroupMuteSetting(
      group: json['group']?.toString() ?? '',
      mutedUntil: mutedUntil,
      isMuted: json.containsKey('is_muted')
          ? asBool(json['is_muted'])
          : mutedUntil != null && mutedUntil.isAfter(DateTime.now()),
    );
  }
}

class ChatMemberInput {
  final String employee;
  final bool canSend;

  const ChatMemberInput({required this.employee, this.canSend = true});

  Map<String, dynamic> toJson() => {
    'employee': employee.trim(),
    'can_send': canSend ? 1 : 0,
  };
}
