import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/salary_model.dart';
import 'salary_slips_page.dart';
import 'salary_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);

class SalaryPage extends StatefulWidget {
  const SalaryPage({super.key});

  @override
  State<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage> {
  late final SalaryViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = SalaryViewModel()..loadSalary();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('My Salary'),
        foregroundColor: Colors.white,
        backgroundColor: _blue,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Salary slips',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalarySlipsPage()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: vm,
        builder: (context, _) {
          if (vm.isLoading && vm.salary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.errorMessage != null && vm.salary == null) {
            return _ErrorState(message: vm.errorMessage!, retry: vm.loadSalary);
          }
          final salary = vm.salary;
          if (salary == null) return const SizedBox.shrink();
          return RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
              children: [
                _SalaryHero(salary: salary),
                const SizedBox(height: 10),
                _AssignmentCard(salary: salary),
                const SizedBox(height: 10),
                _SectionCard(
                  title: 'Earnings',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF159A66),
                  items: salary.earnings,
                  currency: salary.currency,
                  emptyText: 'No earning components are available.',
                ),
                const SizedBox(height: 10),
                _SectionCard(
                  title: 'Deductions',
                  icon: Icons.trending_down_rounded,
                  color: const Color(0xFFE05252),
                  items: salary.deductions,
                  currency: salary.currency,
                  emptyText: 'No deduction components are available.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalarySlipsPage()),
                  ),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View Salary Slip History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    minimumSize: const Size.fromHeight(46),
                    side: const BorderSide(color: _blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SalaryHero extends StatelessWidget {
  const _SalaryHero({required this.salary});
  final SalaryModel salary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue, _darkBlue]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x33123FA0), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(salary.employeeName,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        const Text('Latest Net Salary',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text(_money(salary.netPay, salary.currency),
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _HeroValue('Gross', _money(salary.grossPay, salary.currency))),
          Container(width: 1, height: 34, color: Colors.white24),
          Expanded(child: _HeroValue('Deductions', _money(salary.totalDeduction, salary.currency))),
        ]),
        if (salary.latestSalarySlipEndDate != null) ...[
          const SizedBox(height: 10),
          Text('Calculated through ${_date(salary.latestSalarySlipEndDate)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ]),
    );
  }
}

class _HeroValue extends StatelessWidget {
  const _HeroValue(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    const SizedBox(height: 3),
    Text(value,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
  ]);
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.salary});
  final SalaryModel salary;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Title('Salary Structure', Icons.account_balance_wallet_outlined),
      const SizedBox(height: 10),
      _InfoRow('Structure', salary.salaryStructure ?? 'Not assigned'),
      _InfoRow('Base salary', _money(salary.baseSalary, salary.currency)),
      _InfoRow('Effective from', _date(salary.effectiveFrom)),
      _InfoRow('Frequency', salary.payrollFrequency ?? 'Not available'),
      _InfoRow('Company', salary.company, last: true, allowWrap: true),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.color,
    required this.items, required this.currency, required this.emptyText});
  final String title, currency, emptyText;
  final IconData icon;
  final Color color;
  final List<SalaryComponentModel> items;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(title, icon, color: color),
      const SizedBox(height: 10),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(emptyText, style: const TextStyle(color: Colors.black54)),
        )
      else
        ...items.where((e) => !e.statisticalComponent).map((item) =>
            _InfoRow(item.salaryComponent, _money(item.amount, currency))),
    ]),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF4)),
    ),
    child: child,
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text, this.icon, {this.color = _blue});
  final String text;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(
        color: color.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20)),
    const SizedBox(width: 10),
    Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  ]);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      this.label,
      this.value, {
        this.last = false,
        this.allowWrap = false,
      });
  final String label, value;
  final bool last;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(border: last ? null : const Border(
        bottom: BorderSide(color: Color(0xFFF0F2F7)))),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: allowWrap ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Color(0xFF182230),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retry});
  final String message;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      FilledButton(onPressed: retry, child: const Text('Try Again')),
    ]),
  ));
}

String _money(double value, String currency) =>
    NumberFormat.currency(name: currency, symbol: currency == 'INR' ? '₹' : '$currency ')
        .format(value);
String _date(DateTime? value) => value == null ? 'Not available' : DateFormat('dd MMM yyyy').format(value);
