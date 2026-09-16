import 'dart:io';

import 'package:dio/dio.dart';

import '../model/employee_profile_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class EmployeeProfileService {
  final ApiService _api;

  EmployeeProfileService({ApiService? api}) : _api = api ?? ApiService();

  // ------------------------------------------------------------
  // GET EMPLOYEE PROFILE
  // ------------------------------------------------------------

  Future<EmployeeProfileModel> getEmployeeProfile() async {
    try {
      final response = await _api.get(
        url: ApiEndpoints.employeeProfile,
      );

      final root = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      final message = root['message'] is Map
          ? Map<String, dynamic>.from(root['message'] as Map)
          : root;

      final result = EmployeeProfileResponseModel.fromJson(message);

      if (!result.success || result.profile == null) {
        throw Exception(
          result.message.isEmpty
              ? 'Unable to load employee profile.'
              : result.message,
        );
      }

      return result.profile!;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error));
    }
  }

  // ------------------------------------------------------------
  // UPDATE EMPLOYEE PROFILE PHOTO
  // ------------------------------------------------------------

  Future<String> updateEmployeePhoto(File imageFile) async {
    try {
      final fileName = imageFile.uri.pathSegments.isNotEmpty
          ? imageFile.uri.pathSegments.last
          : 'profile_photo.jpg';

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _api.postMultipart(
        url: ApiEndpoints.updateEmployeePhoto,
        data: formData,
      );

      final root = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      final message = root['message'] is Map
          ? Map<String, dynamic>.from(root['message'] as Map)
          : root;

      if (message['success'] != true) {
        throw Exception(
          message['message']?.toString() ??
              'Unable to update profile photo.',
        );
      }

      return message['image']?.toString() ?? '';
    } on DioException catch (error) {
      throw Exception(_dioMessage(error));
    }
  }

  // ------------------------------------------------------------
  // DIO ERROR MESSAGE
  // ------------------------------------------------------------

  String _dioMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final serverMessage = data['message'];

      if (serverMessage is Map && serverMessage['message'] != null) {
        return serverMessage['message'].toString();
      }

      final value =
          data['_server_messages'] ??
              data['exception'] ??
              serverMessage;

      if (value != null) {
        return value.toString();
      }
    }

    return error.message ?? 'Unable to load employee profile.';
  }
}