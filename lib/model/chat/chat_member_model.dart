class ChatMemberModel {
  final String employee;
  final String employeeName;
  final String user;
  final bool canSend;
  final bool isCurrentUser;

  const ChatMemberModel({
    required this.employee,
    required this.employeeName,
    required this.user,
    required this.canSend,
    required this.isCurrentUser,
  });

  factory ChatMemberModel.fromJson(Map<String, dynamic> json) {
    return ChatMemberModel(
      employee: _string(json['employee']),
      employeeName: _string(json['employee_name'], fallback: _string(json['employee'])),
      user: _string(json['user']),
      canSend: _bool(json['can_send']),
      isCurrentUser: _bool(json['is_current_user']),
    );
  }

  ChatMemberModel copyWith({bool? canSend}) => ChatMemberModel(
        employee: employee,
        employeeName: employeeName,
        user: user,
        canSend: canSend ?? this.canSend,
        isCurrentUser: isCurrentUser,
      );

  static String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return {'1', 'true', 'yes', 'on'}.contains(value?.toString().toLowerCase());
  }
}

class ChatEmployeeModel {
  final String employee;
  final String employeeName;
  final String user;
  final String? designation;
  final String? department;
  final String? company;

  const ChatEmployeeModel({
    required this.employee,
    required this.employeeName,
    required this.user,
    this.designation,
    this.department,
    this.company,
  });

  factory ChatEmployeeModel.fromJson(Map<String, dynamic> json) {
    String? optional(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    final employee = json['name']?.toString() ?? json['employee']?.toString() ?? '';
    return ChatEmployeeModel(
      employee: employee,
      employeeName: optional(json['employee_name']) ?? employee,
      user: optional(json['user_id']) ?? optional(json['user']) ?? '',
      designation: optional(json['designation']),
      department: optional(json['department']),
      company: optional(json['company']),
    );
  }
}
