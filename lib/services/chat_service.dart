import 'dart:convert';

import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../model/chat/chat_group_model.dart';
import '../model/chat/chat_member_model.dart';
import '../model/chat/chat_message_model.dart';
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
  }) async {
    _required(groupName, 'Group name is required.');
    if (members.isEmpty) throw Exception('Select at least one employee.');
    final data = await _post(
      ApiEndpoints.createChatGroup,
      data: {
        'group_name': groupName.trim(),
        'description': description?.trim() ?? '',
        'members': members.map((member) => member.toJson()).toList(),
      },
    );
    return ChatGroupDetailsModel.fromJson(data);
  }

  Future<ChatGroupDetailsModel> updateGroup({
    required String group,
    String? groupName,
    String? description,
    bool? isActive,
  }) async {
    _required(group, 'Chat group is required.');
    if (groupName != null) _required(groupName, 'Group name is required.');
    final data = await _post(
      ApiEndpoints.updateChatGroup,
      data: {
        'group': group.trim(),
        if (groupName != null) 'group_name': groupName.trim(),
        if (description != null) 'description': description.trim(),
        if (isActive != null) 'is_active': isActive ? 1 : 0,
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

class ChatMemberInput {
  final String employee;
  final bool canSend;

  const ChatMemberInput({required this.employee, this.canSend = true});

  Map<String, dynamic> toJson() => {
        'employee': employee.trim(),
        'can_send': canSend ? 1 : 0,
      };
}
