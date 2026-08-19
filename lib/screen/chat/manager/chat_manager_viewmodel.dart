import 'package:flutter/foundation.dart';

import '../../../model/chat/chat_group_model.dart';
import '../../../services/chat_service.dart';

class ChatManagerViewModel extends ChangeNotifier {
  final ChatService _service;

  ChatManagerViewModel({ChatService? service}) : _service = service ?? ChatService();

  final List<ChatGroupModel> _groups = [];
  ChatAccessModel? _access;
  bool _loading = false;
  bool _refreshing = false;
  String _query = '';
  String? _error;

  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;
  bool get hasAccess => _access?.isChatManager ?? false;
  int get groupCount => _groups.length;
  int get totalMembers => _groups.fold(0, (sum, group) => sum + group.memberCount);
  int get totalUnread => _groups.fold(0, (sum, group) => sum + group.unreadCount);

  List<ChatGroupModel> get groups => List.unmodifiable(_groups);

  List<ChatGroupModel> get visibleGroups {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return List.unmodifiable(_groups);
    return _groups.where((group) {
      return group.groupName.toLowerCase().contains(query) ||
          (group.description?.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  Future<void> initialise() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _access = await _service.getChatAccess();
      if (_access!.isChatManager) {
        await _loadManagedGroups();
      }
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_refreshing || !hasAccess) return;
    _refreshing = true;
    _error = null;
    notifyListeners();
    try {
      await _loadManagedGroups();
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

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _replaceGroups(List<ChatGroupModel> values) {
    _groups
      ..clear()
      ..addAll(values.where((group) => group.canManage));
    _groups.sort((a, b) {
      final left = a.activityAt ?? a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.activityAt ?? b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
  }

  Future<void> _loadManagedGroups() async {
    final summaries = (await _service.getMyGroups())
        .where((group) => group.canManage)
        .toList(growable: false);
    final enriched = await Future.wait(
      summaries.map((summary) async {
        try {
          final details = await _service.getGroupDetails(summary.name);
          return details.group.copyWith(
            unreadCount: summary.unreadCount,
            lastMessage: summary.lastMessage,
            lastMessageSender: summary.lastMessageSender,
            lastMessageAt: summary.lastMessageAt,
            activityAt: summary.activityAt,
            members: details.members,
          );
        } catch (_) {
          return summary;
        }
      }),
    );
    _replaceGroups(enriched);
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
