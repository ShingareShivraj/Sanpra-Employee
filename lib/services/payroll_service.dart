import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../model/salary_model.dart';
import '../model/salary_slip_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class PayrollService {
  final ApiService _api;

  PayrollService({ApiService? api}) : _api = api ?? ApiService();

  Future<SalaryModel> getMySalarySummary() async {
    final data = await _get(ApiEndpoints.mySalarySummary);
    return SalaryModel.fromJson(data);
  }

  Future<SalarySlipListModel> getMySalarySlips({
    int start = 0,
    int pageLength = 20,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (fromDate != null && toDate != null && toDate.isBefore(fromDate)) {
      throw Exception('To date cannot be before from date.');
    }
    final data = await _get(
      ApiEndpoints.mySalarySlips,
      query: {
        'limit_start': start < 0 ? 0 : start,
        'limit_page_length': pageLength.clamp(1, 100),
        if (fromDate != null) 'from_date': _date(fromDate),
        if (toDate != null) 'to_date': _date(toDate),
      },
    );
    return SalarySlipListModel.fromJson(data);
  }

  Future<SalarySlipModel> getMySalarySlip(String salarySlip) async {
    _required(salarySlip, 'Salary Slip is required.');
    final data = await _get(
      ApiEndpoints.mySalarySlip,
      query: {'salary_slip': salarySlip.trim()},
    );
    return SalarySlipModel.fromJson(_map(data['salary_slip']));
  }

  /// Returns the PDF bytes. The UI may save, share, or open these bytes using
  /// its preferred platform package. Authentication is attached by ApiService.
  Future<Uint8List> downloadMySalarySlip(
    String salarySlip, {
    String? printFormat,
  }) async {
    _required(salarySlip, 'Salary Slip is required.');
    try {
      final response = await _api.get(
        url: ApiEndpoints.downloadMySalarySlip,
        queryParameters: {
          'salary_slip': salarySlip.trim(),
          if (printFormat?.trim().isNotEmpty == true)
            'print_format': printFormat!.trim(),
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'Accept': 'application/pdf'},
        ),
      );
      final data = response.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      throw Exception('The server did not return a valid PDF.');
    } on DioException catch (error) {
      throw Exception(_dioMessage(error));
    }
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _api.get(
        url: url,
        queryParameters: query,
      );
      return _success(_message(response.data));
    } on DioException catch (error) {
      throw Exception(_dioMessage(error));
    }
  }

  Map<String, dynamic> _success(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw Exception('${data['message'] ?? 'Payroll request failed.'}');
    }
    return data;
  }

  Map<String, dynamic> _message(dynamic value) {
    final root = _map(value);
    return root['message'] is Map ? _map(root['message']) : root;
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  void _required(String value, String message) {
    if (value.trim().isEmpty) throw Exception(message);
  }

  String _dioMessage(DioException error) {
    dynamic data = error.response?.data;
    if (data is List<int>) {
      try {
        data = jsonDecode(utf8.decode(data));
      } catch (_) {}
    }
    if (data is Map) {
      final serverMessages = data['_server_messages'];
      if (serverMessages is String) {
        try {
          final messages = jsonDecode(serverMessages);
          if (messages is List && messages.isNotEmpty) {
            final first = jsonDecode('${messages.first}');
            if (first is Map && first['message'] != null) {
              return '${first['message']}';
            }
          }
        } catch (_) {}
      }
      final message = data['message'];
      if (message is Map && message['message'] != null) {
        return '${message['message']}';
      }
      if (message is String && message.isNotEmpty) return message;
      if (data['exception'] != null) return '${data['exception']}';
    }
    return error.message ?? 'Unable to process payroll request.';
  }
}

