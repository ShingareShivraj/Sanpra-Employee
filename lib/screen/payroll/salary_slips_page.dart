import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/salary_slip_model.dart';
import 'salary_slip_details_page.dart';
import 'salary_slips_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);

class SalarySlipsPage extends StatefulWidget {
  const SalarySlipsPage({super.key});
  @override
  State<SalarySlipsPage> createState() => _SalarySlipsPageState();
}

class _SalarySlipsPageState extends State<SalarySlipsPage> {
  late final SalarySlipsViewModel vm;
  final ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
    vm = SalarySlipsViewModel()..loadSlips();
    controller.addListener(() {
      if (controller.position.extentAfter < 250) vm.loadMore();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    vm.dispose();
    super.dispose();
  }

  Future<void> _filters() async {
    DateTime? from = vm.fromDate;
    DateTime? to = vm.toDate;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheet) {
        Future<void> pick(bool isFrom) async {
          final date = await showDatePicker(
            context: context,
            initialDate: (isFrom ? from : to) ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (date != null) setSheet(() => isFrom ? from = date : to = date);
        }
        return SafeArea(child: Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Filter Salary Slips', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _DateButton(label: 'From date', value: from, onTap: () => pick(true))),
              const SizedBox(width: 10),
              Expanded(child: _DateButton(label: 'To date', value: to, onTap: () => pick(false))),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () async {
                Navigator.pop(sheetContext); await vm.clearDateFilter();
              }, child: const Text('Clear'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: () async {
                Navigator.pop(sheetContext); await vm.applyDateFilter(from, to);
              }, child: const Text('Apply'))),
            ]),
          ]),
        ));
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    appBar: AppBar(
      title: const Text('Salary Slips'),
      foregroundColor: Colors.white,
      backgroundColor: _primary,
      actions: [IconButton(onPressed: _filters, tooltip: 'Date filter', icon: const Icon(Icons.tune_rounded))],
    ),
    body: AnimatedBuilder(animation: vm, builder: (context, _) {
      if (vm.isLoading && vm.salarySlips.isEmpty) return const Center(child: CircularProgressIndicator());
      if (vm.errorMessage != null && vm.salarySlips.isEmpty) {
        return _State(icon: Icons.error_outline, title: 'Could not load salary slips',
          subtitle: vm.errorMessage!, action: vm.loadSlips);
      }
      if (vm.salarySlips.isEmpty) {
        return _State(icon: Icons.receipt_long_outlined, title: 'No salary slips found',
          subtitle: vm.fromDate != null || vm.toDate != null
              ? 'Try changing or clearing the date filter.'
              : 'Your submitted salary slips will appear here.');
      }
      return RefreshIndicator(
        onRefresh: () => vm.loadSlips(refresh: true),
        child: ListView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          itemCount: vm.salarySlips.length + (vm.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == vm.salarySlips.length) return const Padding(
              padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator()));
            return _SlipCard(slip: vm.salarySlips[index], onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => SalarySlipDetailsPage(
                salarySlip: vm.salarySlips[index].name))),
            );
          },
        ),
      );
    }),
  );
}

class _SlipCard extends StatelessWidget {
  const _SlipCard({required this.slip, required this.onTap});
  final SalarySlipModel slip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12), elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: Color(0xFFE7EBF3))),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.receipt_long_outlined, color: _primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_period(slip), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 3),
            Text(slip.name, style: const TextStyle(fontSize: 12, color: Colors.black54),
              overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ]),
        const Divider(height: 24),
        Row(children: [
          Expanded(child: _Value('Gross', _money(slip.grossPay, slip.currency))),
          Expanded(child: _Value('Deduction', _money(slip.totalDeduction, slip.currency))),
          Expanded(child: _Value('Net Pay', _money(slip.netPay, slip.currency), strong: true)),
        ]),
      ]),
    )),
  );
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value, {this.strong = false});
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    const SizedBox(height: 4),
    Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12,
      color: strong ? _primary : Colors.black87, fontWeight: FontWeight.w700)),
  ]);
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: InputDecorator(
    decoration: InputDecoration(labelText: label, border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12))),
    child: Text(value == null ? 'Select' : DateFormat('dd MMM yyyy').format(value!)),
  ));
}

class _State extends StatelessWidget {
  const _State({required this.icon, required this.title, required this.subtitle, this.action});
  final IconData icon;
  final String title, subtitle;
  final Future<void> Function()? action;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 52, color: Colors.black26), const SizedBox(height: 12),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      if (action != null) ...[const SizedBox(height: 16), FilledButton(onPressed: action, child: const Text('Try Again'))],
    ])));
}

String _period(SalarySlipModel slip) {
  if (slip.startDate != null && slip.endDate != null) {
    return '${DateFormat('dd MMM').format(slip.startDate!)} – ${DateFormat('dd MMM yyyy').format(slip.endDate!)}';
  }
  return slip.endDate == null ? 'Salary Slip' : DateFormat('MMMM yyyy').format(slip.endDate!);
}
String _money(double value, String currency) => NumberFormat.currency(
  name: currency, symbol: currency == 'INR' ? '₹' : '$currency ', decimalDigits: 2).format(value);
