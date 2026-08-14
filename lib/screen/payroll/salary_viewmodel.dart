import 'package:flutter/foundation.dart';

import '../../model/salary_model.dart';
import '../../services/payroll_service.dart';

class SalaryViewModel extends ChangeNotifier {
  SalaryViewModel({PayrollService? service})
      : _service = service ?? PayrollService();

  final PayrollService _service;
  SalaryModel? salary;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadSalary({bool refresh = false}) async {
    if (isLoading) return;
    isLoading = true;
    if (refresh) errorMessage = null;
    notifyListeners();
    try {
      salary = await _service.getMySalarySummary();
      errorMessage = null;
    } catch (error) {
      errorMessage = _message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadSalary(refresh: true);

  String _message(Object error) {
    final value = error.toString();
    return value.startsWith('Exception: ') ? value.substring(11) : value;
  }
}
