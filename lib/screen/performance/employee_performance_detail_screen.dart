import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../model/performance/monthly_performance_model.dart';
import 'performance_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _navy = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF182230);
const _muted = Color(0xFF667085);

class EmployeePerformanceDetailScreen extends StatefulWidget {
  final String employee;
  final String employeeName;
  final int month;
  final int year;

  const EmployeePerformanceDetailScreen({
    super.key,
    required this.employee,
    required this.employeeName,
    required this.month,
    required this.year,
  });

  @override
  State<EmployeePerformanceDetailScreen> createState() =>
      _EmployeePerformanceDetailScreenState();
}

class _EmployeePerformanceDetailScreenState
    extends State<EmployeePerformanceDetailScreen> {
  late final PerformanceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PerformanceViewModel.detail(
      employee: widget.employee,
      month: widget.month,
      year: widget.year,
    )..initialiseDetail();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickPeriod() async {
    final selected = await showPerformanceMonthPicker(
      context,
      initialMonth: _viewModel.selectedMonth,
      initialYear: _viewModel.selectedYear,
      minimumYear: _viewModel.minimumYear,
    );
    if (selected != null) {
      await _viewModel.selectPeriod(selected.month, selected.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: _ink,
          elevation: 0,
          titleSpacing: 0,
          title: const Text(
            'Performance details',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.detailLoading && _viewModel.employeeDetail == null) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (_viewModel.employeeDetail == null) {
      return _ErrorState(
        message: _viewModel.error ?? 'Performance details are unavailable.',
        onRetry: _viewModel.initialiseDetail,
      );
    }

    final data = _viewModel.employeeDetail!;
    return RefreshIndicator(
      color: _blue,
      onRefresh: _viewModel.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _EmployeeHeader(data: data, fallbackName: widget.employeeName),
          const SizedBox(height: 10),
          _PeriodButton(label: _viewModel.selectedMonthLabel, onTap: _pickPeriod),
          if (_viewModel.error != null) ...[
            const SizedBox(height: 10),
            _InlineError(message: _viewModel.error!),
          ],
          const SizedBox(height: 12),
          _OverallCard(data: data),
          if (data.isPartialMonth) ...[
            const SizedBox(height: 10),
            const _InfoBanner(
              text: 'Current month results are calculated up to today.',
            ),
          ],
          const SizedBox(height: 14),
          const _SectionTitle('Performance metrics'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Attendance',
                  percentage: data.attendance.percentage,
                  detail: '${_number(data.attendance.present)} / ${data.attendance.workingDays} days',
                  naReason: data.attendance.naReason,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.task_alt_rounded,
                  title: 'Tasks',
                  percentage: data.tasks.percentage,
                  detail: '${data.tasks.completed} / ${data.tasks.total} completed',
                  naReason: data.tasks.naReason,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.checklist_rounded,
                  title: 'To-dos',
                  percentage: data.todos.percentage,
                  detail: '${data.todos.completed} / ${data.todos.total} completed',
                  naReason: data.todos.naReason,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.bug_report_outlined,
                  title: 'Issues',
                  percentage: data.issues.percentage,
                  detail: '${data.issues.resolved} / ${data.issues.total} resolved',
                  naReason: data.issues.naReason,
                ),
              ),
            ],
          ),
          if (data.attendance.statusCounts.isNotEmpty ||
              data.attendance.holidayCount > 0) ...[
            const SizedBox(height: 14),
            const _SectionTitle('Attendance breakdown'),
            const SizedBox(height: 8),
            _AttendanceBreakdown(attendance: data.attendance),
          ],
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Read-only monthly report',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeHeader extends StatelessWidget {
  final MonthlyPerformanceModel data;
  final String fallbackName;

  const _EmployeeHeader({required this.data, required this.fallbackName});

  @override
  Widget build(BuildContext context) {
    final employee = data.employee;
    final name = employee.employeeName.isEmpty ? fallbackName : employee.employeeName;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _Avatar(name: name, image: employee.image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(employee.subtitle.isEmpty ? employee.employee : employee.subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(20)),
            child: const Text('EMPLOYEE', style: TextStyle(color: _navy, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final MonthlyPerformanceModel data;
  const _OverallCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_navy, _blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x33123FA0), blurRadius: 16, offset: Offset(0, 7))],
      ),
      child: Row(
        children: [
          ScoreRing(score: data.overallPercentage, size: 86, light: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.monthLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('Overall performance', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                data.overallPercentage == null
                    ? (data.overallNaReason ?? 'No applicable metrics')
                    : '${data.applicableMetricCount} applicable metrics',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? percentage;
  final String detail;
  final String? naReason;

  const _MetricCard({required this.icon, required this.title, required this.percentage, required this.detail, this.naReason});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(percentage);
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
          const Spacer(),
          Text(percentage == null ? 'N/A' : '$percentage%', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(percentage == null ? (naReason ?? 'Not applicable') : detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10.5, height: 1.25)),
      ]),
    );
  }
}

class _AttendanceBreakdown extends StatelessWidget {
  final AttendancePerformanceModel attendance;
  const _AttendanceBreakdown({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, int>>[
      ...attendance.statusCounts.entries,
      if (attendance.holidayCount > 0) MapEntry('Holiday', attendance.holidayCount),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: entries.map((entry) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(8)),
          child: Text('${_pretty(entry.key)}  ${entry.value}', style: const TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w600)),
        )).toList(),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PeriodButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: _blue, size: 17),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700))),
          const Text('Change', style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(width: 3),
          const Icon(Icons.keyboard_arrow_down_rounded, color: _blue, size: 18),
        ]),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w800));
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [const Icon(Icons.info_outline_rounded, color: _blue, size: 17), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: _navy, fontSize: 11)))]),
  );
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFFFFECEC), borderRadius: BorderRadius.circular(10)),
    child: Text(message, style: const TextStyle(color: Color(0xFFB42318), fontSize: 11)),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, color: _muted, size: 42),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
      const SizedBox(height: 14),
      FilledButton(onPressed: onRetry, style: FilledButton.styleFrom(backgroundColor: _blue), child: const Text('Try again')),
    ]),
  ));
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? image;
  const _Avatar({required this.name, this.image});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFEAF1FF),
      foregroundImage: image == null ? null : NetworkImage(image!),
      child: Text(initial, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)),
    );
  }
}

class ScoreRing extends StatelessWidget {
  final int? score;
  final double size;
  final bool light;
  const ScoreRing({super.key, required this.score, this.size = 64, this.light = false});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _ScoreRingPainter(score: score, light: light),
      child: Center(child: Text(score == null ? 'N/A' : '$score%', style: TextStyle(color: light ? Colors.white : scoreColor(score), fontSize: size * .22, fontWeight: FontWeight.w800))),
    ),
  );
}

class _ScoreRingPainter extends CustomPainter {
  final int? score;
  final bool light;
  const _ScoreRingPainter({required this.score, required this.light});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .095;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final track = Paint()..color = light ? Colors.white24 : const Color(0xFFE7ECF4)..style = PaintingStyle.stroke..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (score != null) {
      final progress = score!.clamp(0, 100) / 100;
      final paint = Paint()..color = light ? Colors.white : scoreColor(score)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = stroke;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) => oldDelegate.score != score || oldDelegate.light != light;
}

Color scoreColor(int? score) {
  if (score == null) return _muted;
  if (score >= 80) return const Color(0xFF079455);
  if (score >= 60) return _blue;
  if (score >= 40) return const Color(0xFFF79009);
  return const Color(0xFFD92D20);
}

Future<DateTime?> showPerformanceMonthPicker(
  BuildContext context, {
  required int initialMonth,
  required int initialYear,
  required int minimumYear,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MonthPicker(initialMonth: initialMonth, initialYear: initialYear, minimumYear: minimumYear),
  );
}

class _MonthPicker extends StatefulWidget {
  final int initialMonth;
  final int initialYear;
  final int minimumYear;
  const _MonthPicker({required this.initialMonth, required this.initialYear, required this.minimumYear});
  @override
  State<_MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  late int year = widget.initialYear;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minYear = math.min(widget.minimumYear, now.year);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFD0D5DD), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Text('Select month', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800))),
            DropdownButtonHideUnderline(child: DropdownButton<int>(
              value: year,
              borderRadius: BorderRadius.circular(12),
              items: [for (int value = now.year; value >= minYear; value--) DropdownMenuItem(value: value, child: Text('$value'))],
              onChanged: (value) { if (value != null) setState(() => year = value); },
            )),
          ]),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.15, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final selected = month == widget.initialMonth && year == widget.initialYear;
              final disabled = year == now.year && month > now.month;
              return Material(
                color: selected ? _blue : _background,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: disabled ? null : () => Navigator.pop(context, DateTime(year, month)),
                  borderRadius: BorderRadius.circular(10),
                  child: Center(child: Text(PerformanceViewModel.monthNames[index].substring(0, 3), style: TextStyle(color: disabled ? const Color(0xFFB8C0CC) : selected ? Colors.white : _ink, fontSize: 12, fontWeight: FontWeight.w700))),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: const Color(0xFFEAECF0)),
);

String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);

String _pretty(String value) => value.replaceAll('_', ' ').split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}').join(' ');
