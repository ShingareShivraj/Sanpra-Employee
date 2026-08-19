import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../model/chat/chat_group_model.dart';
import '../../../model/chat/chat_member_model.dart';
import '../../../services/chat_service.dart';

class CreateGroupViewModel extends ChangeNotifier {
  final ChatService _service;
  Timer? _searchTimer;

  CreateGroupViewModel({ChatService? service}) : _service = service ?? ChatService();

  final List<ChatEmployeeModel> _employees = [];
  final Map<String, bool> _selected = {};
  bool _loading = false;
  bool _searching = false;
  bool _creating = false;
  String _searchQuery = '';
  String? _error;

  List<ChatEmployeeModel> get employees => List.unmodifiable(_employees);
  bool get loading => _loading;
  bool get searching => _searching;
  bool get creating => _creating;
  String? get error => _error;
  int get selectedCount => _selected.length;
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> initialise() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final access = await _service.getChatAccess();
      if (!access.isChatManager) throw Exception('Only a Chat Manager can create groups.');
      _employees
        ..clear()
        ..addAll(await _service.getAvailableEmployees());
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void searchEmployees(String value) {
    _searchQuery = value.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    _searching = true;
    _error = null;
    notifyListeners();
    try {
      final results = await _service.getAvailableEmployees(search: _searchQuery);
      _employees
        ..clear()
        ..addAll(results);
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  bool isSelected(String employee) => _selected.containsKey(employee);
  bool canSend(String employee) => _selected[employee] ?? true;

  void toggleEmployee(ChatEmployeeModel employee) {
    if (_selected.containsKey(employee.employee)) {
      _selected.remove(employee.employee);
    } else {
      _selected[employee.employee] = true;
    }
    notifyListeners();
  }

  void setCanSend(String employee, bool value) {
    if (!_selected.containsKey(employee)) return;
    _selected[employee] = value;
    notifyListeners();
  }

  void selectAllVisible() {
    for (final employee in _employees) {
      _selected.putIfAbsent(employee.employee, () => true);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }

  Future<ChatGroupDetailsModel?> create({
    required String groupName,
    String? description,
  }) async {
    if (_creating) return null;
    if (groupName.trim().isEmpty) {
      _error = 'Group name is required.';
      notifyListeners();
      return null;
    }
    if (_selected.isEmpty) {
      _error = 'Select at least one employee.';
      notifyListeners();
      return null;
    }
    _creating = true;
    _error = null;
    notifyListeners();
    try {
      return await _service.createGroup(
        groupName: groupName.trim(),
        description: description?.trim(),
        members: _selected.entries
            .map((entry) => ChatMemberInput(employee: entry.key, canSend: entry.value))
            .toList(growable: false),
      );
    } catch (error) {
      _error = _cleanError(error);
      return null;
    } finally {
      _creating = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
