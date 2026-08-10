import 'leave_application_model.dart';
import 'leave_balance_model.dart';

class LeaveStatusCountsModel {
  final int open, approved, rejected, cancelled;
  const LeaveStatusCountsModel({required this.open, required this.approved,
    required this.rejected, required this.cancelled});
  factory LeaveStatusCountsModel.fromJson(Map<String, dynamic> json) =>
      LeaveStatusCountsModel(open: _int(json['Open']), approved: _int(json['Approved']),
        rejected: _int(json['Rejected']), cancelled: _int(json['Cancelled']));
  int get total => open + approved + rejected + cancelled;
}

class LeaveAccessModel {
  final bool success, isLeaveApprover;
  final String employee, employeeName, company;
  const LeaveAccessModel({required this.success, required this.isLeaveApprover,
    required this.employee, required this.employeeName, required this.company});
  factory LeaveAccessModel.fromJson(Map<String, dynamic> json) => LeaveAccessModel(
    success: _bool(json['success']), isLeaveApprover: _bool(json['is_leave_approver']),
    employee: '${json['employee'] ?? ''}', employeeName: '${json['employee_name'] ?? ''}',
    company: '${json['company'] ?? ''}');
}

class LeaveSummaryModel {
  final bool success;
  final String employee, employeeName, company;
  final List<LeaveBalanceModel> balances;
  final LeaveStatusCountsModel counts;
  final List<LeaveApplicationModel> recentApplications;
  const LeaveSummaryModel({required this.success, required this.employee,
    required this.employeeName, required this.company, required this.balances,
    required this.counts, required this.recentApplications});
  factory LeaveSummaryModel.fromJson(Map<String, dynamic> json) => LeaveSummaryModel(
    success: _bool(json['success']), employee: '${json['employee'] ?? ''}',
    employeeName: '${json['employee_name'] ?? ''}', company: '${json['company'] ?? ''}',
    balances: _maps(json['balances']).map(LeaveBalanceModel.fromJson).toList(),
    counts: LeaveStatusCountsModel.fromJson(_map(json['counts'])),
    recentApplications: _maps(json['recent_applications']).map(LeaveApplicationModel.fromJson).toList());
}

class LeaveManagementSummaryModel {
  final bool success;
  final String company;
  final LeaveStatusCountsModel counts;
  const LeaveManagementSummaryModel({required this.success, required this.company, required this.counts});
  factory LeaveManagementSummaryModel.fromJson(Map<String, dynamic> json) =>
      LeaveManagementSummaryModel(success: _bool(json['success']), company: '${json['company'] ?? ''}',
        counts: LeaveStatusCountsModel.fromJson(_map(json['counts'])));
}

int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
bool _bool(dynamic v) => v == true || v == 1 || '$v'.toLowerCase() == 'true';
Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : {};
List<Map<String, dynamic>> _maps(dynamic v) => v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
