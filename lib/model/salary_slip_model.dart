import 'salary_model.dart';

double _slipDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

DateTime? _slipDate(dynamic value) {
  if (value == null || '$value'.isEmpty) return null;
  return DateTime.tryParse('$value');
}

class SalarySlipModel {
  final String name;
  final String? employee;
  final String? employeeName;
  final String? company;
  final String? department;
  final String? designation;
  final DateTime? postingDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currency;
  final String? status;
  final String? salaryStructure;
  final String? payrollFrequency;
  final double workingDays;
  final double paymentDays;
  final double leaveWithoutPay;
  final double absentDays;
  final double grossPay;
  final double totalDeduction;
  final double netPay;
  final double roundedTotal;
  final List<SalaryComponentModel> earnings;
  final List<SalaryComponentModel> deductions;
  final bool canDownload;

  const SalarySlipModel({
    required this.name,
    this.employee,
    this.employeeName,
    this.company,
    this.department,
    this.designation,
    this.postingDate,
    this.startDate,
    this.endDate,
    this.currency = 'INR',
    this.status,
    this.salaryStructure,
    this.payrollFrequency,
    this.workingDays = 0,
    this.paymentDays = 0,
    this.leaveWithoutPay = 0,
    this.absentDays = 0,
    this.grossPay = 0,
    this.totalDeduction = 0,
    this.netPay = 0,
    this.roundedTotal = 0,
    this.earnings = const [],
    this.deductions = const [],
    this.canDownload = false,
  });

  factory SalarySlipModel.fromJson(Map<String, dynamic> json) {
    List<SalaryComponentModel> components(dynamic value) => value is List
        ? value
            .whereType<Map>()
            .map((item) => SalaryComponentModel.fromJson(
                Map<String, dynamic>.from(item)))
            .toList()
        : const [];

    return SalarySlipModel(
      name: '${json['name'] ?? ''}',
      employee: json['employee']?.toString(),
      employeeName: json['employee_name']?.toString(),
      company: json['company']?.toString(),
      department: json['department']?.toString(),
      designation: json['designation']?.toString(),
      postingDate: _slipDate(json['posting_date']),
      startDate: _slipDate(json['start_date']),
      endDate: _slipDate(json['end_date']),
      currency: '${json['currency'] ?? 'INR'}',
      status: json['status']?.toString(),
      salaryStructure: json['salary_structure']?.toString(),
      payrollFrequency: json['payroll_frequency']?.toString(),
      workingDays: _slipDouble(json['working_days']),
      paymentDays: _slipDouble(json['payment_days']),
      leaveWithoutPay: _slipDouble(json['leave_without_pay']),
      absentDays: _slipDouble(json['absent_days']),
      grossPay: _slipDouble(json['gross_pay']),
      totalDeduction: _slipDouble(json['total_deduction']),
      netPay: _slipDouble(json['net_pay']),
      roundedTotal: _slipDouble(json['rounded_total']),
      earnings: components(json['earnings']),
      deductions: components(json['deductions']),
      canDownload:
          json['can_download'] == true || json['can_download'] == 1,
    );
  }
}

class SalarySlipListModel {
  final List<SalarySlipModel> salarySlips;
  final int total;
  final int limitStart;
  final int limitPageLength;
  final bool hasMore;

  const SalarySlipListModel({
    this.salarySlips = const [],
    this.total = 0,
    this.limitStart = 0,
    this.limitPageLength = 20,
    this.hasMore = false,
  });

  factory SalarySlipListModel.fromJson(Map<String, dynamic> json) {
    final raw = json['salary_slips'];
    final slips = raw is List
        ? raw
            .whereType<Map>()
            .map((item) =>
                SalarySlipModel.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <SalarySlipModel>[];
    return SalarySlipListModel(
      salarySlips: slips,
      total: int.tryParse('${json['total'] ?? slips.length}') ?? slips.length,
      limitStart: int.tryParse('${json['limit_start'] ?? 0}') ?? 0,
      limitPageLength:
          int.tryParse('${json['limit_page_length'] ?? 20}') ?? 20,
      hasMore: json['has_more'] == true || json['has_more'] == 1,
    );
  }
}

