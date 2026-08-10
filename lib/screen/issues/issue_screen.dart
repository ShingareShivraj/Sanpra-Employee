import 'dart:async';
import 'package:flutter/material.dart';

import '../../model/issue_model.dart';
import 'issue_details_screen.dart';
import 'issue_viewmodel.dart';
import 'raise_issue_screen.dart';

const _blue = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _ink = Color(0xFF172033);

class IssueScreen extends StatefulWidget {
  const IssueScreen({super.key});
  @override
  State<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<IssueScreen> {
  late final IssueViewModel _vm;
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _vm = IssueViewModel()..addListener(_changed);
    _scroll.addListener(_onScroll);
    _vm.initialize();
  }

  void _changed() { if (mounted) setState(() {}); }
  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) _vm.loadMore();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _vm.removeListener(_changed);
    _vm.dispose();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _raise() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const RaiseIssueScreen()));
    if (result != null) await _vm.load();
  }

  Future<void> _open(IssueModel issue) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => IssueDetailsScreen(issueName: issue.name)));
    await _vm.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FC),
    appBar: AppBar(
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Issue Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text('Raise, track and resolve issues', style: TextStyle(fontSize: 10.5, color: Color(0xFFDCE8FF), fontWeight: FontWeight.w500)),
      ]),
      actions: [IconButton(tooltip: 'Refresh', onPressed: _vm.loading ? null : _vm.load, icon: const Icon(Icons.refresh_rounded))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _raise,
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Raise Issue', style: TextStyle(fontWeight: FontWeight.w700)),
    ),
    body: Column(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_blue, _darkBlue]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 15),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(13)),
            child: Row(children: [
              _scope('Raised', IssueListScope.mine, Icons.outbox_outlined),
              const SizedBox(width: 5),
              _scope('Assigned', IssueListScope.assigned, Icons.assignment_ind_outlined),
              if (_vm.isManager) ...[const SizedBox(width: 5), _scope('Company', IssueListScope.company, Icons.corporate_fare_rounded)],
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 7),
        child: Column(children: [
          if (_vm.scope == IssueListScope.company) ...[
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search issue ID, subject or employee',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded, size: 19), onPressed: () { _search.clear(); _vm.setSearch(''); }),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
              onChanged: (value) {
                setState(() {});
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 450), () => _vm.setSearch(value));
              },
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Open', 'Working', 'Resolved', 'Closed', 'All'].map((status) {
                final selected = _vm.status == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: selected,
                    onSelected: (_) => _vm.setStatus(status),
                    selectedColor: _blue,
                    labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    side: BorderSide(color: selected ? _blue : const Color(0xFFDCE2EC)),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 5, 14, 8),
        child: Row(children: [
          Text(_heading(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
          const Spacer(),
          Text('${_vm.total} issue${_vm.total == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
      ),
      Expanded(child: _content()),
    ]),
  );

  Widget _scope(String label, IssueListScope scope, IconData icon) {
    final selected = _vm.scope == scope;
    return Expanded(child: InkWell(
      onTap: () => _vm.setScope(scope),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 39,
        decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 17, color: selected ? _blue : Colors.white),
          const SizedBox(width: 5),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? _blue : Colors.white))),
        ]),
      ),
    ));
  }

  Widget _content() {
    if (_vm.loading && _vm.issues.isEmpty) return const Center(child: CircularProgressIndicator(color: _blue));
    if (_vm.errorMessage != null && _vm.issues.isEmpty) return _state(Icons.cloud_off_rounded, 'Could not load issues', _vm.errorMessage!, 'Retry', _vm.load);
    if (_vm.issues.isEmpty) return _state(Icons.task_alt_rounded, 'No issues here', 'There are no ${_vm.status.toLowerCase()} issues in this section.', null, null);
    return RefreshIndicator(
      onRefresh: _vm.load,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 90),
        itemCount: _vm.issues.length + (_vm.loadingMore ? 1 : 0),
        itemBuilder: (_, index) => index == _vm.issues.length
            ? const Padding(padding: EdgeInsets.all(14), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : _issueCard(_vm.issues[index]),
      ),
    );
  }

  Widget _issueCard(IssueModel issue) {
    final color = _statusColor(issue.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shadowColor: const Color(0x14123FA0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5EAF3))),
      child: InkWell(
        onTap: () => _open(issue),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 4, height: 34, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(issue.subject, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.25, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 2),
                Text(issue.name, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ])),
              const SizedBox(width: 8),
              _badge(issue.status, color),
            ]),
            const SizedBox(height: 11),
            Row(children: [
              _meta(Icons.flag_outlined, issue.priority, _priorityColor(issue.priority)),
              if (issue.issueType?.isNotEmpty == true) ...[const SizedBox(width: 12), Expanded(child: _meta(Icons.category_outlined, issue.issueType!, const Color(0xFF64748B)))],
              const Spacer(),
              Container(width: 26, height: 26, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B))),
            ]),
            if (issue.createdByName?.isNotEmpty == true) ...[
              const Divider(height: 17),
              _meta(Icons.person_outline_rounded, 'Raised by ${issue.createdByName}', const Color(0xFF64748B)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)));
  Widget _meta(IconData icon, String text, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: color), const SizedBox(width: 4), Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)))]);

  Widget _state(IconData icon, String title, String message, String? action, VoidCallback? callback) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 52, color: const Color(0xFFB6C2D4)), const SizedBox(height: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))), if (action != null) ...[const SizedBox(height: 12), OutlinedButton(onPressed: callback, child: Text(action))]])));

  String _heading() => switch (_vm.scope) { IssueListScope.mine => 'Issues raised by me', IssueListScope.assigned => 'Assigned to me', IssueListScope.company => 'Company issues' };
  Color _statusColor(String value) => switch (value.toLowerCase()) { 'resolved' => const Color(0xFF0E9F6E), 'closed' => const Color(0xFF64748B), 'working' => const Color(0xFFF59E0B), 'on hold' => const Color(0xFF8B5CF6), _ => _blue };
  Color _priorityColor(String value) => value.toLowerCase() == 'high' ? const Color(0xFFDC3545) : value.toLowerCase() == 'low' ? const Color(0xFF0E9F6E) : const Color(0xFFF59E0B);
}
