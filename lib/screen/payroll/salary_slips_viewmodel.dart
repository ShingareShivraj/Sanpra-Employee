import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../model/salary_slip_model.dart';
import '../../services/payroll_service.dart';

class SalarySlipsViewModel extends ChangeNotifier {
  SalarySlipsViewModel({PayrollService? service})
      : _service = service ?? PayrollService();

  final PayrollService _service;
  final List<SalarySlipModel> salarySlips = [];
  SalarySlipModel? selectedSlip;
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isLoadingDetails = false;
  bool isDownloading = false;
  bool hasMore = false;
  int total = 0;
  String? errorMessage;
  String? detailsError;
  static const int _pageLength = 20;

  Future<void> loadSlips({bool refresh = false}) async {
    if (isLoading || isLoadingMore) return;
    if (refresh) {
      salarySlips.clear();
      hasMore = false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.getMySalarySlips(
        start: 0,
        pageLength: _pageLength,
        fromDate: fromDate,
        toDate: toDate,
      );
      salarySlips
        ..clear()
        ..addAll(result.salarySlips);
      total = result.total;
      hasMore = result.hasMore;
    } catch (error) {
      errorMessage = _message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final result = await _service.getMySalarySlips(
        start: salarySlips.length,
        pageLength: _pageLength,
        fromDate: fromDate,
        toDate: toDate,
      );
      salarySlips.addAll(result.salarySlips);
      total = result.total;
      hasMore = result.hasMore;
      errorMessage = null;
    } catch (error) {
      errorMessage = _message(error);
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> applyDateFilter(DateTime? from, DateTime? to) async {
    if (from != null && to != null && to.isBefore(from)) {
      errorMessage = 'To date cannot be before from date.';
      notifyListeners();
      return;
    }
    fromDate = from;
    toDate = to;
    await loadSlips(refresh: true);
  }

  Future<void> clearDateFilter() => applyDateFilter(null, null);

  Future<void> loadDetails(String salarySlip) async {
    if (isLoadingDetails) return;
    isLoadingDetails = true;
    detailsError = null;
    selectedSlip = null;
    notifyListeners();
    try {
      selectedSlip = await _service.getMySalarySlip(salarySlip);
    } catch (error) {
      detailsError = _message(error);
    } finally {
      isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> downloadPdf(String salarySlip) async {
    if (isDownloading) return null;
    isDownloading = true;
    detailsError = null;
    notifyListeners();
    try {
      return await _service.downloadMySalarySlip(salarySlip);
    } catch (error) {
      detailsError = _message(error);
      return null;
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  String _message(Object error) {
    final value = error.toString();
    return value.startsWith('Exception: ') ? value.substring(11) : value;
  }
}
