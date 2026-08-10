class LeaveTypeModel {
  final String leaveType;
  final double balance;
  final bool isLeaveWithoutPay;
  final bool allowNegative;
  final bool isCompensatory;

  const LeaveTypeModel({required this.leaveType, required this.balance,
    required this.isLeaveWithoutPay, required this.allowNegative,
    required this.isCompensatory});

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) => LeaveTypeModel(
    leaveType: _text(json['leave_type']), balance: _number(json['balance']),
    isLeaveWithoutPay: _bool(json['is_leave_without_pay']),
    allowNegative: _bool(json['allow_negative']),
    isCompensatory: _bool(json['is_compensatory']),
  );
}

class LeaveTypeListModel {
  final bool success;
  final String employee;
  final String company;
  final List<LeaveTypeModel> leaveTypes;

  const LeaveTypeListModel({required this.success, required this.employee,
    required this.company, required this.leaveTypes});

  factory LeaveTypeListModel.fromJson(Map<String, dynamic> json) => LeaveTypeListModel(
    success: _bool(json['success']), employee: _text(json['employee']),
    company: _text(json['company']),
    leaveTypes: _maps(json['leave_types']).map(LeaveTypeModel.fromJson).toList(),
  );
}

String _text(dynamic value) => value?.toString() ?? '';
double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse(_text(value)) ?? 0;
bool _bool(dynamic value) => value == true || value == 1 || _text(value).toLowerCase() == 'true';
List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];
