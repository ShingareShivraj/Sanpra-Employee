import 'package:flutter/material.dart';

import '../../model/issue_model.dart';
import 'assign_issue_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _surface = Color(0xFFF4F7FC);

class AssignIssueScreen extends StatefulWidget {
  const AssignIssueScreen({super.key, required this.issueName});
  final String issueName;

  @override
  State<AssignIssueScreen> createState() => _AssignIssueScreenState();
}

class _AssignIssueScreenState extends State<AssignIssueScreen>
    with SingleTickerProviderStateMixin {
  late final AssignIssueViewModel _vm;
  late final TabController _tabs;
  final _search = TextEditingController();
  final Set<String> _selected = {};
  String? _fromEmployee;
  String? _toEmployee;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)..addListener(_refresh);
    _vm = AssignIssueViewModel(widget.issueName)..addListener(_refresh);
    _vm.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_refresh);
    _tabs.dispose();
    _search.dispose();
    _vm.removeListener(_refresh);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _surface,
    appBar: AppBar(
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assign Issue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Manage issue responsibility',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500,
                  color: Color(0xFFDCE8FF))),
        ],
      ),
      actions: [
        IconButton(
            onPressed: _vm.loading || _vm.processing ? null : _vm.load,
            icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
    body: _body(),
    bottomNavigationBar: _bottomAction(),
  );

  Widget _body() {
    if (_vm.loading && _vm.details == null) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (_vm.details == null) {
      return _state(Icons.lock_outline_rounded, 'Assignment unavailable',
          _vm.errorMessage ?? 'Please try again.');
    }
    final issue = _vm.details!.issue;
    return Column(children: [
      _hero(issue),
      if (!_vm.canManage)
        _notice('You can view assignments, but you do not have permission to change them.'),
      Container(
        color: _blue,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
        child: Container(
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(12)),
          child: TabBar(
            controller: _tabs,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(9)),
            labelColor: _blue,
            unselectedLabelColor: Colors.white,
            labelStyle:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            tabs: const [Tab(text: 'Add Employees'), Tab(text: 'Reassign')],
          ),
        ),
      ),
      Expanded(
          child: TabBarView(
              controller: _tabs, children: [_addEmployees(), _reassign()])),
    ]);
  }

  Widget _hero(IssueModel issue) => Container(
    width: double.infinity,
    color: _blue,
    padding: const EdgeInsets.fromLTRB(12, 3, 12, 12),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_blue, _darkBlue]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33FFFFFF))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(issue.name,
                  style: const TextStyle(
                      color: Color(0xFFDCE8FF), fontSize: 11.5))),
          Text('${issue.assignees.length} assigned',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Text(issue.subject,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w800)),
        if (issue.assignees.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: issue.assignees.take(3).map((employee) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(employee.employeeName,
                  style: const TextStyle(color: Colors.white, fontSize: 10.5,
                      fontWeight: FontWeight.w700)),
            )).toList(),
          ),
        ],
      ]),
    ),
  );

  Widget _addEmployees() => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 7),
      child: TextField(
        controller: _search,
        onChanged: _vm.setSearch,
        decoration: InputDecoration(
          hintText: 'Search employee, department or designation',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
              onPressed: () {
                _search.clear();
                _vm.setSearch('');
              },
              icon: const Icon(Icons.close_rounded, size: 19)),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blue, width: 1.4)),
        ),
      ),
    ),
    if (_selected.isNotEmpty)
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 5),
        child: Row(children: [
          Text('${_selected.length} employee${_selected.length == 1 ? '' : 's'} selected',
              style: const TextStyle(
                  fontSize: 12.5,
                  color: _blue,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          TextButton(
              onPressed: () => setState(_selected.clear),
              child: const Text('Clear')),
        ]),
      ),
    Expanded(
      child: _vm.employees.isEmpty
          ? _state(Icons.person_search_rounded, 'No employees found',
          'No unassigned employee matches your search.')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 90),
        itemCount: _vm.employees.length,
        itemBuilder: (_, index) {
          final employee = _vm.employees[index];
          final selected = _selected.contains(employee.name);
          return _employeeCard(employee, selected, () {
            setState(() => selected
                ? _selected.remove(employee.name)
                : _selected.add(employee.name));
          });
        },
      ),
    ),
  ]);

  Widget _reassign() {
    final assignees = _vm.details!.issue.assignees;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        _step('1', 'Select current assignee',
            'Choose the employee whose assignment will be replaced.'),
        const SizedBox(height: 8),
        if (assignees.isEmpty)
          _notice('This issue has no current assignee. Use Add Employees first.')
        else
          ...assignees.map((a) => _radioAssignee(a)),
        const SizedBox(height: 14),
        _step('2', 'Select new employee',
            'The issue will move from the current employee to this employee.'),
        const SizedBox(height: 8),
        if (_fromEmployee == null)
          _notice('Select a current assignee to continue.')
        else
          ..._vm.employees.map((e) => _radioEmployee(e)),
        if (_vm.errorMessage != null) ...[
          const SizedBox(height: 10),
          _notice(_vm.errorMessage!, error: true),
        ],
      ],
    );
  }

  Widget _employeeCard(
      CompanyEmployeeModel employee, bool selected, VoidCallback onTap) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: selected ? const Color(0xFFEAF1FF) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(
                color: selected ? _blue : const Color(0xFFE5EAF3))),
        child: CheckboxListTile(
          value: selected,
          onChanged: (_) => onTap(),
          activeColor: _blue,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(employee.employeeName,
              style:
              const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
          subtitle: Text(
              [employee.name, employee.designation, employee.department]
                  .whereType<String>()
                  .where((e) => e.isNotEmpty)
                  .join(' • '),
              style: const TextStyle(fontSize: 11.5)),
        ),
      );

  Widget _radioAssignee(IssueAssigneeModel employee) => RadioListTile<String>(
    value: employee.employeeId,
    groupValue: _fromEmployee,
    onChanged: (value) => setState(() {
      _fromEmployee = value;
      _toEmployee = null;
    }),
    activeColor: _blue,
    title: Text(employee.employeeName,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
    subtitle: Text(
        [employee.employeeId, employee.designation]
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .join(' • '),
        style: const TextStyle(fontSize: 11.5)),
  );

  Widget _radioEmployee(CompanyEmployeeModel employee) =>
      RadioListTile<String>(
        value: employee.name,
        groupValue: _toEmployee,
        onChanged: (value) => setState(() => _toEmployee = value),
        activeColor: _blue,
        title: Text(employee.employeeName,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        subtitle: Text(
            [employee.name, employee.designation, employee.department]
                .whereType<String>()
                .where((e) => e.isNotEmpty)
                .join(' • '),
            style: const TextStyle(fontSize: 11.5)),
      );

  Widget _step(String number, String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
          radius: 14,
          backgroundColor: _blue,
          child: Text(number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800))),
      const SizedBox(width: 9),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF64748B))),
              ])),
    ],
  );

  Widget _notice(String message, {bool error = false}) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
        color: error ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: error
            ? const Color(0xFFFECACA)
            : const Color(0xFFFDE68A))),
    child: Text(message,
        style: TextStyle(
            fontSize: 12.5,
            color: error
                ? const Color(0xFFB42318)
                : const Color(0xFF92400E))),
  );

  Widget? _bottomAction() {
    if (_vm.details == null || !_vm.canManage) return null;
    final adding = _tabs.index == 0;
    final enabled = adding
        ? _selected.isNotEmpty
        : _fromEmployee != null && _toEmployee != null;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 11),
      child: SizedBox(
        height: 50,
        child: FilledButton.icon(
          onPressed: !enabled || _vm.processing ? null : _submit,
          style: FilledButton.styleFrom(
              backgroundColor: _blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13))),
          icon: _vm.processing
              ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
              : Icon(adding
              ? Icons.person_add_alt_1_rounded
              : Icons.swap_horiz_rounded),
          label: Text(
              _vm.processing
                  ? 'Please wait...'
                  : adding
                  ? 'Assign ${_selected.length} Employee${_selected.length == 1 ? '' : 's'}'
                  : 'Confirm Reassignment',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final adding = _tabs.index == 0;
    if (!adding) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Reassignment'),
          content: const Text(
              'The current assignment will be removed and given to the selected employee.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reassign')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final ok = adding
        ? await _vm.assign(_selected.toList())
        : await _vm.reassign(
        fromEmployee: _fromEmployee!, toEmployee: _toEmployee!);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
        Text(adding ? 'Employees assigned successfully' : 'Issue reassigned')));
    Navigator.pop(context, true);
  }

  Widget _state(IconData icon, String title, String message) => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 50, color: const Color(0xFFB6C2D4)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          ])));
}
