import 'package:dio/dio.dart';

import '../model/employee_profile_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class EmployeeProfileService {
  final ApiService _api;
  EmployeeProfileService({ApiService? api}) : _api = api ?? ApiService();

  Future<EmployeeProfileModel> getEmployeeProfile() async {
    try {
      final response = await _api.get(url: ApiEndpoints.employeeProfile);
      final root = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final message = root['message'] is Map
          ? Map<String, dynamic>.from(root['message'] as Map)
          : root;
      final result = EmployeeProfileResponseModel.fromJson(message);
      if (!result.success || result.profile == null) {
        throw Exception(result.message.isEmpty
            ? 'Unable to load employee profile.'
            : result.message);
      }
      return result.profile!;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error));
    }
  }

  String _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final serverMessage = data['message'];
      if (serverMessage is Map && serverMessage['message'] != null) {
        return serverMessage['message'].toString();
      }
      final value = data['_server_messages'] ?? data['exception'] ?? serverMessage;
      if (value != null) return value.toString();
    }
    return error.message ?? 'Unable to load employee profile.';
  }
}
