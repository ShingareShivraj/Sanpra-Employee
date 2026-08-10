class LoginResponseModel {
  final bool success;
  final String message;
  final UserModel user;

  LoginResponseModel({
    required this.success,
    required this.message,
    required this.user,
  });

  factory LoginResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return LoginResponseModel(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      user: UserModel.fromJson(
        json["user"] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "user": user.toJson(),
    };
  }
}

class UserModel {
  final String email;
  final String fullName;

  final String employee;
  final String employeeName;

  final String company;
  final String department;
  final String designation;

  final String defaultShift;
  final String image;

  final String apiKey;
  final String apiSecret;
  final bool isTaskManager;

  final bool canCreateTask;

  final bool canAssignTask;

  final bool canReviewTask;
  final List<String> roles;

  UserModel({
    required this.email,
    required this.fullName,
    required this.employee,
    required this.employeeName,
    required this.company,
    required this.department,
    required this.designation,
    required this.defaultShift,
    required this.image,
    required this.apiKey,
    required this.apiSecret,
    required this.isTaskManager,
    required this.canCreateTask,
    required this.canAssignTask,
    required this.canReviewTask,
    required this.roles,
  });

  factory UserModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return UserModel(
      email: json["email"] ?? "",
      fullName: json["full_name"] ?? "",

      employee: json["employee"] ?? "",
      employeeName: json["employee_name"] ?? "",

      company: json["company"] ?? "",
      department: json["department"] ?? "",
      designation: json["designation"] ?? "",

      defaultShift: json["default_shift"] ?? "",
      image: json["image"] ?? "",

      apiKey: json["api_key"] ?? "",
      apiSecret: json["api_secret"] ?? "",
      isTaskManager: json["is_task_manager"] ?? false,

      canCreateTask: json["can_create_task"] ?? false,

      canAssignTask: json["can_assign_task"] ?? false,

      canReviewTask: json["can_review_task"] ?? false,
      roles: (json["roles"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "full_name": fullName,

      "employee": employee,
      "employee_name": employeeName,

      "company": company,
      "department": department,
      "designation": designation,

      "default_shift": defaultShift,
      "image": image,

      "api_key": apiKey,
      "api_secret": apiSecret,
      "is_task_manager": isTaskManager,

      "can_create_task": canCreateTask,

      "can_assign_task": canAssignTask,

      "can_review_task": canReviewTask,
      "roles": roles,
    };
  }
}