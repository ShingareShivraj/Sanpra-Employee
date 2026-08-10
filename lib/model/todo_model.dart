class TodoModel {
  final String name;
  final String description;
  final String status;
  final DateTime? dueDate;
  final String priority;
  final String referenceType;
  final String referenceName;
  final DateTime? completedOn;

  const TodoModel({required this.name, required this.description,
    required this.status, required this.dueDate, required this.priority,
    required this.referenceType, required this.referenceName,
    this.completedOn});

  factory TodoModel.fromJson(Map<String, dynamic> json) => TodoModel(
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? 'Untitled ToDo',
    status: json['status']?.toString() ?? 'Open',
    dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
    priority: json['priority']?.toString() ?? 'Medium',
    referenceType: json['reference_type']?.toString() ?? '',
    referenceName: json['reference_name']?.toString() ?? '',
    completedOn: DateTime.tryParse(json['completed_on']?.toString() ?? ''),
  );
}

class EmployeeTodosResponseModel {
  final bool success;
  final String message;
  final List<TodoModel> overdue;
  final List<TodoModel> today;
  final List<TodoModel> upcoming;
  final List<TodoModel> completed;

  const EmployeeTodosResponseModel({required this.success, required this.message,
    required this.overdue, required this.today, required this.upcoming,
    required this.completed});

  factory EmployeeTodosResponseModel.fromJson(Map<String, dynamic> json) {
    List<TodoModel> list(String key) => (json[key] as List? ?? const [])
        .whereType<Map>().map((e) => TodoModel.fromJson(
        Map<String, dynamic>.from(e))).toList(growable: false);
    return EmployeeTodosResponseModel(success: json['success'] == true,
        message: json['message']?.toString() ?? '', overdue: list('overdue'),
        today: list('today'), upcoming: list('upcoming'),
        completed: list('completed'));
  }
}

class DashboardTodosResponseModel {
  final bool success;
  final String message;
  final int todoCount;
  final List<TodoModel> todos;
  const DashboardTodosResponseModel({required this.success,
    required this.message, required this.todoCount, required this.todos});
  factory DashboardTodosResponseModel.fromJson(Map<String, dynamic> json) {
    final todos = (json['todos'] as List? ?? const []).whereType<Map>()
        .map((e) => TodoModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
    return DashboardTodosResponseModel(success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        todoCount: int.tryParse(json['todo_count']?.toString() ?? '') ?? todos.length,
        todos: todos);
  }
}
