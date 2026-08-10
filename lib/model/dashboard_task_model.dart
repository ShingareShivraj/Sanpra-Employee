import 'task_model.dart';

class DashboardTaskModel {
  final bool success;
  final String message;
  final String? employeeName;
  final TaskCountsModel counts;
  final int taskCount;
  final List<TaskModel> tasks;

  const DashboardTaskModel({
    required this.success,
    this.message = '',
    this.employeeName,
    this.counts = const TaskCountsModel(),
    this.taskCount = 0,
    this.tasks = const [],
  });

  factory DashboardTaskModel.fromJson(Map<String, dynamic> json) {
    final data = unwrapFrappeResponse(json);
    final rows = data['tasks'];
    final tasks = rows is List
        ? rows
            .whereType<Map>()
            .map((row) => TaskModel.fromJson(Map<String, dynamic>.from(row)))
            .toList()
        : <TaskModel>[];

    return DashboardTaskModel(
      success: _bool(data['success']),
      message: data['message']?.toString() ?? '',
      employeeName: _nullable(data['employee_name']),
      counts: TaskCountsModel.fromJson(_map(data['counts'])),
      taskCount: _int(data['task_count'], fallback: tasks.length),
      tasks: tasks,
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
String? _nullable(dynamic value) =>
    value == null || value.toString().trim().isEmpty ? null : value.toString();
bool _bool(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';
int _int(dynamic value, {int fallback = 0}) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
