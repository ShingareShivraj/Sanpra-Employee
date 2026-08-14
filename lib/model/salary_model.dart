double _salaryDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

DateTime? _salaryDate(dynamic value) {
  if (value == null || '$value'.isEmpty) return null;
  return DateTime.tryParse('$value');
}

class SalaryComponentModel {
  final String salaryComponent;
  final String? abbreviation;
  final double amount;
  final double yearToDate;
  final String? formula;
  final bool statisticalComponent;

  const SalaryComponentModel({
    required this.salaryComponent,
    this.abbreviation,
    required this.amount,
    this.yearToDate = 0,
    this.formula,
    this.statisticalComponent = false,
  });

  factory SalaryComponentModel.fromJson(Map<String, dynamic> json) {
    return SalaryComponentModel(
      salaryComponent: '${json['salary_component'] ?? ''}',
      abbreviation: json['abbreviation']?.toString(),
      amount: _salaryDouble(json['amount']),
      yearToDate: _salaryDouble(json['year_to_date']),
      formula: json['formula']?.toString(),
      statisticalComponent: json['statistical_component'] == true ||
          json['statistical_component'] == 1,
    );
  }
}

class SalaryModel {
  final String employee;
  final String employeeName;
  final String company;
  final String? salaryStructure;
  final double baseSalary;
  final DateTime? effectiveFrom;
  final String currency;
  final String? payrollFrequency;
  final List<SalaryComponentModel> earnings;
  final List<SalaryComponentModel> deductions;
  final double grossPay;
  final double totalDeduction;
  final double netPay;
  final String? breakupSource;
  final String? latestSalarySlip;
  final DateTime? latestSalarySlipEndDate;

  const SalaryModel({
    required this.employee,
    required this.employeeName,
    required this.company,
    this.salaryStructure,
    required this.baseSalary,
    this.effectiveFrom,
    required this.currency,
    this.payrollFrequency,
    this.earnings = const [],
    this.deductions = const [],
    this.grossPay = 0,
    this.totalDeduction = 0,
    this.netPay = 0,
    this.breakupSource,
    this.latestSalarySlip,
    this.latestSalarySlipEndDate,
  });

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    List<SalaryComponentModel> components(dynamic value) => value is List
        ? value
            .whereType<Map>()
            .map((item) => SalaryComponentModel.fromJson(
                Map<String, dynamic>.from(item)))
            .toList()
        : const [];

    return SalaryModel(
      employee: '${json['employee'] ?? ''}',
      employeeName: '${json['employee_name'] ?? ''}',
      company: '${json['company'] ?? ''}',
      salaryStructure: json['salary_structure']?.toString(),
      baseSalary: _salaryDouble(json['base_salary']),
      effectiveFrom: _salaryDate(json['effective_from']),
      currency: '${json['currency'] ?? 'INR'}',
      payrollFrequency: json['payroll_frequency']?.toString(),
      earnings: components(json['earnings']),
      deductions: components(json['deductions']),
      grossPay: _salaryDouble(json['gross_pay']),
      totalDeduction: _salaryDouble(json['total_deduction']),
      netPay: _salaryDouble(json['net_pay']),
      breakupSource: json['breakup_source']?.toString(),
      latestSalarySlip: json['latest_salary_slip']?.toString(),
      latestSalarySlipEndDate:
          _salaryDate(json['latest_salary_slip_end_date']),
    );
  }

  bool get hasAssignment => salaryStructure?.isNotEmpty == true;
  bool get hasBreakup => earnings.isNotEmpty || deductions.isNotEmpty;
}

