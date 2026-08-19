import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../model/chat/chat_group_model.dart';
import '../../../model/chat/chat_member_model.dart';
import '../../../services/chat_service.dart';

class GroupInfoViewModel extends ChangeNotifier {
  final String groupName;
  final ChatService _service;
  Timer? _searchTimer;

  GroupInfoViewModel({required this.groupName, ChatService? service})
      : _service = service ?? ChatService();

  ChatGroupDetailsModel? _details;
  final List<ChatEmployeeModel> _available = [];
  final Map<String, bool> _pendingMembers = {};
  bool _loading = false;
  bool _saving = false;
  bool _loadingEmployees = false;
  String? _busyEmployee;
  String? _error;

  ChatGroupDetailsModel? get details => _details;
  ChatGroupModel? get group => _details?.group;
  List<ChatMemberModel> get members => List.unmodifiable(_details?.members ?? const []);
  List<ChatEmployeeModel> get availableEmployees => List.unmodifiable(_available);
  bool get loading => _loading;
  bool get saving => _saving;
  bool get loadingEmployees => _loadingEmployees;
  String? get busyEmployee => _busyEmployee;
  String? get error => _error;
  bool get canManage => group?.canManage ?? false;
  bool get isActive => group?.isActive ?? false;
  int get selectedNewCount => _pendingMembers.length;

  Future<void> initialise() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await Future.wait<dynamic>([
        _service.getChatAccess(),
        _service.getGroupDetails(groupName),
      ]);
      final access = result[0] as ChatAccessModel;
      if (!access.isChatManager) throw Exception('Only a Chat Manager can manage groups.');
      _details = result[1] as ChatGroupDetailsModel;
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
      _details = await _service.getGroupDetails(groupName);
    } catch (error) {
      _error = _cleanError(error);
    }
    notifyListeners();
  }

  Future<bool> updateDetails({required String name, String? description}) async {
    if (_saving || !canManage) return false;
    if (name.trim().isEmpty) {
      _error = 'Group name is required.';
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      _details = await _service.updateGroup(
        group: groupName,
        groupName: name.trim(),
        description: description?.trim() ?? '',
      );
      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> setActive(bool value) async {
    if (_saving || !canManage || value == isActive) return false;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      _details = await _service.updateGroup(group: groupName, isActive: value);
      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void searchAvailableEmployees(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => loadAvailableEmployees(search: value.trim()),
    );
  }

  Future<void> loadAvailableEmployees({String? search}) async {
    if (_loadingEmployees || !canManage) return;
    _loadingEmployees = true;
    _error = null;
    notifyListeners();
    try {
      final current = members.map((member) => member.employee).toSet();
      final results = await _service.getAvailableEmployees(search: search);
      _available
        ..clear()
        ..addAll(results.where((employee) => !current.contains(employee.employee)));
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _loadingEmployees = false;
      notifyListeners();
    }
  }

  bool isNewMemberSelected(String employee) => _pendingMembers.containsKey(employee);
  bool newMemberCanSend(String employee) => _pendingMembers[employee] ?? true;

  void toggleNewMember(ChatEmployeeModel employee) {
    if (_pendingMembers.containsKey(employee.employee)) {
      _pendingMembers.remove(employee.employee);
    } else {
      _pendingMembers[employee.employee] = true;
    }
    notifyListeners();
  }

  void setNewMemberCanSend(String employee, bool value) {
    if (!_pendingMembers.containsKey(employee)) return;
    _pendingMembers[employee] = value;
    notifyListeners();
  }

  Future<bool> addSelectedMembers() async {
    if (_saving || !canManage || _pendingMembers.isEmpty || !isActive) return false;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _service.addMembers(
        group: groupName,
        members: _pendingMembers.entries
            .map((entry) => ChatMemberInput(employee: entry.key, canSend: entry.value))
            .toList(growable: false),
      );
      _pendingMembers.clear();
      await refresh();
      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> updatePermission(ChatMemberModel member, bool canSend) async {
    if (_busyEmployee != null || !canManage || !isActive) return false;
    _busyEmployee = member.employee;
    _error = null;
    notifyListeners();
    try {
      await _service.updateMemberPermission(
        group: groupName,
        employee: member.employee,
        canSend: canSend,
      );
      await refresh();
      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _busyEmployee = null;
      notifyListeners();
    }
  }

  Future<bool> removeMember(ChatMemberModel member) async {
    if (_busyEmployee != null || !canManage || !isActive) return false;
    _busyEmployee = member.employee;
    _error = null;
    notifyListeners();
    try {
      await _service.removeMember(group: groupName, employee: member.employee);
      await refresh();
      return true;
    } catch (error) {
      _error = _cleanError(error);
      return false;
    } finally {
      _busyEmployee = null;
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
