import 'package:flutter/foundation.dart';

import '../../../model/employee_profile_model.dart';
import '../../../services/employee_profile_service.dart';

class EmployeeProfileViewModel extends ChangeNotifier {
  final EmployeeProfileService _service;
  EmployeeProfileViewModel({EmployeeProfileService? service})
      : _service = service ?? EmployeeProfileService();

  bool _loading = false;
  String _errorMessage = '';
  EmployeeProfileModel? _profile;

  bool get loading => _loading;
  String get errorMessage => _errorMessage;
  EmployeeProfileModel? get profile => _profile;
  bool get hasProfile => _profile != null;

  Future<void> loadProfile() async {
    if (_loading) return;
    _loading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      _profile = await _service.getEmployeeProfile();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
