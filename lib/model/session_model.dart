class SessionModel {
  final String email;
  final String fullName;

  final String employeeId;
  final String employeeName;

  final String company;
  final String department;
  final String designation;

  final List<String> roles;

  final bool isTaskManager;
  final bool isSystemManager;

  final bool canCreateTask;
  final bool canAssignTask;
  final bool canReviewTask;

  const SessionModel({
    required this.email,
    required this.fullName,
    required this.employeeId,
    required this.employeeName,
    required this.company,
    required this.department,
    required this.designation,
    required this.roles,
    required this.isTaskManager,
    required this.isSystemManager,
    required this.canCreateTask,
    required this.canAssignTask,
    required this.canReviewTask,
  });
}