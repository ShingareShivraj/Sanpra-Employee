import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/chat/chat_group_model.dart';
import '../../model/chat/chat_message_model.dart';
import '../../services/chat_service.dart';

class ChatConversationViewModel extends ChangeNotifier {
  final String groupName;
  final ChatService _service;
  final Stream<Map<String, dynamic>>? _messageEvents;
  final Stream<Map<String, dynamic>>? _deletedEvents;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _deletedSubscription;

  ChatConversationViewModel({
    required this.groupName,
    ChatService? service,
    Stream<Map<String, dynamic>>? messageEvents,
    Stream<Map<String, dynamic>>? deletedEvents,
  })  : _service = service ?? ChatService(),
        _messageEvents = messageEvents,
        _deletedEvents = deletedEvents;

  final List<ChatMessageModel> _messages = [];
  ChatGroupDetailsModel? _details;
  bool _loading = false;
  bool _loadingOlder = false;
  bool _sending = false;
  bool _uploading = false;
  bool _hasMore = true;
  String? _nextBefore;
  String? _error;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  ChatGroupDetailsModel? get details => _details;
  ChatGroupModel? get group => _details?.group;
  bool get loading => _loading;
  bool get loadingOlder => _loadingOlder;
  bool get sending => _sending;
  bool get uploading => _uploading;
  bool get busy => _sending || _uploading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get canSend => group?.canSend == true && group?.isActive == true;

  Future<void> initialise() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await Future.wait<dynamic>([
        _service.getGroupDetails(groupName),
        _service.getMessages(group: groupName),
      ]);
      _details = result[0] as ChatGroupDetailsModel;
      _applyPage(result[1] as ChatMessagePageModel, replace: true);
      await _markReadSilently();
      _listenRealtime();
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      _error = null;
      final result = await Future.wait<dynamic>([
        _service.getGroupDetails(groupName),
        _service.getMessages(group: groupName),
      ]);
      _details = result[0] as ChatGroupDetailsModel;
      _applyPage(result[1] as ChatMessagePageModel, replace: true);
      await _markReadSilently();
    } catch (error) {
      _error = _cleanError(error);
    }
    notifyListeners();
  }

  Future<void> loadOlder() async {
    if (_loadingOlder || !_hasMore || _nextBefore == null) return;
    _loadingOlder = true;
    notifyListeners();
    try {
      final page = await _service.getMessages(
        group: groupName,
        before: _nextBefore,
      );
      _applyPage(page, replace: false);
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _loadingOlder = false;
      notifyListeners();
    }
  }

  Future<bool> sendText(String value) async {
    final text = value.trim();
    if (text.isEmpty || busy || !canSend) return false;
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final message = await _service.sendMessage(
        group: groupName,
        message: text,
      );
      _addMessage(message);
      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<bool> sendAttachment({
    required String filePath,
    required String fileName,
    required ChatMessageType type,
    String? caption,
  }) async {
    if (busy || !canSend || type == ChatMessageType.text) return false;
    _uploading = true;
    _error = null;
    notifyListeners();
    try {
      final fileUrl = await _service.uploadAttachment(
        filePath: filePath,
        fileName: fileName,
      );
      final message = await _service.sendMessage(
        group: groupName,
        message: caption,
        messageType: type,
        attachment: fileUrl,
      );
      _addMessage(message);
      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  Future<String?> downloadAttachment(ChatMessageModel message) async {
    final attachment = message.attachment;

    if (attachment == null || attachment.trim().isEmpty) {
      return null;
    }

    try {
      return await _service.downloadAttachment(
        fileUrl: attachment,
      );
    } catch (error) {
      _error = _cleanError(error);
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteMessage(ChatMessageModel message) async {
    if (!message.isMine || message.isDeleted || busy) return false;
    try {
      await _service.deleteMessage(message.name);
      _markDeleted(message.name);
      return true;
    } catch (error) {
      _error = _cleanError(error);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _applyPage(ChatMessagePageModel page, {required bool replace}) {
    if (replace) _messages.clear();
    for (final message in page.messages) {
      if (_messages.every((current) => current.name != message.name)) {
        replace ? _messages.add(message) : _messages.insert(0, message);
      }
    }
    _messages.sort((a, b) {
      final left = a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return left.compareTo(right);
    });
    _hasMore = page.hasMore;
    _nextBefore = page.nextBefore;
  }

  void _addMessage(ChatMessageModel message) {
    if (message.chatGroup != groupName ||
        _messages.any((current) => current.name == message.name)) return;
    _messages.add(message);
    _messages.sort((a, b) =>
        (a.sentAt ?? DateTime.now()).compareTo(b.sentAt ?? DateTime.now()));
    notifyListeners();
  }

  void _markDeleted(String name) {
    final index = _messages.indexWhere((message) => message.name == name);
    if (index < 0) return;
    _messages[index] = _messages[index].copyWith(isDeleted: true);
    notifyListeners();
  }

  void _listenRealtime() {
    _messageSubscription ??= _messageEvents?.listen(handleRealtimeMessage);
    _deletedSubscription ??= _deletedEvents?.listen(handleRealtimeDeleted);
  }

  void handleRealtimeMessage(Map<String, dynamic> event) {
    if (event['group']?.toString() != groupName || event['message'] is! Map) return;
    final messageJson = Map<String, dynamic>.from(event['message'] as Map);
    final currentUser = _details?.members
        .where((member) => member.isCurrentUser)
        .map((member) => member.user)
        .firstOrNull;
    messageJson['is_mine'] = messageJson['sender']?.toString() == currentUser;
    _addMessage(ChatMessageModel.fromJson(messageJson));
    unawaited(_markReadSilently());
  }

  void handleRealtimeDeleted(Map<String, dynamic> event) {
    if (event['group']?.toString() != groupName) return;
    _markDeleted(event['message']?.toString() ?? '');
  }

  Future<void> _markReadSilently() async {
    try {
      await _service.markGroupRead(groupName);
    } catch (_) {}
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _deletedSubscription?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
