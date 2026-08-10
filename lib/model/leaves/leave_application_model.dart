class LeaveApprovalHistoryModel {
  final String name;
  final String content;
  final String user;
  final String userName;
  final DateTime? creation;

  const LeaveApprovalHistoryModel({required this.name, required this.content,
    required this.user, required this.userName, this.creation});

  factory LeaveApprovalHistoryModel.fromJson(Map<String, dynamic> json) =>
      LeaveApprovalHistoryModel(name: _s(json['name']), content: _s(json['content']),
        user: _s(json['user']), userName: _s(json['user_name']),
        creation: _dateTime(json['creation']));
}

class LeaveApplicationModel {
  final String name, employee, employeeName, company, leaveType, status;
  final String leaveApprover, reason;
  final DateTime? fromDate, toDate, halfDayDate, postingDate, creation, modified;
  final bool halfDay, canCancel, canApprove, canReject;
  final double totalLeaveDays;
  final double? availableBalance;
  final int docstatus;
  final List<LeaveApprovalHistoryModel> approvalHistory;

  const LeaveApplicationModel({required this.name, required this.employee,
    required this.employeeName, required this.company, required this.leaveType,
    required this.status, required this.leaveApprover, required this.reason,
    this.fromDate, this.toDate, this.halfDayDate, this.postingDate, this.creation,
    this.modified, required this.halfDay, required this.totalLeaveDays,
    this.availableBalance, required this.docstatus, required this.canCancel,
    required this.canApprove, required this.canReject,
    required this.approvalHistory});

  factory LeaveApplicationModel.fromJson(Map<String, dynamic> json) =>
      LeaveApplicationModel(name: _s(json['name']), employee: _s(json['employee']),
        employeeName: _s(json['employee_name']), company: _s(json['company']),
        leaveType: _s(json['leave_type']), status: _s(json['status']),
        leaveApprover: _s(json['leave_approver']), reason: _s(json['reason']),
        fromDate: _date(json['from_date']), toDate: _date(json['to_date']),
        halfDayDate: _date(json['half_day_date']), postingDate: _date(json['posting_date']),
        creation: _dateTime(json['creation']), modified: _dateTime(json['modified']),
        halfDay: _b(json['half_day']), totalLeaveDays: _d(json['total_leave_days']),
        availableBalance: json['available_balance'] == null ? null : _d(json['available_balance']),
        docstatus: _i(json['docstatus']), canCancel: _b(json['can_cancel']),
        canApprove: _b(json['can_approve']), canReject: _b(json['can_reject']),
        approvalHistory: _list(json['approval_history'])
            .map(LeaveApprovalHistoryModel.fromJson).toList());

  bool get isPending => status == 'Open';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
  bool get isCancelled => status == 'Cancelled';
}

class LeaveApplicationListModel {
  final bool success;
  final String company;
  final List<LeaveApplicationModel> applications;
  final int total, limitStart, limitPageLength;
  final bool hasMore;
  const LeaveApplicationListModel({required this.success, required this.company,
    required this.applications, required this.total, required this.limitStart,
    required this.limitPageLength, required this.hasMore});
  factory LeaveApplicationListModel.fromJson(Map<String, dynamic> json) =>
      LeaveApplicationListModel(success: _b(json['success']), company: _s(json['company']),
        applications: _list(json['applications']).map(LeaveApplicationModel.fromJson).toList(),
        total: _i(json['total']), limitStart: _i(json['limit_start']),
        limitPageLength: _i(json['limit_page_length']), hasMore: _b(json['has_more']));
}

String _s(dynamic v) => v?.toString() ?? '';
bool _b(dynamic v) => v == true || v == 1 || _s(v).toLowerCase() == 'true';
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(_s(v)) ?? 0;
double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse(_s(v)) ?? 0;
DateTime? _date(dynamic v) => _s(v).isEmpty ? null : DateTime.tryParse(_s(v));
DateTime? _dateTime(dynamic v) => _date(v);
List<Map<String, dynamic>> _list(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
