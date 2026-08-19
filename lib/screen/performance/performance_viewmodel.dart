import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/performance/monthly_performance_model.dart';
import '../../model/performance/performance_access_model.dart';
import '../../model/performance/performance_employee_model.dart';
import '../../services/performance_service.dart';

enum PerformanceViewMode { myPerformance, employeePerformance }

class PerformanceViewModel extends ChangeNotifier {
  final PerformanceService _service;
  final String? _detailEmployee;
  Timer? _searchTimer;
  int _requestGeneration = 0;

  PerformanceViewModel({PerformanceService? service})
      : _service = service ?? PerformanceService(),
        _detailEmployee = null;

  PerformanceViewModel.detail({
    required String employee,
    required int month,
    required int year,
    PerformanceService? service,
  })  : _service = service ?? PerformanceService(),
        _detailEmployee = employee,
        _selectedMonth = month,
        _selectedYear = year;

  PerformanceAccessModel? _access;
  MonthlyPerformanceModel? _myPerformance;
  MonthlyPerformanceModel? _employeeDetail;
  final List<PerformanceEmployeeModel> _employees = [];
  final List<String> _departments = [];

  PerformanceViewMode _mode = PerformanceViewMode.myPerformance;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _search = '';
  String? _department;
  int _totalEmployees = 0;
  bool _hasMore = false;
  bool _initialLoading = false;
  bool _contentLoading = false;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _detailLoading = false;
  String? _error;

  PerformanceAccessModel? get access => _access;
  MonthlyPerformanceModel? get myPerformance => _myPerformance;
  MonthlyPerformanceModel? get employeeDetail => _employeeDetail;
  List<PerformanceEmployeeModel> get employees => List.unmodifiable(_employees);
  List<String> get departments => List.unmodifiable(_departments);
  PerformanceViewMode get mode => _mode;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  String? get selectedDepartment => _department;
  int get totalEmployees => _totalEmployees;
  bool get hasMore => _hasMore;
  bool get initialLoading => _initialLoading;
  bool get contentLoading => _contentLoading;
  bool get loadingMore => _loadingMore;
  bool get refreshing => _refreshing;
  bool get detailLoading => _detailLoading;
  String? get error => _error;
  bool get isManager => _access?.isPerformanceManager ?? false;
  int get minimumYear => _access?.minimumYear ?? 2000;
  bool get isDetailMode => _detailEmployee != null;

  String get selectedMonthLabel =>
      '${monthNames[_selectedMonth - 1]} $_selectedYear';

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  Future<void> initialise() async {
    if (_initialLoading || isDetailMode) return;
    _initialLoading = true;
    _error = null;
    notifyListeners();
    try {
      _access = await _service.getPerformanceAccess();
      _selectedMonth = _access!.defaultMonth;
      _selectedYear = _access!.defaultYear;
      final operations = <Future<dynamic>>[
        _service.getMyPerformance(month: _selectedMonth, year: _selectedYear),
        if (_access!.isPerformanceManager) _service.getPerformanceDepartments(),
      ];
      final results = await Future.wait(operations);
      _myPerformance = results.first as MonthlyPerformanceModel;
      if (_access!.isPerformanceManager && results.length > 1) {
        _replaceDepartments(results[1] as PerformanceDepartmentsModel);
      }
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _initialLoading = false;
      notifyListeners();
    }
  }

  Future<void> initialiseDetail() async {
    if (!isDetailMode || _detailLoading) return;
    _detailLoading = true;
    _error = null;
    notifyListeners();
    try {
      _employeeDetail = await _service.getEmployeePerformance(
        employee: _detailEmployee!,
        month: _selectedMonth,
        year: _selectedYear,
      );
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  Future<void> setMode(PerformanceViewMode value) async {
    if (value == _mode || (value == PerformanceViewMode.employeePerformance && !isManager)) {
      return;
    }
    _mode = value;
    _error = null;
    notifyListeners();
    if (_mode == PerformanceViewMode.employeePerformance && _employees.isEmpty) {
      await loadEmployees(reset: true);
    }
  }

  Future<void> selectPeriod(int month, int year) async {
    if (!_isValidPeriod(month, year) ||
        (month == _selectedMonth && year == _selectedYear)) return;
    _selectedMonth = month;
    _selectedYear = year;
    _error = null;
    notifyListeners();
    if (isDetailMode) {
      await initialiseDetail();
    } else if (_mode == PerformanceViewMode.myPerformance) {
      await _loadMyPerformance();
    } else {
      await loadEmployees(reset: true);
    }
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    notifyListeners();
    try {
      if (isDetailMode) {
        _employeeDetail = await _service.getEmployeePerformance(
          employee: _detailEmployee!,
          month: _selectedMonth,
          year: _selectedYear,
        );
      } else if (_mode == PerformanceViewMode.myPerformance) {
        _myPerformance = await _service.getMyPerformance(
          month: _selectedMonth,
          year: _selectedYear,
        );
      } else {
        await _fetchEmployees(reset: true);
      }
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> _loadMyPerformance() async {
    final generation = ++_requestGeneration;
    _contentLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.getMyPerformance(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (generation == _requestGeneration) _myPerformance = result;
    } catch (error) {
      if (generation == _requestGeneration) _error = _cleanError(error);
    } finally {
      if (generation == _requestGeneration) {
        _contentLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadEmployees({required bool reset}) async {
    if ((_contentLoading && reset) || (_loadingMore && !reset) || (!reset && !_hasMore)) return;
    if (reset) {
      _contentLoading = true;
      _error = null;
    } else {
      _loadingMore = true;
    }
    notifyListeners();
    try {
      await _fetchEmployees(reset: reset);
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _contentLoading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchEmployees({required bool reset}) async {
    final generation = reset ? ++_requestGeneration : _requestGeneration;
    final start = reset ? 0 : _employees.length;
    final response = await _service.getEmployeesPerformance(
      month: _selectedMonth,
      year: _selectedYear,
      search: _search,
      department: _department,
      start: start,
    );
    if (generation != _requestGeneration) return;
    if (reset) _employees.clear();
    final existing = _employees.map((employee) => employee.employee).toSet();
    _employees.addAll(
      response.employees.where((employee) => existing.add(employee.employee)),
    );
    _totalEmployees = response.total;
    _hasMore = response.hasMore;
  }

  void searchEmployees(String value) {
    _search = value.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 400),
      () => loadEmployees(reset: true),
    );
  }

  Future<void> setDepartment(String? value) async {
    final normalized = value?.trim();
    final next = normalized == null || normalized.isEmpty ? null : normalized;
    if (next == _department) return;
    _department = next;
    notifyListeners();
    await loadEmployees(reset: true);
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _replaceDepartments(PerformanceDepartmentsModel model) {
    _departments
      ..clear()
      ..addAll(model.departments);
  }

  bool _isValidPeriod(int month, int year) {
    if (month < 1 || month > 12 || year < minimumYear) return false;
    final now = DateTime.now();
    return year < now.year || (year == now.year && month <= now.month);
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
