import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance =
  SecureStorageService._();

  final FlutterSecureStorage _storage =
  const FlutterSecureStorage();

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String apiKey = "api_key";
  static const String apiSecret = "api_secret";

  static const String email = "email";
  static const String fullName = "full_name";

  static const String employeeId = "employee_id";
  static const String employeeName = "employee_name";

  static const String company = "company";
  static const String department = "department";
  static const String designation = "designation";
  static const String isTaskManager = "is_task_manager";

  static const String canCreateTask = "can_create_task";

  static const String canAssignTask = "can_assign_task";

  static const String canReviewTask = "can_review_task";
  static const _roles = "roles";

  // ============================================================
  // SAVE LOGIN
  // ============================================================

  Future<void> saveLogin({
    required String apiKeyValue,
    required String apiSecretValue,
    required String emailValue,
    required String fullNameValue,
    required String employeeIdValue,
    required String employeeNameValue,
    required String companyValue,
    required String departmentValue,
    required String designationValue,
    required bool isTaskManagerValue,
    required bool canCreateTaskValue,
    required bool canAssignTaskValue,
    required bool canReviewTaskValue,
    required List<String> rolesValue,
  }) async {
    await _storage.write(
      key: apiKey,
      value: apiKeyValue,
    );

    await _storage.write(
      key: apiSecret,
      value: apiSecretValue,
    );

    await _storage.write(
      key: email,
      value: emailValue,
    );

    await _storage.write(
      key: fullName,
      value: fullNameValue,
    );

    await _storage.write(
      key: employeeId,
      value: employeeIdValue,
    );

    await _storage.write(
      key: employeeName,
      value: employeeNameValue,
    );

    await _storage.write(
      key: company,
      value: companyValue,
    );

    await _storage.write(
      key: department,
      value: departmentValue,
    );

    await _storage.write(
      key: designation,
      value: designationValue,
    );
    await _storage.write(
      key: isTaskManager,
      value: isTaskManagerValue.toString(),
    );

    await _storage.write(
      key: canCreateTask,
      value: canCreateTaskValue.toString(),
    );

    await _storage.write(
      key: canAssignTask,
      value: canAssignTaskValue.toString(),
    );

    await _storage.write(
      key: canReviewTask,
      value: canReviewTaskValue.toString(),
    );
    await _storage.write(
      key: _roles,
      value: jsonEncode(rolesValue),
    );
  }

  // ============================================================
  // GET VALUES
  // ============================================================

  Future<String?> getApiKey() =>
      _storage.read(key: apiKey);

  Future<String?> getApiSecret() =>
      _storage.read(key: apiSecret);

  Future<String?> getEmail() =>
      _storage.read(key: email);

  Future<String?> getFullName() =>
      _storage.read(key: fullName);

  Future<String?> getEmployeeId() =>
      _storage.read(key: employeeId);

  Future<String?> getEmployeeName() =>
      _storage.read(key: employeeName);

  Future<String?> getCompany() =>
      _storage.read(key: company);

  Future<String?> getDepartment() =>
      _storage.read(key: department);

  Future<String?> getDesignation() =>
      _storage.read(key: designation);
  Future<bool> getIsTaskManager() async =>
      (await _storage.read(key: isTaskManager)) == "true";

  Future<bool> getCanCreateTask() async =>
      (await _storage.read(key: canCreateTask)) == "true";

  Future<bool> getCanAssignTask() async =>
      (await _storage.read(key: canAssignTask)) == "true";

  Future<bool> getCanReviewTask() async =>
      (await _storage.read(key: canReviewTask)) == "true";

  Future<List<String>> getRoles() async {
    final value = await _storage.read(key: _roles);

    if (value == null || value.isEmpty) {
      return [];
    }

    return (jsonDecode(value) as List)
        .map((e) => e.toString())
        .toList();
  }

  // ============================================================
  // LOGIN STATUS
  // ============================================================

  Future<bool> isLoggedIn() async {
    final key = await getApiKey();
    final secret = await getApiSecret();

    return key != null &&
        key.isNotEmpty &&
        secret != null &&
        secret.isNotEmpty;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}