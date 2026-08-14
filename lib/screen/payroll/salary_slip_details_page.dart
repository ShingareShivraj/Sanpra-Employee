import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../model/salary_model.dart';
import '../../model/salary_slip_model.dart';
import 'salary_slips_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);

class SalarySlipDetailsPage extends StatefulWidget {
  const SalarySlipDetailsPage({super.key, required this.salarySlip, this.onPdfReady});
  final String salarySlip;
  final Future<void> Function(Uint8List bytes, String fileName)? onPdfReady;
  @override
  State<SalarySlipDetailsPage> createState() => _SalarySlipDetailsPageState();
}

class _SalarySlipDetailsPageState extends State<SalarySlipDetailsPage> {
  late final SalarySlipsViewModel vm;
  @override
  void initState() {
    super.initState();
    vm = SalarySlipsViewModel()..loadDetails(widget.salarySlip);
  }
  @override
  void dispose() { vm.dispose(); super.dispose(); }

  Future<void> _download() async {
    try {
      final bytes = await vm.downloadPdf(widget.salarySlip);

      if (!mounted || bytes == null) return;

      final directory = await getApplicationDocumentsDirectory();

      final safeFileName =
      widget.salarySlip
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

      final file = File(
        '${directory.path}/$safeFileName.pdf',
      );

      await file.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(file.path);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salary slip PDF opened successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open salary slip: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    appBar: AppBar(title: const Text('Salary Slip Details'), foregroundColor: Colors.white,
        backgroundColor: _blue),
    body: AnimatedBuilder(animation: vm, builder: (context, _) {
      if (vm.isLoadingDetails) return const Center(child: CircularProgressIndicator());
      if (vm.detailsError != null && vm.selectedSlip == null) return _Error(
          message: vm.detailsError!, retry: () => vm.loadDetails(widget.salarySlip));
      final slip = vm.selectedSlip;
      if (slip == null) return const SizedBox.shrink();
      return RefreshIndicator(
        onRefresh: () => vm.loadDetails(widget.salarySlip),
        child: ListView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 92), children: [
          _Hero(slip: slip),
          const SizedBox(height: 10),
          _Section(title: 'Attendance & Pay Days', icon: Icons.calendar_month_outlined, child: Column(children: [
            _Info('Working days', _number(slip.workingDays)),
            _Info('Payment days', _number(slip.paymentDays)),
            _Info('Leave without pay', _number(slip.leaveWithoutPay)),
            _Info('Absent days', _number(slip.absentDays), last: true),
          ])),
          const SizedBox(height: 10),
          _Components(title: 'Earnings', color: const Color(0xFF159A66),
              items: slip.earnings, currency: slip.currency),
          const SizedBox(height: 10),
          _Components(title: 'Deductions', color: const Color(0xFFE05252),
              items: slip.deductions, currency: slip.currency),
          const SizedBox(height: 10),
          _Section(title: 'Employment Details', icon: Icons.badge_outlined, child: Column(children: [
            _Info('Employee', slip.employeeName ?? slip.employee ?? 'Not available'),
            _Info('Employee ID', slip.employee ?? 'Not available'),
            _Info('Department', slip.department ?? 'Not available'),
            _Info('Designation', slip.designation ?? 'Not available'),
            _Info(
              'Company',
              slip.company ?? 'Not available',
              last: true,
              allowWrap: true,
            ),
          ])),
        ]),
      );
    }),
    bottomNavigationBar: AnimatedBuilder(animation: vm, builder: (context, _) {
      final slip = vm.selectedSlip;
      if (slip == null || !slip.canDownload) return const SizedBox.shrink();
      return SafeArea(top: false, child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        decoration: const BoxDecoration(color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, -3))]),
        child: FilledButton.icon(
          onPressed: vm.isDownloading ? null : _download,
          icon: vm.isDownloading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.download_rounded),
          label: Text(vm.isDownloading ? 'Preparing PDF...' : 'Download Salary Slip'),
          style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ));
    }),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.slip});
  final SalarySlipModel slip;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_blue, Color(0xFF123FA0)]),
        borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Net Pay', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(_money(slip.netPay, slip.currency), style: const TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(20)),
            child: Text(slip.status ?? 'Submitted', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 14),
      Text(_period(slip), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(slip.name, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      const Divider(height: 26, color: Colors.white24),
      Row(children: [
        Expanded(child: _HeroValue('Gross', _money(slip.grossPay, slip.currency))),
        Expanded(child: _HeroValue('Deductions', _money(slip.totalDeduction, slip.currency))),
      ]),
    ]),
  );
}

class _HeroValue extends StatelessWidget {
  const _HeroValue(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    const SizedBox(height: 3),
    Text(value, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
  ]);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7EBF3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: _blue, size: 21), const SizedBox(width: 9),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 8), child,
      ]));
}

class _Components extends StatelessWidget {
  const _Components({required this.title, required this.color, required this.items, required this.currency});
  final String title, currency;
  final Color color;
  final List<SalaryComponentModel> items;
  @override
  Widget build(BuildContext context) => _Section(title: title,
      icon: title == 'Earnings' ? Icons.add_circle_outline : Icons.remove_circle_outline,
      child: items.isEmpty
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No components available.',
          style: TextStyle(color: Colors.black54)))
          : Column(children: [
        ...items.where((e) => !e.statisticalComponent).map((e) => _Info(
            e.salaryComponent, _money(e.amount, currency))),
        const Divider(height: 20),
        _Info('Total', _money(items.where((e) => !e.statisticalComponent)
            .fold<double>(0, (sum, e) => sum + e.amount), currency), color: color, last: true),
      ]));
}

class _Info extends StatelessWidget {
  const _Info(
      this.label,
      this.value, {
        this.last = false,
        this.color,
        this.allowWrap = false,
      });
  final String label, value;
  final bool last;
  final Color? color;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF0F2F7)))),
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
              style: TextStyle(
                color: color ?? const Color(0xFF182230),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ));
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.retry});
  final String message;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 50, color: Colors.redAccent), const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center), const SizedBox(height: 16),
        FilledButton(onPressed: retry, child: const Text('Try Again')),
      ])));
}

String _money(double value, String currency) => NumberFormat.currency(
    name: currency, symbol: currency == 'INR' ? '₹' : '$currency ').format(value);
String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
String _period(SalarySlipModel slip) {
  if (slip.startDate != null && slip.endDate != null) {
    return '${DateFormat('dd MMM').format(slip.startDate!)} – ${DateFormat('dd MMM yyyy').format(slip.endDate!)}';
  }
  return slip.endDate == null ? 'Pay period unavailable' : DateFormat('MMMM yyyy').format(slip.endDate!);
}
