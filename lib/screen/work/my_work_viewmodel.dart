import 'package:flutter/foundation.dart';

import '../../model/my_work_model.dart';
import '../../services/my_work_service.dart';

class MyWorkViewModel extends ChangeNotifier {
  MyWorkViewModel({MyWorkService? service})
      : _service = service ?? MyWorkService();

  final MyWorkService _service;

  MyWorkResponseModel? _response;
  MyWorkSection _selectedSection = MyWorkSection.today;
  bool _loading = false;
  bool _refreshing = false;
  String? _completingTodo;
  String? _errorMessage;
  bool _disposed = false;

  MyWorkResponseModel? get response => _response;
  MyWorkSection get selectedSection => _selectedSection;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get completingTodo => _completingTodo;
  String? get errorMessage => _errorMessage;

  MyWorkCountsModel get counts =>
      _response?.counts ?? const MyWorkCountsModel();

  List<MyWorkItemModel> get overdue => _response?.overdue ?? const [];
  List<MyWorkItemModel> get today => _response?.today ?? const [];
  List<MyWorkItemModel> get upcoming => _response?.upcoming ?? const [];
  List<MyWorkItemModel> get pendingReview =>
      _response?.pendingReview ?? const [];
  List<MyWorkItemModel> get completed => _response?.completed ?? const [];

  List<MyWorkItemModel> get selectedItems =>
      _response?.itemsFor(_selectedSection) ?? const [];

  bool get hasOpenWork => _response?.hasOpenWork ?? false;
  bool get hasAnyWork => _response?.hasAnyWork ?? false;
  int get openCount => _response?.openCount ?? counts.open;
  int get totalCount => counts.total;
  bool isCompleting(String? todoName) =>
      todoName != null && _completingTodo == todoName;

  int countFor(MyWorkSection section) {
    switch (section) {
      case MyWorkSection.overdue:
        return counts.overdue;
      case MyWorkSection.today:
        return counts.today;
      case MyWorkSection.upcoming:
        return counts.upcoming;
      case MyWorkSection.pendingReview:
        return counts.pendingReview;
      case MyWorkSection.completed:
        return counts.completed;
    }
  }

  void selectSection(MyWorkSection section) {
    if (_selectedSection == section) return;
    _selectedSection = section;
    _notify();
  }

  Future<void> load({bool force = false}) async {
    if (_loading || _refreshing) return;
    if (!force && _response != null) return;
    _loading = true;
    _errorMessage = null;
    _notify();
    try {
      _response = await _service.getMyWork();
      _selectUsefulSection();
    } catch (error) {
      _errorMessage = _cleanError(error);
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    if (_loading || _refreshing || _completingTodo != null) return;
    _refreshing = true;
    _errorMessage = null;
    _notify();
    try {
      _response = await _service.getMyWork();
      _selectUsefulSection(onlyWhenEmpty: true);
    } catch (error) {
      _errorMessage = _cleanError(error);
    } finally {
      _refreshing = false;
      _notify();
    }
  }

  Future<bool> completeTodo(MyWorkItemModel item) async {
    final todoName = item.todoName;
    if (_completingTodo != null) return false;
    if (!item.isTodo || !item.canCompleteDirectly || todoName == null) {
      _errorMessage =
          'This work item must be completed through its own workflow.';
      _notify();
      return false;
    }

    _completingTodo = todoName;
    _errorMessage = null;
    _notify();
    try {
      await _service.completeWorkItem(item);
      _response = await _service.getMyWork();
      _selectUsefulSection(onlyWhenEmpty: true);
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      return false;
    } finally {
      _completingTodo = null;
      _notify();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notify();
  }

  void _selectUsefulSection({bool onlyWhenEmpty = false}) {
    if (_response == null) return;
    if (onlyWhenEmpty && selectedItems.isNotEmpty) return;

    const preference = [
      MyWorkSection.today,
      MyWorkSection.overdue,
      MyWorkSection.pendingReview,
      MyWorkSection.upcoming,
      MyWorkSection.completed,
    ];
    for (final section in preference) {
      if (_response!.itemsFor(section).isNotEmpty) {
        _selectedSection = section;
        return;
      }
    }
    _selectedSection = MyWorkSection.today;
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

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '').trim();
}
