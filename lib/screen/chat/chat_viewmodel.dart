import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/chat/chat_group_model.dart';
import '../../services/chat_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _service;
  final Stream<Map<String, dynamic>>? _messageEvents;
  final Stream<Map<String, dynamic>>? _updatedMessageEvents;
  final Stream<Map<String, dynamic>>? _deletedMessageEvents;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _updatedMessageSubscription;
  StreamSubscription<Map<String, dynamic>>? _deletedMessageSubscription;

  ChatViewModel({
    ChatService? service,
    Stream<Map<String, dynamic>>? messageEvents,
    Stream<Map<String, dynamic>>? updatedMessageEvents,
    Stream<Map<String, dynamic>>? deletedMessageEvents,
  })  : _service = service ?? ChatService(),
        _messageEvents = messageEvents,
        _updatedMessageEvents = updatedMessageEvents,
        _deletedMessageEvents = deletedMessageEvents;

  final List<ChatGroupModel> _groups = [];
  String _query = '';
  bool _loading = false;
  bool _refreshing = false;
  String? _error;
  ChatAccessModel? _access;

  List<ChatGroupModel> get groups => List.unmodifiable(_groups);
  ChatAccessModel? get access => _access;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;
  bool get isChatManager => _access?.isChatManager ?? false;
  int get totalUnread => _groups.fold(0, (sum, group) => sum + group.unreadCount);

  List<ChatGroupModel> get visibleGroups {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return List.unmodifiable(_groups);
    return _groups.where((group) {
      return group.groupName.toLowerCase().contains(query) ||
          (group.description?.toLowerCase().contains(query) ?? false) ||
          (group.lastMessage?.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  Future<void> initialise() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _service.getChatAccess(),
        _service.getMyGroups(),
      ]);
      _access = results[0] as ChatAccessModel;
      _replaceGroups(results[1] as List<ChatGroupModel>);
      _listenRealtime();
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    notifyListeners();
    try {
      _replaceGroups(await _service.getMyGroups());
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  void search(String value) {
    _query = value;
    notifyListeners();
  }

  void clearSearch() {
    if (_query.isEmpty) return;
    _query = '';
    notifyListeners();
  }

  void markLocallyRead(String groupName) {
    final index = _groups.indexWhere((group) => group.name == groupName);
    if (index < 0 || _groups[index].unreadCount == 0) return;
    _groups[index] = _groups[index].copyWith(unreadCount: 0);
    notifyListeners();
  }

  void _replaceGroups(List<ChatGroupModel> values) {
    _groups
      ..clear()
      ..addAll(values);
    _sortGroups();
  }

  void _listenRealtime() {
    _messageSubscription ??= _messageEvents?.listen(handleRealtimeMessage);
    _updatedMessageSubscription ??=
        _updatedMessageEvents?.listen(handleRealtimeMessageChanged);
    _deletedMessageSubscription ??=
        _deletedMessageEvents?.listen(handleRealtimeMessageChanged);
  }

  void handleRealtimeMessageChanged(Map<String, dynamic> event) {
    final groupName = event['group']?.toString() ?? '';
    if (groupName.isEmpty ||
        !_groups.any((group) => group.name == groupName)) {
      return;
    }
    unawaited(_refreshFromRealtime());
  }

  Future<void> _refreshFromRealtime() async {
    try {
      _replaceGroups(await _service.getMyGroups());
      notifyListeners();
    } catch (error) {
      _error = _cleanError(error);
      notifyListeners();
    }
  }

  void handleRealtimeMessage(Map<String, dynamic> event) {
    final groupName = event['group']?.toString() ?? '';
    final rawMessage = event['message'];
    if (groupName.isEmpty || rawMessage is! Map) return;
    final message = Map<String, dynamic>.from(rawMessage);
    final index = _groups.indexWhere((group) => group.name == groupName);
    if (index < 0) {
      unawaited(refresh());
      return;
    }
    final group = _groups[index];
    final sentAt = _parseDate(message['sent_at']) ?? DateTime.now();
    final isMine = message['sender']?.toString() == _access?.user;
    final preview = message['message_type']?.toString() == 'Text'
        ? message['message']?.toString()
        : '${message['message_type'] ?? 'File'} attachment';
    _groups[index] = group.copyWith(
      lastMessage: preview,
      lastMessageSender: message['sender']?.toString(),
      lastMessageAt: sentAt,
      activityAt: sentAt,
      unreadCount: isMine ? group.unreadCount : group.unreadCount + 1,
    );
    _sortGroups();
    notifyListeners();
  }

  void _sortGroups() {
    _groups.sort((a, b) {
      final left = a.activityAt ?? a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.activityAt ?? b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
  }

  DateTime? _parseDate(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _updatedMessageSubscription?.cancel();
    _deletedMessageSubscription?.cancel();
    super.dispose();
  }
}
