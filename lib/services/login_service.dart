import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../model/login_response.dart';
import 'api_endpoints.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'secure_storage_service.dart';
import 'device_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<LoginResponseModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final String androidId =
      await DeviceService.instance.getAndroidId();

      print("Android ID : $androidId");

      final Response response = await _api.post(
        url: ApiEndpoints.login,
        data: {
          "usr": username,
          "pwd": password,
          "android_id": androidId,
        },
      );

      print("Login Response : ${response.data}");

      final LoginResponseModel loginResponse =
      LoginResponseModel.fromJson(
        response.data["message"] ?? response.data,
      );

      if (loginResponse.success) {
        await SecureStorageService.instance.saveLogin(
          apiKeyValue: loginResponse.user.apiKey,
          apiSecretValue: loginResponse.user.apiSecret,
          emailValue: loginResponse.user.email,
          fullNameValue: loginResponse.user.fullName,
          employeeIdValue: loginResponse.user.employee,
          employeeNameValue: loginResponse.user.employeeName,
          companyValue: loginResponse.user.company,
          departmentValue: loginResponse.user.department,
          designationValue: loginResponse.user.designation,
          isTaskManagerValue: loginResponse.user.isTaskManager,
          canCreateTaskValue: loginResponse.user.canCreateTask,
          canAssignTaskValue: loginResponse.user.canAssignTask,
          canReviewTaskValue: loginResponse.user.canReviewTask,
          rolesValue: loginResponse.user.roles,
        );
        print("API isTaskManager = ${loginResponse.user.isTaskManager}");

        print(await SecureStorageService.instance.getIsTaskManager());

        print(await SecureStorageService.instance.getCanCreateTask());

        print(await SecureStorageService.instance.getCanAssignTask());

        print(await SecureStorageService.instance.getCanReviewTask());

        String? token = await NotificationService.instance.getToken();

        print("FCM Token : $token");


      }

      return loginResponse;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["message"] ??
            e.message ??
            "Unable to connect to server.",
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==========================================================
// FORGOT PASSWORD
// ==========================================================

  Future<void> forgotPassword({
    required String username,
  }) async {
    try {
      final Response response = await _api.post(
        url: ApiEndpoints.forgotPassword,
        requiresAuth: false,
        data: {
          "user": username.trim(),
        },
      );

      print("Forgot Password Response : ${response.data}");
    } on DioException catch (e) {
      final responseData = e.response?.data;

      String message = "Unable to process password reset request.";

      if (responseData is Map<String, dynamic>) {
        message =
            responseData["message"]?.toString() ??
                responseData["_server_messages"]?.toString() ??
                e.message ??
                message;
      } else if (e.message != null) {
        message = e.message!;
      }

      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> logout() async {
    await SecureStorageService.instance.logout();
  }

  // ==========================================================
  // LOGIN STATUS
  // ==========================================================

  Future<bool> isLoggedIn() async {
    return await SecureStorageService.instance.isLoggedIn();
  }

  // ==========================================================
  // STORED USER DETAILS
  // ==========================================================

  Future<String?> getEmployeeId() async {
    return await SecureStorageService.instance.getEmployeeId();
  }

  Future<String?> getEmployeeName() async {
    return await SecureStorageService.instance.getEmployeeName();
  }

  Future<String?> getCompany() async {
    return await SecureStorageService.instance.getCompany();
  }

  Future<String?> getDepartment() async {
    return await SecureStorageService.instance.getDepartment();
  }

  Future<String?> getDesignation() async {
    return await SecureStorageService.instance.getDesignation();
  }

  Future<String?> getFullName() async {
    return await SecureStorageService.instance.getFullName();
  }

  Future<String?> getEmail() async {
    return await SecureStorageService.instance.getEmail();
  }
  Future<bool> getIsTaskManager() {
    return SecureStorageService.instance.getIsTaskManager();
  }

  Future<bool> getCanCreateTask() {
    return SecureStorageService.instance.getCanCreateTask();
  }

  Future<bool> getCanAssignTask() {
    return SecureStorageService.instance.getCanAssignTask();
  }

  Future<bool> getCanReviewTask() {
    return SecureStorageService.instance.getCanReviewTask();
  }
  Future<List<String>> getRoles() {
    return SecureStorageService.instance.getRoles();
  }

  Future<bool> hasRole(String role) async {
    final roles = await getRoles();
    return roles.contains(role);
  }
}