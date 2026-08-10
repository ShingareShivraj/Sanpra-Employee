import 'dart:convert';

import '../model/issue_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class IssueService {
  IssueService({ApiService? apiService}) : _api = apiService ?? ApiService();
  final ApiService _api;

  Map<String, dynamic> _message(dynamic response) {
    final raw = response.data;
    if (raw is! Map) throw Exception('Invalid server response');
    final root = Map<String, dynamic>.from(raw);
    final value = root['message'];
    return value is Map ? Map<String, dynamic>.from(value) : root;
  }

  void _ensureSuccess(Map<String, dynamic> data) {
    if (data['success'] != true) throw Exception('${data['message'] ?? 'Request failed'}');
  }

  Future<IssueModel> createIssue({required String subject, required String description,
    String priority = 'Medium', String? issueType}) async {
    final data = _message(await _api.post(url:ApiEndpoints.createIssue, data: {
      'subject': subject, 'description': description, 'priority': priority,
      if (issueType?.trim().isNotEmpty == true) 'issue_type': issueType,
    }));
    _ensureSuccess(data);
    return IssueModel.fromJson(Map<String, dynamic>.from(data['issue'] as Map));
  }

  Future<IssueListResult> getMyIssues({String? status, int start = 0, int pageLength = 20}) async {
    final d = _message(await _api.get(url:ApiEndpoints.myIssues, queryParameters: {
      if (status != null) 'status': status, 'start': start, 'page_length': pageLength}));
    _ensureSuccess(d); return IssueListResult.fromJson(d);
  }

  Future<IssueListResult> getAssignedIssues({String? status, int start = 0, int pageLength = 20}) async {
    final d = _message(await _api.get(url:ApiEndpoints.assignedIssues, queryParameters: {
      if (status != null) 'status': status, 'start': start, 'page_length': pageLength}));
    _ensureSuccess(d); return IssueListResult.fromJson(d);
  }

  Future<IssueListResult> getCompanyIssues({String? status, String? priority,
    String? issueType, String? search, int start = 0, int pageLength = 20}) async {
    final d = _message(await _api.get(url:ApiEndpoints.companyIssues, queryParameters: {
      if (status != null) 'status': status, if (priority != null) 'priority': priority,
      if (issueType != null) 'issue_type': issueType, if (search?.isNotEmpty == true) 'search': search,
      'start': start, 'page_length': pageLength}));
    _ensureSuccess(d); return IssueListResult.fromJson(d);
  }

  Future<IssueDetailsModel> getIssueDetails(String issueName) async {
    final d = _message(await _api.get(url:ApiEndpoints.issueDetails,
      queryParameters: {'issue_name': issueName}));
    _ensureSuccess(d); return IssueDetailsModel.fromJson(d);
  }

  Future<void> submitResolution({required String issueName, required String remarks}) async {
    final d = _message(await _api.post(url:ApiEndpoints.submitIssueResolution, data: {
      'issue_name': issueName, 'resolution_remarks': remarks}));
    _ensureSuccess(d);
  }

  Future<void> submitUnresolvedRemark({
    required String issueName,
    required String remarks,
  }) async {
    final d = _message(await _api.post(url:ApiEndpoints.submitUnresolvedRemark,
      data: {'issue_name': issueName, 'remarks': remarks},
    ));
    _ensureSuccess(d);
  }

  Future<void> assignIssue(String issueName, List<String> employeeIds) async {
    final d = _message(await _api.post(url:ApiEndpoints.assignIssue,
      data: {'issue_name': issueName, 'employee_ids': jsonEncode(employeeIds)}));
    _ensureSuccess(d);
  }

  Future<void> reassignIssue({required String issueName, required String fromEmployee,
    required String toEmployee}) async {
    final d = _message(await _api.post(url:ApiEndpoints.reassignIssue, data: {
      'issue_name': issueName, 'from_employee': fromEmployee, 'to_employee': toEmployee}));
    _ensureSuccess(d);
  }

  Future<void> updateStatus(String issueName, String status, {String? remarks}) async {
    final d = _message(await _api.post(url:ApiEndpoints.updateIssueStatus,
      data: {'issue_name': issueName, 'status': status, if (remarks != null) 'remarks': remarks}));
    _ensureSuccess(d);
  }

  Future<void> addRemark(String issueName, String remarks) async {
    final d = _message(await _api.post(url:ApiEndpoints.addIssueRemark,
      data: {'issue_name': issueName, 'remarks': remarks}));
    _ensureSuccess(d);
  }

  Future<void> resolveIssue(String issueName, String remarks) async {
    final d = _message(await _api.post(url:ApiEndpoints.resolveIssue,
      data: {'issue_name': issueName, 'resolution_remarks': remarks}));
    _ensureSuccess(d);
  }

  Future<void> closeIssue(String issueName, {String? remarks}) async {
    final d = _message(await _api.post(url:ApiEndpoints.closeIssue,
      data: {'issue_name': issueName, if (remarks != null) 'remarks': remarks}));
    _ensureSuccess(d);
  }

  Future<List<CompanyEmployeeModel>> getCompanyEmployees({
    String? search,
  }) async {
    final d = _message(
      await _api.get(
        url: ApiEndpoints.issueCompanyEmployees,
        queryParameters: {
          if (search?.isNotEmpty == true) 'search': search,
        },
      ),
    );

    _ensureSuccess(d);

    return _list(d['employees'])
        .map(CompanyEmployeeModel.fromJson)
        .toList();
  }

  Future<List<String>> getIssueTypes() async {
    final d = _message(await _api.get(url:ApiEndpoints.issueTypes)); _ensureSuccess(d);
    return _list(d['issue_types']).map((e) => '${e['name'] ?? ''}').where((e) => e.isNotEmpty).toList();
  }

  Future<IssueDashboardCounts> getDashboardCounts() async {
    final d = _message(await _api.get(url:ApiEndpoints.issueDashboard)); _ensureSuccess(d);
    return IssueDashboardCounts.fromJson(Map<String, dynamic>.from(d['counts'] as Map));
  }

  List<Map<String, dynamic>> _list(dynamic v) => v is List
      ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
}
