import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/leaves/leave_application_model.dart';
import '../model/leaves/leave_summary_model.dart';
import '../model/leaves/leave_type_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class LeaveService {
  final ApiService _api;
  LeaveService({ApiService? api}) : _api = api ?? ApiService();

  Future<LeaveAccessModel> getLeaveAccess() async =>
      LeaveAccessModel.fromJson(await _get(ApiEndpoints.leaveAccess));

  Future<LeaveTypeListModel> getMyLeaveTypes({DateTime? onDate}) async =>
      LeaveTypeListModel.fromJson(await _get(ApiEndpoints.myLeaveTypes,
        query: {if (onDate != null) 'on_date': _date(onDate)}));

  Future<LeaveSummaryModel> getMyLeaveSummary({int recentLimit = 5}) async =>
      LeaveSummaryModel.fromJson(await _get(ApiEndpoints.myLeaveSummary,
        query: {'recent_limit': recentLimit.clamp(1, 20)}));

  Future<LeaveApplicationModel> applyLeave({required String leaveType,
    required DateTime fromDate, required DateTime toDate, required String reason,
    bool halfDay = false, DateTime? halfDayDate}) async {
    _required(leaveType, 'Leave type is required.');
    _required(reason, 'Reason is required.');
    if (toDate.isBefore(fromDate)) throw Exception('To date cannot be before from date.');
    if (halfDay && halfDayDate != null &&
        (halfDayDate.isBefore(fromDate) || halfDayDate.isAfter(toDate))) {
      throw Exception('Half-day date must be within the leave date range.');
    }
    final data = await _post(ApiEndpoints.applyLeave, data: {
      'leave_type': leaveType.trim(), 'from_date': _date(fromDate),
      'to_date': _date(toDate), 'reason': reason.trim(), 'half_day': halfDay ? 1 : 0,
      if (halfDay) 'half_day_date': _date(halfDayDate ?? fromDate),
    });
    return _application(data);
  }

  Future<LeaveApplicationListModel> getMyLeaveApplications({String? status,
    int start = 0, int pageLength = 20}) async => LeaveApplicationListModel.fromJson(
      await _get(ApiEndpoints.myLeaveApplications, query: _page(status, start, pageLength)));

  Future<LeaveApplicationModel> getLeaveApplication(String name) async {
    _required(name, 'Leave Application is required.');
    return _application(await _get(ApiEndpoints.leaveApplication,
      query: {'leave_application': name.trim()}));
  }

  Future<LeaveApplicationModel> cancelLeaveApplication(String name) async {
    _required(name, 'Leave Application is required.');
    return _application(await _post(ApiEndpoints.cancelLeaveApplication,
      data: {'leave_application': name.trim()}));
  }

  Future<LeaveApplicationListModel> getPendingLeaveApplications({String? search,
    int start = 0, int pageLength = 20}) async => LeaveApplicationListModel.fromJson(
      await _get(ApiEndpoints.pendingLeaveApplications, query: {
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        'limit_start': start < 0 ? 0 : start,
        'limit_page_length': pageLength.clamp(1, 100),
      }));

  Future<LeaveManagementSummaryModel> getLeaveManagementSummary() async =>
      LeaveManagementSummaryModel.fromJson(await _get(ApiEndpoints.leaveManagementSummary));

  Future<LeaveApplicationModel> getLeaveApprovalDetails(String name) async {
    _required(name, 'Leave Application is required.');
    return _application(await _get(ApiEndpoints.leaveApprovalDetails,
      query: {'leave_application': name.trim()}));
  }

  Future<LeaveApplicationModel> approveLeaveApplication(String name, {String? remark}) async {
    _required(name, 'Leave Application is required.');
    return _application(await _post(ApiEndpoints.approveLeaveApplication, data: {
      'leave_application': name.trim(),
      if (remark?.trim().isNotEmpty == true) 'remark': remark!.trim(),
    }));
  }

  Future<LeaveApplicationModel> rejectLeaveApplication(String name, {required String reason}) async {
    _required(name, 'Leave Application is required.');
    _required(reason, 'Rejection reason is required.');
    return _application(await _post(ApiEndpoints.rejectLeaveApplication,
      data: {'leave_application': name.trim(), 'reason': reason.trim()}));
  }

  Map<String, dynamic> _page(String? status, int start, int length) => {
    if (status?.trim().isNotEmpty == true && status!.toLowerCase() != 'all') 'status': status.trim(),
    'limit_start': start < 0 ? 0 : start, 'limit_page_length': length.clamp(1, 100),
  };
  LeaveApplicationModel _application(Map<String, dynamic> data) =>
      LeaveApplicationModel.fromJson(_map(data['application']));

  Future<Map<String, dynamic>> _get(String url, {Map<String, dynamic>? query}) async {
    try { return _success(_message((await _api.get(url: url, queryParameters: query)).data)); }
    on DioException catch (e) { throw Exception(_dioMessage(e)); }
  }
  Future<Map<String, dynamic>> _post(String url, {required Map<String, dynamic> data}) async {
    try { return _success(_message((await _api.post(url: url, data: data)).data)); }
    on DioException catch (e) { throw Exception(_dioMessage(e)); }
  }
  Map<String, dynamic> _success(Map<String, dynamic> data) {
    if (data['success'] != true) throw Exception('${data['message'] ?? 'Leave request failed.'}');
    return data;
  }
  Map<String, dynamic> _message(dynamic value) {
    final root = _map(value); return root['message'] is Map ? _map(root['message']) : root;
  }
  Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : {};
  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  void _required(String value, String message) { if (value.trim().isEmpty) throw Exception(message); }
  String _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final server = data['_server_messages'];
      if (server is String) { try { final list = jsonDecode(server); if (list is List && list.isNotEmpty) {
        final item = jsonDecode('${list.first}'); if (item is Map && item['message'] != null) return '${item['message']}';
      }} catch (_) {} }
      final message = data['message'];
      if (message is Map && message['message'] != null) return '${message['message']}';
      if (message is String && message.isNotEmpty) return message;
      if (data['exception'] != null) return '${data['exception']}';
    }
    return error.message ?? 'Unable to process leave request.';
  }
}
