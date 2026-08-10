import 'package:flutter/material.dart';

import '../../model/issue_model.dart';
import 'issue_details_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _ink = Color(0xFF172033);

class IssueDetailsScreen extends StatefulWidget {
  const IssueDetailsScreen({super.key, required this.issueName});
  final String issueName;
  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  late final IssueDetailsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = IssueDetailsViewModel(widget.issueName)..addListener(_changed);
    _vm.load();
  }

  void _changed() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _vm.removeListener(_changed);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FC),
    appBar: AppBar(
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Issue Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text('Information, activity and actions', style: TextStyle(fontSize: 10.5, color: Color(0xFFDCE8FF))),
      ]),
      actions: [IconButton(tooltip: 'Refresh', onPressed: _vm.loading || _vm.processing ? null : _vm.load, icon: const Icon(Icons.refresh_rounded))],
    ),
    body: _body(),
    bottomNavigationBar: _actions(),
  );

  Widget _body() {
    if (_vm.loading && _vm.details == null) return const Center(child: CircularProgressIndicator(color: _blue));
    if (_vm.details == null) return _error();
    final d = _vm.details!;
    final issue = d.issue;
    return RefreshIndicator(
      onRefresh: _vm.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
        children: [
          _hero(issue),
          const SizedBox(height: 10),
          _section('Issue Information', Icons.info_outline_rounded, [
            _row(Icons.person_outline_rounded, 'Created by', issue.createdByName ?? issue.createdByEmployee ?? 'Not available'),
            _row(Icons.business_outlined, 'Company', issue.company ?? 'Not available'),
            _row(Icons.category_outlined, 'Issue type', issue.issueType?.isNotEmpty == true ? issue.issueType! : 'No Issue Type'),
            _row(Icons.flag_outlined, 'Priority', issue.priority),
            _row(Icons.schedule_rounded, 'Raised on', _date(issue.creation ?? issue.openingDate)),
          ]),
          const SizedBox(height: 10),
          _section('Description', Icons.notes_rounded, [
            Text(_plain(issue.description), style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155))),
          ]),
          if (issue.assignees.isNotEmpty) ...[
            const SizedBox(height: 10),
            _section('Assigned Employees', Icons.groups_2_outlined, issue.assignees.map((a) => _assignee(a)).toList()),
          ],
          if (issue.resolutionDetails?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _section('Resolution', Icons.task_alt_rounded, [
              Text(_plain(issue.resolutionDetails!), style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF14532D))),
              if (issue.resolutionDateTime != null) ...[const SizedBox(height: 8), _row(Icons.event_available_rounded, 'Resolved on', _date(issue.resolutionDateTime))],
            ], tint: const Color(0xFFF0FDF4), border: const Color(0xFFBBF7D0)),
          ],
          if (d.timeline.isNotEmpty) ...[
            const SizedBox(height: 10),
            _section('Remarks & Activity', Icons.forum_outlined, d.timeline.map(_remark).toList()),
          ],
          if (_vm.errorMessage != null) ...[const SizedBox(height: 10), _errorBox(_vm.errorMessage!)],
        ],
      ),
    );
  }

  Widget _hero(IssueModel issue) {
    final color = _statusColor(issue.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_blue, _darkBlue]),
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [BoxShadow(color: Color(0x26123FA0), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(issue.name, style: const TextStyle(color: Color(0xFFDCE8FF), fontSize: 12, fontWeight: FontWeight.w600))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Text(issue.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color))),
        ]),
        const SizedBox(height: 10),
        Text(issue.subject, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 7, children: [
          _heroMeta(Icons.flag_outlined, '${issue.priority} priority'),
          if (issue.issueType?.isNotEmpty == true) _heroMeta(Icons.category_outlined, issue.issueType!),
          _heroMeta(Icons.person_outline_rounded, issue.createdByName ?? 'Employee'),
        ]),
      ]),
    );
  }

  Widget _heroMeta(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: const Color(0x24FFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x22FFFFFF))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFFDCE8FF), size: 14), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600))]),
  );

  Widget? _actions() {
    final d = _vm.details;
    if (d == null) return null;
    final issue = d.issue;
    final done = ['resolved', 'closed'].contains(issue.status.toLowerCase());
    if ((!d.canSubmitResolution && !d.canManage) || (done && !d.canManage)) return null;
    return Material(
        color: Colors.white,
        elevation: 12,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 10, 12, 11),
          child: _vm.processing
              ? const SizedBox(height: 49, child: Center(child: CircularProgressIndicator(color: _blue)))
              : d.canManage
              ? Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _managerMenu, icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Manage'), style: _buttonStyle(false))),
            const SizedBox(width: 9),
            Expanded(child: FilledButton.icon(onPressed: _addRemark, icon: const Icon(Icons.add_comment_outlined), label: const Text('Add Remark'), style: _buttonStyle(true))),
          ])
              : Row(children: [
            Expanded(child: OutlinedButton(onPressed: _unable, style: _buttonStyle(false), child: const Text('Unable to Resolve'))),
            const SizedBox(width: 9),
            Expanded(child: FilledButton.icon(onPressed: _resolve, icon: const Icon(Icons.check_rounded), label: const Text('Resolve'), style: _buttonStyle(true))),
          ]),
        ));
  }

  Future<void> _resolve() async {
    final text = await _textDialog('Resolve Issue', 'Resolution remark', 'Explain what was done to resolve this issue.', 'Mark Resolved');
    if (text != null) await _result(await _vm.submitResolution(text), 'Issue marked as resolved');
  }

  Future<void> _unable() async {
    final text = await _textDialog('Unable to Resolve', 'Reason / remark', 'Explain the blocker or support required.', 'Submit Remark');
    if (text != null) await _result(await _vm.submitUnableRemark(text), 'Remark submitted');
  }

  Future<void> _addRemark() async {
    final text = await _textDialog('Add Manager Remark', 'Remark', 'Add guidance, feedback, or an update.', 'Add Remark');
    if (text != null) await _result(await _vm.addManagerRemark(text), 'Remark added');
  }

  Future<void> _managerMenu() async {
    final d = _vm.details!;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(8), child: Text('Manage Issue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
        _menu('assign', Icons.person_add_alt_1_rounded, 'Assign employees', 'Add one or more company employees'),
        if (d.issue.assignees.isNotEmpty) _menu('reassign', Icons.swap_horiz_rounded, 'Reassign', 'Move an assignment to another employee'),
        _menu('status', Icons.published_with_changes_rounded, 'Change status', 'Open, Working, On Hold, Resolved or Closed'),
        if (!['resolved', 'closed'].contains(d.issue.status.toLowerCase())) _menu('resolve', Icons.task_alt_rounded, 'Resolve directly', 'Add resolution and mark resolved'),
        if (d.issue.status.toLowerCase() == 'resolved') _menu('close', Icons.lock_outline_rounded, 'Close issue', 'Confirm and close the resolved issue'),
      ]))),
    );
    if (!mounted || action == null) return;
    if (action == 'assign') await _assign();
    if (action == 'reassign') await _reassign();
    if (action == 'status') await _changeStatus();
    if (action == 'resolve') {
      final t = await _textDialog('Resolve Issue', 'Resolution remark', 'Enter the final resolution.', 'Resolve');
      if (t != null) await _result(await _vm.resolveAsManager(t), 'Issue resolved');
    }
    if (action == 'close') await _result(await _vm.closeIssue(), 'Issue closed');
  }

  Widget _menu(String value, IconData icon, String title, String subtitle) => ListTile(
    onTap: () => Navigator.pop(context, value),
    leading: CircleAvatar(backgroundColor: const Color(0xFFEAF1FF), child: Icon(icon, color: _blue, size: 20)),
    title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5)),
    trailing: const Icon(Icons.chevron_right_rounded),
  );

  Future<void> _assign() async {
    await _vm.loadEmployees();
    if (!mounted) return;
    final selected = <String>{};
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => SafeArea(child: SizedBox(
        height: MediaQuery.of(ctx).size.height * .72,
        child: Column(children: [
          const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 8), child: Row(children: [Expanded(child: Text('Assign Employees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))])),
          Expanded(child: ListView.builder(itemCount: _vm.employees.length, itemBuilder: (_, i) {
            final e = _vm.employees[i];
            return CheckboxListTile(value: selected.contains(e.name), onChanged: (v) => setSheet(() => v == true ? selected.add(e.name) : selected.remove(e.name)), title: Text(e.employeeName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)), subtitle: Text([e.designation, e.department].whereType<String>().where((x) => x.isNotEmpty).join(' • '), style: const TextStyle(fontSize: 11.5)), controlAffinity: ListTileControlAffinity.leading);
          })),
          Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx, selected.toList()), child: Text('Assign ${selected.length} Employee${selected.length == 1 ? '' : 's'}')))),
        ]),
      ))),
    );
    if (result != null) await _result(await _vm.assignEmployees(result), 'Employees assigned');
  }

  Future<void> _reassign() async {
    await _vm.loadEmployees();
    if (!mounted) return;
    String? fromId;
    String? toId;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: const Text('Reassign Issue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: fromId, isExpanded: true, decoration: const InputDecoration(labelText: 'Current assignee'), items: _vm.details!.issue.assignees.map((e) => DropdownMenuItem(value: e.employeeId, child: Text(e.employeeName))).toList(), onChanged: (v) => setDialog(() => fromId = v)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: toId, isExpanded: true, decoration: const InputDecoration(labelText: 'New assignee'), items: _vm.employees.where((e) => e.name != fromId).map((e) => DropdownMenuItem(value: e.name, child: Text(e.employeeName))).toList(), onChanged: (v) => setDialog(() => toId = v)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: fromId == null || toId == null ? null : () => Navigator.pop(ctx, true), child: const Text('Reassign'))],
    )));
    if (ok == true) await _result(await _vm.reassign(fromId: fromId!, toId: toId!), 'Issue reassigned');
  }

  Future<void> _changeStatus() async {
    final selected = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: ['Open', 'Working', 'On Hold', 'Resolved', 'Closed'].map((s) => ListTile(title: Text(s), leading: Icon(Icons.circle, size: 13, color: _statusColor(s)), trailing: _vm.details!.issue.status == s ? const Icon(Icons.check_rounded, color: _blue) : null, onTap: () => Navigator.pop(ctx, s))).toList())));
    if (selected != null && selected != _vm.details!.issue.status) await _result(await _vm.updateStatus(selected), 'Status changed to $selected');
  }

  Future<String?> _textDialog(String title, String label, String hint, String action) async {
    final c = TextEditingController();

    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      content: TextField(controller: c, minLines: 4, maxLines: 7, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { if (c.text.trim().isNotEmpty) Navigator.pop(ctx, c.text.trim()); }, child: Text(action))],
    ));
    await Future.delayed(const Duration(milliseconds: 50));
    c.dispose();
    return value;
  }

  Future<void> _result(bool success, String message) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? message
              : (_vm.errorMessage ?? 'Action failed'),
        ),
        backgroundColor: success
            ? const Color(0xFF0E9F6E)
            : const Color(0xFFB42318),
      ),
    );

    if (success) {
      await _vm.load();
    }
  }

  Widget _section(String title, IconData icon, List<Widget> children, {Color tint = Colors.white, Color border = const Color(0xFFE5EAF3)}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16), border: Border.all(color: border), boxShadow: tint == Colors.white ? const [BoxShadow(color: Color(0x0A172033), blurRadius: 10, offset: Offset(0, 3))] : null),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: _blue, size: 18)), const SizedBox(width: 9), Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink))]), const SizedBox(height: 12), ..._separate(children)]),
  );

  List<Widget> _separate(List<Widget> items) { final out = <Widget>[]; for (var i = 0; i < items.length; i++) { out.add(items[i]); if (i < items.length - 1) out.add(const Divider(height: 17)); } return out; }
  Widget _row(IconData icon, String label, String value) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 17, color: const Color(0xFF64748B)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF263244)))]))]);
  Widget _assignee(IssueAssigneeModel e) => Row(children: [CircleAvatar(radius: 17, backgroundColor: const Color(0xFFEAF1FF), child: Text(_initials(e.employeeName), style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w800))), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.employeeName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)), if (e.designation?.isNotEmpty == true) Text(e.designation!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]))]);
  Widget _remark(IssueRemarkModel r) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const CircleAvatar(radius: 15, backgroundColor: Color(0xFFEAF1FF), child: Icon(Icons.chat_bubble_outline_rounded, color: _blue, size: 15)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(r.authorName ?? r.authorEmail ?? 'User', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))), Text(_date(r.creation), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))]), const SizedBox(height: 4), Text(_plain(r.content), style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF475569)))]))]);
  Widget _error() => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline_rounded, size: 50, color: Color(0xFFB6C2D4)), const SizedBox(height: 12), Text(_vm.errorMessage ?? 'Issue could not be loaded', textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton(onPressed: _vm.load, child: const Text('Retry'))])));
  Widget _errorBox(String text) => Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFFFFF1F1), borderRadius: BorderRadius.circular(11)), child: Row(children: [const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318), size: 19), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF8E2020))))]));
  ButtonStyle _buttonStyle(bool filled) => filled ? FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size(0, 49), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : OutlinedButton.styleFrom(foregroundColor: _blue, minimumSize: const Size(0, 49), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
  Color _statusColor(String value) => switch (value.toLowerCase()) { 'resolved' => const Color(0xFF0E9F6E), 'closed' => const Color(0xFF64748B), 'working' => const Color(0xFFF59E0B), 'on hold' => const Color(0xFF8B5CF6), _ => _blue };
  String _date(DateTime? date) { if (date == null) return 'Not available'; final d = date.toLocal(); String p(int n) => n.toString().padLeft(2, '0'); return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}:${p(d.minute)}'; }
  String _plain(String value) => value.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  String _initials(String value) { final p = value.trim().split(RegExp(r'\s+')); if (p.isEmpty || p.first.isEmpty) return '?'; return (p.first[0] + (p.length > 1 ? p.last[0] : '')).toUpperCase(); }
}
