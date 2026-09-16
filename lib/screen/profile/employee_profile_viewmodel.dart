import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../model/employee_profile_model.dart';
import '../../../services/employee_profile_service.dart';

class EmployeeProfileViewModel extends ChangeNotifier {
  final EmployeeProfileService _service;

  EmployeeProfileViewModel({EmployeeProfileService? service})
      : _service = service ?? EmployeeProfileService();

  bool _loading = false;
  bool _photoLoading = false;

  String _errorMessage = '';
  EmployeeProfileModel? _profile;

  bool get loading => _loading;
  bool get photoLoading => _photoLoading;
  String get errorMessage => _errorMessage;
  EmployeeProfileModel? get profile => _profile;
  bool get hasProfile => _profile != null;

  // ------------------------------------------------------------
  // LOAD PROFILE
  // ------------------------------------------------------------

  Future<void> loadProfile() async {
    if (_loading) return;

    _loading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _profile = await _service.getEmployeeProfile();
    } catch (error) {
      _errorMessage =
          error.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE PHOTO
  // ------------------------------------------------------------

  Future<bool> updateProfilePhoto(File imageFile) async {
    if (_photoLoading) return false;

    _photoLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Upload the selected photo to ERPNext.
      await _service.updateEmployeePhoto(imageFile);

      // Load the profile again so the UI gets the
      // latest image URL stored in Employee.image.
      _profile = await _service.getEmployeeProfile();

      return true;
    } catch (error) {
      _errorMessage =
          error.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _photoLoading = false;
      notifyListeners();
    }
  }
}