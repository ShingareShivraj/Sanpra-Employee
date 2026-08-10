class LeaveBalanceModel {
  final String leaveType;
  final double balance;
  final bool isLeaveWithoutPay;
  final bool allowNegative;
  final bool isCompensatory;

  const LeaveBalanceModel({required this.leaveType, required this.balance,
    required this.isLeaveWithoutPay, required this.allowNegative,
    required this.isCompensatory});

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) => LeaveBalanceModel(
    leaveType: json['leave_type']?.toString() ?? '',
    balance: json['balance'] is num ? (json['balance'] as num).toDouble()
        : double.tryParse('${json['balance'] ?? ''}') ?? 0,
    isLeaveWithoutPay: _asBool(json['is_leave_without_pay']),
    allowNegative: _asBool(json['allow_negative']),
    isCompensatory: _asBool(json['is_compensatory']),
  );

  bool get isPaidLeave => !isLeaveWithoutPay;
}

bool _asBool(dynamic value) => value == true || value == 1 || '$value'.toLowerCase() == 'true';
