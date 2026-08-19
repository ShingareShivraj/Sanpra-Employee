import 'package:flutter/material.dart';

import '../../model/performance/monthly_performance_model.dart';
import '../../model/performance/performance_employee_model.dart';
import 'employee_performance_detail_screen.dart';
import 'performance_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _navy = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF182230);
const _muted = Color(0xFF667085);

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final PerformanceViewModel _viewModel = PerformanceViewModel();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _viewModel.initialise();
  }

  void _onScroll() {
    if (_viewModel.mode == PerformanceViewMode.employeePerformance &&
        _scrollController.position.extentAfter < 280) {
      _viewModel.loadEmployees(reset: false);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickPeriod() async {
    final result = await showPerformanceMonthPicker(
      context,
      initialMonth: _viewModel.selectedMonth,
      initialYear: _viewModel.selectedYear,
      minimumYear: _viewModel.minimumYear,
    );
    if (result != null) {
      await _viewModel.selectPeriod(result.month, result.year);
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
          title: const Text('Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _viewModel.refreshing ? null : _viewModel.refresh,
              icon: _viewModel.refreshing
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _blue))
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_viewModel.initialLoading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (_viewModel.access == null) {
      return _PageError(message: _viewModel.error ?? 'Unable to load performance.', onRetry: _viewModel.initialise);
    }

    return RefreshIndicator(
      color: _blue,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _WelcomeCard(name: _viewModel.access!.employee.employeeName),
              const SizedBox(height: 10),
              _PeriodSelector(label: _viewModel.selectedMonthLabel, onTap: _pickPeriod),
              if (_viewModel.isManager) ...[
                const SizedBox(height: 10),
                _ModeSwitch(viewModel: _viewModel),
              ],
              if (_viewModel.error != null) ...[
                const SizedBox(height: 10),
                _InlineError(message: _viewModel.error!),
              ],
            ])),
          ),
          if (_viewModel.contentLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _blue)))
          else if (_viewModel.mode == PerformanceViewMode.myPerformance)
            _myPerformance()
          else
            _employeePerformance(),
        ],
      ),
    );
  }

  Widget _myPerformance() {
    final data = _viewModel.myPerformance;
    if (data == null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(icon: Icons.query_stats_rounded, title: 'No performance data', message: 'No report is available for this month.', action: _viewModel.refresh),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
      sliver: SliverList(delegate: SliverChildListDelegate([
        _OverallSummary(data: data),
        if (data.isPartialMonth) ...[
          const SizedBox(height: 10),
          const _InfoBanner(text: 'Live result for the current month, calculated up to today.'),
        ],
        const SizedBox(height: 14),
        const Text('Your metrics', style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _MetricTile(icon: Icons.calendar_month_rounded, title: 'Attendance', score: data.attendance.percentage, detail: '${_number(data.attendance.present)} / ${data.attendance.workingDays} days', reason: data.attendance.naReason)),
          const SizedBox(width: 10),
          Expanded(child: _MetricTile(icon: Icons.task_alt_rounded, title: 'Tasks', score: data.tasks.percentage, detail: '${data.tasks.completed} / ${data.tasks.total} completed', reason: data.tasks.naReason)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _MetricTile(icon: Icons.checklist_rounded, title: 'To-dos', score: data.todos.percentage, detail: '${data.todos.completed} / ${data.todos.total} completed', reason: data.todos.naReason)),
          const SizedBox(width: 10),
          Expanded(child: _MetricTile(icon: Icons.bug_report_outlined, title: 'Issues', score: data.issues.percentage, detail: '${data.issues.resolved} / ${data.issues.total} resolved', reason: data.issues.naReason)),
        ]),
      ])),
    );
  }

  Widget _employeePerformance() {
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
        child: Column(children: [
          _EmployeeFilters(
            controller: _searchController,
            departments: _viewModel.departments,
            selectedDepartment: _viewModel.selectedDepartment,
            onSearch: _viewModel.searchEmployees,
            onDepartment: _viewModel.setDepartment,
          ),
          const SizedBox(height: 11),
          Row(children: [
            const Expanded(child: Text('Employee performance', style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w800))),
            Text('${_viewModel.totalEmployees} employees', style: const TextStyle(color: _muted, fontSize: 11)),
          ]),
        ]),
      ),
      if (_viewModel.employees.isEmpty)
        const _EmptyState(icon: Icons.people_outline_rounded, title: 'No employees found', message: 'Try changing the search or department filter.'),
      for (final employee in _viewModel.employees) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
          child: _EmployeeCard(employee: employee, onTap: () => _openEmployee(employee)),
        ),
      ],
      Padding(
        padding: const EdgeInsets.only(bottom: 26, top: 8),
        child: _viewModel.loadingMore
            ? const Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _blue)))
            : _viewModel.hasMore
                ? Center(child: TextButton(onPressed: () => _viewModel.loadEmployees(reset: false), child: const Text('Load more')))
                : const SizedBox.shrink(),
      ),
    ];
    return SliverList(delegate: SliverChildListDelegate(children));
  }

  Future<void> _openEmployee(PerformanceEmployeeModel employee) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmployeePerformanceDetailScreen(
      employee: employee.employee,
      employeeName: employee.employeeName,
      month: _viewModel.selectedMonth,
      year: _viewModel.selectedYear,
    )));
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  const _WelcomeCard({required this.name});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEAECF0))),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.insights_rounded, color: _blue, size: 22)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name.isEmpty ? 'Monthly overview' : 'Hello, ${name.split(' ').first}', style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        const Text('Track monthly work performance at a glance.', style: TextStyle(color: _muted, fontSize: 10.5)),
      ])),
    ]),
  );
}

class _PeriodSelector extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PeriodSelector({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11), child: Row(children: [
        const Icon(Icons.calendar_today_rounded, color: _blue, size: 17),
        const SizedBox(width: 9),
        Expanded(child: Text(label, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700))),
        const Text('Select month', style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w700)),
        const Icon(Icons.keyboard_arrow_down_rounded, color: _blue, size: 18),
      ])),
    ),
  );
}

class _ModeSwitch extends StatelessWidget {
  final PerformanceViewModel viewModel;
  const _ModeSwitch({required this.viewModel});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: const Color(0xFFE8ECF3), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      _option('My performance', PerformanceViewMode.myPerformance, Icons.person_outline_rounded),
      _option('Employees', PerformanceViewMode.employeePerformance, Icons.groups_outlined),
    ]),
  );

  Widget _option(String label, PerformanceViewMode mode, IconData icon) {
    final active = viewModel.mode == mode;
    return Expanded(child: InkWell(
      onTap: () => viewModel.setMode(mode),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(9), boxShadow: active ? const [BoxShadow(color: Color(0x16000000), blurRadius: 7)] : null),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: active ? _blue : _muted), const SizedBox(width: 6), Text(label, style: TextStyle(color: active ? _navy : _muted, fontSize: 11, fontWeight: FontWeight.w700))]),
      ),
    ));
  }
}

class _OverallSummary extends StatelessWidget {
  final MonthlyPerformanceModel data;
  const _OverallSummary({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, _blue]), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x30123FA0), blurRadius: 16, offset: Offset(0, 7))]),
    child: Row(children: [
      ScoreRing(score: data.overallPercentage, size: 88, light: true),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data.monthLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        const Text('Overall performance', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(data.overallPercentage == null ? (data.overallNaReason ?? 'No applicable metrics') : '${data.applicableMetricCount} metrics included', style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ])),
    ]),
  );
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? score;
  final String detail;
  final String? reason;
  const _MetricTile({required this.icon, required this.title, required this.score, required this.detail, this.reason});
  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEAECF0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color)), const Spacer(), Text(score == null ? 'N/A' : '$score%', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(score == null ? (reason ?? 'Not applicable') : detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10.5)),
      ]),
    );
  }
}

class _EmployeeFilters extends StatelessWidget {
  final TextEditingController controller;
  final List<String> departments;
  final String? selectedDepartment;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onDepartment;
  const _EmployeeFilters({required this.controller, required this.departments, required this.selectedDepartment, required this.onSearch, required this.onDepartment});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: TextField(
      controller: controller,
      onChanged: onSearch,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(hintText: 'Search employee', hintStyle: const TextStyle(color: _muted, fontSize: 12), prefixIcon: const Icon(Icons.search_rounded, size: 19), filled: true, fillColor: Colors.white, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 11), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    )),
    const SizedBox(width: 8),
    PopupMenuButton<String?>(
      tooltip: 'Filter department',
      initialValue: selectedDepartment,
      onSelected: onDepartment,
      itemBuilder: (_) => [const PopupMenuItem<String?>(value: null, child: Text('All departments')), ...departments.map((value) => PopupMenuItem<String?>(value: value, child: Text(value)))],
      child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: selectedDepartment == null ? Colors.white : const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.tune_rounded, color: selectedDepartment == null ? _muted : _blue, size: 20)),
    ),
  ]);
}

class _EmployeeCard extends StatelessWidget {
  final PerformanceEmployeeModel employee;
  final VoidCallback onTap;
  const _EmployeeCard({required this.employee, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEAECF0))),
        child: Row(children: [
          _EmployeeAvatar(employee: employee),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(employee.employeeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 13.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(employee.subtitle.isEmpty ? employee.employee : employee.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 5, runSpacing: 5, children: [
              _ScoreChip(label: 'A', score: employee.attendancePercentage),
              _ScoreChip(label: 'T', score: employee.taskPercentage),
              _ScoreChip(label: 'D', score: employee.todoPercentage),
              _ScoreChip(label: 'I', score: employee.issuePercentage),
            ]),
          ])),
          const SizedBox(width: 8),
          ScoreRing(score: employee.overallPercentage, size: 58),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3), size: 20),
        ]),
      ),
    ),
  );
}

class _EmployeeAvatar extends StatelessWidget {
  final PerformanceEmployeeModel employee;
  const _EmployeeAvatar({required this.employee});
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundColor: const Color(0xFFEAF1FF),
    foregroundImage: employee.image == null ? null : NetworkImage(employee.image!),
    child: Text(employee.employeeName.isEmpty ? '?' : employee.employeeName[0].toUpperCase(), style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)),
  );
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int? score;
  const _ScoreChip({required this.label, required this.score});
  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(.09), borderRadius: BorderRadius.circular(6)), child: Text('$label ${score == null ? 'N/A' : '$score%'}', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)));
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.info_outline_rounded, color: _blue, size: 17), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: _navy, fontSize: 11)))]));
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFECEC), borderRadius: BorderRadius.circular(10)), child: Text(message, style: const TextStyle(color: Color(0xFFB42318), fontSize: 11)));
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? action;
  const _EmptyState({required this.icon, required this.title, required this.message, this.action});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(34), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFF98A2B3), size: 43), const SizedBox(height: 10), Text(title, style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 11)), if (action != null) ...[const SizedBox(height: 12), TextButton(onPressed: action, child: const Text('Refresh'))]]));
}

class _PageError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _PageError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, color: _muted, size: 44), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)), const SizedBox(height: 14), FilledButton(onPressed: onRetry, style: FilledButton.styleFrom(backgroundColor: _blue), child: const Text('Try again'))])));
}

String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
