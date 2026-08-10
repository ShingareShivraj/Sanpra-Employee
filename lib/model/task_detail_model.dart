import 'task_model.dart';

class TaskDetailModel {
  final bool success;
  final String message;
  final String accessType;
  final bool canManage;
  final bool canStart;
  final bool canSubmitCompletion;
  final bool canReview;
  final TaskModel? task;

  const TaskDetailModel({
    required this.success,
    this.message = '',
    this.accessType = '',
    this.canManage = false,
    this.canStart = false,
    this.canSubmitCompletion = false,
    this.canReview = false,
    this.task,
  });

  factory TaskDetailModel.fromJson(Map<String, dynamic> json) {
    final data = unwrapFrappeResponse(json);
    final taskJson = data['task'];

    return TaskDetailModel(
      success: _bool(data['success']),
      message: data['message']?.toString() ?? '',
      accessType: data['access_type']?.toString() ?? '',
      canManage: _bool(data['can_manage']),
      canStart: _bool(data['can_start']),
      canSubmitCompletion: _bool(data['can_submit_completion']),
      canReview: _bool(data['can_review']),
      task: taskJson is Map
          ? TaskModel.fromJson(Map<String, dynamic>.from(taskJson))
          : null,
    );
  }
}

bool _bool(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';
