import 'package:flutter/foundation.dart';

import '../../model/actions_needed_model.dart';
import '../../model/chat/chat_group_model.dart';
import '../../services/actions_needed_service.dart';
import '../../services/chat_service.dart';

class ActionsNeededViewModel extends ChangeNotifier {
  final ActionsNeededService _service;
  final ChatService _chatService;

  ActionsNeededViewModel({
    ActionsNeededService? service,
    ChatService? chatService,
  })  : _service = service ?? ActionsNeededService(),
        _chatService = chatService ?? ChatService();

  ActionsNeededResponseModel? _response;
  bool _loading = false;
  bool _refreshing = false;
  String? _error;
  bool _disposed = false;

  ActionsNeededResponseModel? get response => _response;
  List<ActionNeededItemModel> get actions => _response?.actions ?? const [];
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get hasLoaded => _response != null;
  bool get isEmpty => hasLoaded && actions.isEmpty;
  String? get error => _error;
  int get total => _response?.total ?? actions.length;
  DateTime? get generatedAt => _response?.generatedAt;

  List<ActionNeededCategory> get visibleCategories {
    final categories = groupedActions.keys.toList()
      ..sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
    return categories;
  }

  Map<ActionNeededCategory, List<ActionNeededItemModel>> get groupedActions {
    return _response?.groupedActions ?? const {};
  }

  int countFor(ActionNeededCategory category) {
    return groupedActions[category]?.length ?? 0;
  }

  Future<void> initialise() async {
    if (_loading || hasLoaded) return;
    await _load(showFullLoader: true);
  }

  Future<void> retry() => _load(showFullLoader: true);

  /// Called only by a user-initiated pull-to-refresh.
  Future<void> refresh() => _load(showFullLoader: false);

  Future<void> _load({required bool showFullLoader}) async {
    if (_loading || _refreshing) return;
    if (showFullLoader) {
      _loading = true;
    } else {
      _refreshing = true;
    }
    _error = null;
    _notify();

    try {
      _response = await _service.getActionsNeeded();
    } on ActionsNeededServiceException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Unable to load actions. Please try again.';
    } finally {
      _loading = false;
      _refreshing = false;
      _notify();
    }
  }

  /// Chat requires the complete group model before opening the existing
  /// conversation screen. This request happens only after the employee taps a
  /// Chat action; it is not part of loading or polling Actions Needed.
  Future<ChatGroupModel> loadChatGroup(String groupName) async {
    final name = groupName.trim();
    if (name.isEmpty) throw Exception('Chat group is required.');
    final details = await _chatService.getGroupDetails(name);
    return details.group;
  }

  /// The conversation screen updates last_read_at when opened. Remove only
  /// that conversation from the current in-memory list after returning, so no
  /// automatic Actions Needed API call is introduced.
  void removeReadChatAction(String actionId) {
    final current = _response;
    if (current == null) return;
    final updated = current.actions
        .where((action) => action.id != actionId)
        .toList(growable: false);
    if (updated.length == current.actions.length) return;
    _response = ActionsNeededResponseModel(
      success: current.success,
      total: current.total > 0 ? current.total - 1 : 0,
      returned: updated.length,
      hasMore: current.hasMore,
      generatedAt: current.generatedAt,
      actions: updated,
    );
    _notify();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
