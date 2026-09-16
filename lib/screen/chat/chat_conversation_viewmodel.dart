import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/chat/chat_group_model.dart';
import '../../model/chat/chat_message_model.dart';
import '../../model/chat/chat_reaction_model.dart';
import '../../services/chat_service.dart';

class ChatConversationViewModel extends ChangeNotifier {
  static final Map<String, String> _localDrafts = <String, String>{};
  final String groupName;
  final ChatService _service;
  final Stream<Map<String, dynamic>>? _messageEvents;
  final Stream<Map<String, dynamic>>? _deletedEvents;
  final Stream<Map<String, dynamic>>? _updatedEvents;
  final Stream<Map<String, dynamic>>? _reactionEvents;
  final Stream<Map<String, dynamic>>? _typingEvents;
  final Stream<Map<String, dynamic>>? _presenceEvents;

  ChatConversationViewModel({
    required this.groupName,
    ChatService? service,
    Stream<Map<String, dynamic>>? messageEvents,
    Stream<Map<String, dynamic>>? deletedEvents,
    Stream<Map<String, dynamic>>? updatedEvents,
    Stream<Map<String, dynamic>>? reactionEvents,
    Stream<Map<String, dynamic>>? typingEvents,
    Stream<Map<String, dynamic>>? presenceEvents,
  })  : _service = service ?? ChatService(),
        _messageEvents = messageEvents,
        _deletedEvents = deletedEvents,
        _updatedEvents = updatedEvents,
        _reactionEvents = reactionEvents,
        _typingEvents = typingEvents,
        _presenceEvents = presenceEvents;

  final List<ChatMessageModel> _messages = [];
  final List<ChatMessageModel> _searchResults = [];
  final List<ChatMessageModel> _pinnedMessages = [];
  final List<ChatMentionModel> _mentionResults = [];
  final List<ChatMentionModel> _selectedMentions = [];
  final Map<String, String> _typingUsers = {};
  final Set<String> _onlineUsers = {};
  final List<StreamSubscription<Map<String, dynamic>>> _subscriptions = [];

  ChatGroupDetailsModel? _details;
  ChatMessageModel? _replyingTo;
  ChatMessageModel? _editingMessage;
  bool _loading = false;
  bool _loadingOlder = false;
  bool _sending = false;
  bool _uploading = false;
  bool _searching = false;
  bool _searchMode = false;
  bool _mentionLoading = false;
  bool _hasMore = true;
  String? _nextBefore;
  String? _error;
  Timer? _mentionTimer;
  Timer? _typingStopTimer;
  bool _typingPublished = false;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  List<ChatMessageModel> get searchResults => List.unmodifiable(_searchResults);
  List<ChatMessageModel> get pinnedMessages => List.unmodifiable(_pinnedMessages);
  List<ChatMentionModel> get mentionResults => List.unmodifiable(_mentionResults);
  List<ChatMentionModel> get selectedMentions => List.unmodifiable(_selectedMentions);
  ChatGroupDetailsModel? get details => _details;
  ChatGroupModel? get group => _details?.group;
  ChatMessageModel? get replyingTo => _replyingTo;
  ChatMessageModel? get editingMessage => _editingMessage;
  bool get loading => _loading;
  bool get loadingOlder => _loadingOlder;
  bool get sending => _sending;
  bool get uploading => _uploading;
  bool get searching => _searching;
  bool get searchMode => _searchMode;
  bool get mentionLoading => _mentionLoading;
  bool get busy => _sending || _uploading;
  bool get hasMore => _hasMore;
  bool get canSend => group?.canSend == true && group?.isActive == true;
  bool get canManage => group?.canManage == true;
  String? get error => _error;
  String get draft => _localDrafts[groupName] ?? '';
  Set<String> get onlineUsers => Set.unmodifiable(_onlineUsers);
  String? get typingText {
    final names = _typingUsers.values.toList(growable: false);
    if (names.isEmpty) return null;
    if (names.length == 1) return '${names.first} is typing…';
    if (names.length == 2) return '${names[0]} and ${names[1]} are typing…';
    return '${names.length} people are typing…';
  }

  Future<void> initialise() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await Future.wait<dynamic>([
        _service.getGroupDetails(groupName),
        _service.getMessages(group: groupName),
        _service.getPinnedMessages(groupName),
      ]);
      _details = result[0] as ChatGroupDetailsModel;
      _applyPage(result[1] as ChatMessagePageModel, replace: true);
      _pinnedMessages
        ..clear()
        ..addAll(result[2] as List<ChatMessageModel>);
      await _markReadSilently();
      await _publishPresence(true);
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
        _service.getPinnedMessages(groupName),
      ]);
      _details = result[0] as ChatGroupDetailsModel;
      _applyPage(result[1] as ChatMessagePageModel, replace: true);
      _pinnedMessages
        ..clear()
        ..addAll(result[2] as List<ChatMessageModel>);
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
      _applyPage(await _service.getMessages(group: groupName, before: _nextBefore), replace: false);
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _loadingOlder = false;
      notifyListeners();
    }
  }

  void startReply(ChatMessageModel message) {
    if (message.isDeleted) return;
    _editingMessage = null;
    _replyingTo = message;
    notifyListeners();
  }

  void cancelReply() {
    _replyingTo = null;
    notifyListeners();
  }

  void startEdit(ChatMessageModel message) {
    if (!message.isMine || message.isDeleted || message.messageType != ChatMessageType.text) return;
    _replyingTo = null;
    _editingMessage = message;
    notifyListeners();
  }

  void cancelEdit() {
    _editingMessage = null;
    notifyListeners();
  }

  Future<bool> sendText(String value) async {
    final text = value.trim();
    if (text.isEmpty || busy || !canSend) return false;
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      if (_editingMessage != null) {
        _replaceMessage(await _service.editMessage(message: _editingMessage!.name, text: text));
      } else {
        _addMessage(await _service.sendMessage(
          group: groupName,
          message: text,
          replyTo: _replyingTo?.name,
          mentions: _selectedMentions,
        ));
      }
      _replyingTo = null;
      _editingMessage = null;
      _selectedMentions.clear();
      _localDrafts.remove(groupName);
      await publishTyping(false);
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
      final fileUrl = await _service.uploadAttachment(filePath: filePath, fileName: fileName);
      _addMessage(await _service.sendMessage(
        group: groupName,
        message: caption,
        messageType: type,
        attachment: fileUrl,
        replyTo: _replyingTo?.name,
      ));
      _replyingTo = null;
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
    if (message.attachment?.trim().isNotEmpty != true) return null;
    try {
      return await _service.downloadAttachment(fileUrl: message.attachment!);
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

  Future<bool> forwardMessage(ChatMessageModel message, List<String> groups) async {
    try {
      await _service.forwardMessage(message: message.name, groups: groups);
      return true;
    } catch (error) {
      _error = _cleanError(error);
      notifyListeners();
      return false;
    }
  }

  Future<List<ChatGroupModel>> loadForwardGroups() => _service.getForwardGroups();

  void searchMentions(String query) {
    _mentionTimer?.cancel();
    _mentionTimer = Timer(const Duration(milliseconds: 250), () => _loadMentions(query));
  }

  Future<void> _loadMentions(String query) async {
    _mentionLoading = true;
    notifyListeners();
    try {
      _mentionResults
        ..clear()
        ..addAll(await _service.searchGroupMembers(group: groupName, search: query));
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _mentionLoading = false;
      notifyListeners();
    }
  }

  void selectMention(ChatMentionModel mention) {
    if (_selectedMentions.every((item) => item.user != mention.user)) _selectedMentions.add(mention);
    _mentionResults.clear();
    notifyListeners();
  }

  void clearMentionResults() {
    _mentionResults.clear();
    notifyListeners();
  }

  Future<void> react(ChatMessageModel message, String reaction) async {
    try {
      final mine = message.reactions.where((item) => item.reactedByMe).map((item) => item.reaction).contains(reaction);
      final reactions = mine
          ? await _service.removeMessageReaction(message.name)
          : await _service.setMessageReaction(message: message.name, reaction: reaction);
      _replaceMessage(message.copyWith(reactions: reactions));
    } catch (error) {
      _error = _cleanError(error);
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(ChatMessageModel message) async {
    try {
      final value = await _service.toggleBookmark(message: message.name, bookmarked: !message.isBookmarked);
      _replaceMessage(message.copyWith(isBookmarked: value));
    } catch (error) {
      _error = _cleanError(error);
      notifyListeners();
    }
  }

  Future<void> togglePin(ChatMessageModel message) async {
    if (!canManage) return;
    try {
      final pinned = _pinnedMessages.any((item) => item.name == message.name);
      if (pinned) {
        await _service.unpinMessage(message.name);
        _pinnedMessages.removeWhere((item) => item.name == message.name);
      } else {
        await _service.pinMessage(message.name);
        _pinnedMessages.insert(0, message);
      }
      notifyListeners();
    } catch (error) {
      _error = _cleanError(error);
      notifyListeners();
    }
  }

  Future<void> searchMessages(String query) async {
    if (query.trim().isEmpty) return clearSearch();
    _searchMode = true;
    _searching = true;
    notifyListeners();
    try {
      final page = await _service.searchMessages(group: groupName, search: query.trim());
      _searchResults
        ..clear()
        ..addAll(page.messages);
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchMode = false;
    _searchResults.clear();
    notifyListeners();
  }

  Future<List<ChatMessageReadStatusModel>> loadReadStatus(ChatMessageModel message) {
    return _service.getMessageReadStatus(message.name);
  }

  Future<void> publishTyping(bool value) async {
    _typingStopTimer?.cancel();
    if (value == _typingPublished) {
      if (value) {
        _typingStopTimer = Timer(
          const Duration(seconds: 2),
              () => publishTyping(false),
        );
      }
      return;
    }
    _typingPublished = value;
    try {
      await _service.publishTyping(group: groupName, isTyping: value);
      if (value) {
        _typingStopTimer = Timer(const Duration(seconds: 2), () => publishTyping(false));
      }
    } catch (_) {
      _typingPublished = !value;
    }
  }

  void saveDraft(String value) {
    if (value.trim().isEmpty) {
      _localDrafts.remove(groupName);
    } else {
      _localDrafts[groupName] = value;
    }
  }

  Future<void> _publishPresence(bool value) async {
    try {
      await _service.publishPresence(group: groupName, isOnline: value);
    } catch (_) {}
  }

  void handleRealtimeMessage(Map<String, dynamic> event) {
    if (event['group']?.toString() != groupName || event['message'] is! Map) return;
    final json = Map<String, dynamic>.from(event['message'] as Map);
    json['is_mine'] = json['sender']?.toString() == _currentUser;
    _addMessage(ChatMessageModel.fromJson(json));
    unawaited(_markReadSilently());
  }

  void handleRealtimeDeleted(Map<String, dynamic> event) {
    if (event['group']?.toString() == groupName) _markDeleted(event['message']?.toString() ?? '');
  }

  void handleRealtimeUpdated(Map<String, dynamic> event) {
    if (event['group']?.toString() != groupName || event['message'] is! Map) return;
    final json = Map<String, dynamic>.from(event['message'] as Map);
    json['is_mine'] = json['sender']?.toString() == _currentUser;
    _replaceMessage(ChatMessageModel.fromJson(json));
  }

  void handleRealtimeReaction(Map<String, dynamic> event) {
    if (event['group']?.toString() != groupName) return;
    final index = _messages.indexWhere((item) => item.name == event['message']?.toString());
    if (index < 0) return;
    final reactions = event['reactions'] is List
        ? (event['reactions'] as List).whereType<Map>().map((item) => ChatReactionModel.fromJson(Map<String, dynamic>.from(item))).toList()
        : <ChatReactionModel>[];
    _messages[index] = _messages[index].copyWith(reactions: reactions);
    notifyListeners();
  }

  void handleRealtimeTyping(Map<String, dynamic> event) {
    if (event['group']?.toString() != groupName || event['user']?.toString() == _currentUser) return;
    final user = event['user']?.toString() ?? '';
    if (event['is_typing'] == true || event['is_typing'] == 1) {
      _typingUsers[user] = event['employee_name']?.toString() ?? user;
    } else {
      _typingUsers.remove(user);
    }
    notifyListeners();
  }

  void handleRealtimePresence(Map<String, dynamic> event) {
    if (event['group']?.toString() != groupName) return;
    final user = event['user']?.toString() ?? '';
    if (event['is_online'] == true || event['is_online'] == 1) {
      _onlineUsers.add(user);
    } else {
      _onlineUsers.remove(user);
    }
    notifyListeners();
  }

  String? get _currentUser => _details?.members.where((item) => item.isCurrentUser).map((item) => item.user).firstOrNull;

  void _listenRealtime() {
    void listen(Stream<Map<String, dynamic>>? stream, void Function(Map<String, dynamic>) handler) {
      if (stream != null) _subscriptions.add(stream.listen(handler));
    }
    if (_subscriptions.isNotEmpty) return;
    listen(_messageEvents, handleRealtimeMessage);
    listen(_deletedEvents, handleRealtimeDeleted);
    listen(_updatedEvents, handleRealtimeUpdated);
    listen(_reactionEvents, handleRealtimeReaction);
    listen(_typingEvents, handleRealtimeTyping);
    listen(_presenceEvents, handleRealtimePresence);
  }

  void _applyPage(ChatMessagePageModel page, {required bool replace}) {
    if (replace) _messages.clear();
    for (final message in page.messages) {
      if (_messages.every((item) => item.name != message.name)) {
        replace ? _messages.add(message) : _messages.insert(0, message);
      }
    }
    _sortMessages();
    _hasMore = page.hasMore;
    _nextBefore = page.nextBefore;
  }

  void _addMessage(ChatMessageModel message) {
    if (message.chatGroup != groupName || _messages.any((item) => item.name == message.name)) return;
    _messages.add(message);
    _sortMessages();
    notifyListeners();
  }

  void _replaceMessage(ChatMessageModel message) {
    final index = _messages.indexWhere((item) => item.name == message.name);
    if (index < 0) return;
    _messages[index] = message;
    notifyListeners();
  }

  void _markDeleted(String name) {
    final index = _messages.indexWhere((item) => item.name == name);
    if (index < 0) return;
    _messages[index] = _messages[index].copyWith(isDeleted: true);
    _pinnedMessages.removeWhere((item) => item.name == name);
    notifyListeners();
  }

  void _sortMessages() => _messages.sort((a, b) =>
      (a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

  Future<void> _markReadSilently() async {
    try {
      await _service.markGroupRead(groupName);
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _cleanError(Object error) => error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  @override
  void dispose() {
    _mentionTimer?.cancel();
    _typingStopTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    unawaited(_publishPresence(false));
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
