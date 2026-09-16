class KnowledgeResourceMemberModel {
  final String employee;
  final String employeeName;
  final String role;

  const KnowledgeResourceMemberModel({
    required this.employee,
    required this.employeeName,
    required this.role,
  });

  factory KnowledgeResourceMemberModel.fromJson(Map<String, dynamic> json) {
    final employee = _string(json['employee']);
    return KnowledgeResourceMemberModel(
      employee: employee,
      employeeName: _string(json['employee_name'], fallback: employee),
      role: _string(json['role']),
    );
  }

  /// Payload expected by create/update_knowledge_resource.
  Map<String, dynamic> toJson() => {
        'employee': employee,
        'role': role,
      };

  KnowledgeResourceMemberModel copyWith({
    String? employee,
    String? employeeName,
    String? role,
  }) {
    return KnowledgeResourceMemberModel(
      employee: employee ?? this.employee,
      employeeName: employeeName ?? this.employeeName,
      role: role ?? this.role,
    );
  }
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

