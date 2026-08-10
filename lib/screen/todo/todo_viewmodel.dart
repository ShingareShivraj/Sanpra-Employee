import 'package:flutter/foundation.dart';
import '../../model/todo_model.dart';
import '../../services/todo_service.dart';

class TodoViewModel extends ChangeNotifier {
  final TodoService _service;
  TodoViewModel({TodoService? service}) : _service = service ?? TodoService();
  bool _loading = false;
  String _errorMessage = '';
  String? _completingTodo;
  EmployeeTodosResponseModel? _response;

  bool get loading => _loading;
  String get errorMessage => _errorMessage;
  List<TodoModel> get overdue => _response?.overdue ?? const [];
  List<TodoModel> get today => _response?.today ?? const [];
  List<TodoModel> get upcoming => _response?.upcoming ?? const [];
  List<TodoModel> get completed => _response?.completed ?? const [];
  int get openCount => overdue.length + today.length + upcoming.length;
  bool get hasTodos => openCount > 0;
  bool isCompleting(String name) => _completingTodo == name;

  Future<void> loadTodos() async {
    _loading = true; _errorMessage = ''; notifyListeners();
    try { _response = await _service.getEmployeeTodos(); }
    catch (e) { _errorMessage = e.toString().replaceFirst('Exception: ', ''); }
    finally { _loading = false; notifyListeners(); }
  }

  Future<bool> completeTodo(String name) async {
    if (_completingTodo != null) return false;
    _completingTodo = name; _errorMessage = ''; notifyListeners();
    try { await _service.completeTodo(name); await loadTodos(); return true; }
    catch (e) { _errorMessage = e.toString().replaceFirst('Exception: ', ''); return false; }
    finally { _completingTodo = null; notifyListeners(); }
  }
}
