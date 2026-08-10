import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/issue_model.dart';
import 'company_issues_viewmodel.dart';
import 'issue_details_screen.dart';

const _blue = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _surface = Color(0xFFF4F7FC);

class CompanyIssuesScreen extends StatefulWidget {
  const CompanyIssuesScreen({super.key});

  @override
  State<CompanyIssuesScreen> createState() => _CompanyIssuesScreenState();
}

class _CompanyIssuesScreenState extends State<CompanyIssuesScreen> {
  late final CompanyIssuesViewModel _vm;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  bool _filtersOpen = false;

  @override
  void initState() {
    super.initState();
    _vm = CompanyIssuesViewModel()..addListener(_refresh);
    _scroll.addListener(_onScroll);
    _vm.initialize();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 250) {
      _vm.loadMore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _vm.removeListener(_refresh);
    _vm.dispose();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _surface,
    appBar: AppBar(
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 4,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Company Issues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Manager issue centre',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500,
                  color: Color(0xFFDCE8FF))),
        ],
      ),
      actions: [
        IconButton(
            onPressed: _vm.loading ? null : _vm.load,
            icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
    body: Column(children: [
      _summary(),
      _searchBar(),
      _filterPanel(),
      _activeFilters(),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
        child: Row(children: [
          const Text('All company issues',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('${_vm.total} record${_vm.total == 1 ? '' : 's'}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
        ]),
      ),
      Expanded(child: _content()),
    ]),
  );

  Widget _summary() => Container(
    width: double.infinity,
    color: _blue,
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_blue, _darkBlue]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33FFFFFF))),
      child: Row(children: [
        const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.corporate_fare_rounded, color: _blue)),
        const SizedBox(width: 11),
        const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manager Issue Centre',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('Monitor, open and manage company issues',
                      style: TextStyle(
                          color: Color(0xFFDCE8FF), fontSize: 11.5)),
                ])),
        Text('${_vm.total}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
      ]),
    ),
  );

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search ID, subject or employee',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                icon: const Icon(Icons.close_rounded, size: 19),
                onPressed: () {
                  _search.clear();
                  _vm.setSearch('');
                }),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
          onChanged: (value) {
            setState(() {});
            _debounce?.cancel();
            _debounce = Timer(
                const Duration(milliseconds: 450), () => _vm.setSearch(value));
          },
        ),
      ),
      const SizedBox(width: 8),
      Badge(
        isLabelVisible: _vm.hasFilters,
        child: IconButton.filledTonal(
          onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
          icon: Icon(_filtersOpen
              ? Icons.filter_alt_off_outlined
              : Icons.tune_rounded),
          tooltip: 'Filters',
        ),
      ),
    ]),
  );

  Widget _filterPanel() => AnimatedCrossFade(
    duration: const Duration(milliseconds: 180),
    crossFadeState: _filtersOpen
        ? CrossFadeState.showSecond
        : CrossFadeState.showFirst,
    firstChild: const SizedBox(height: 5),
    secondChild: Container(
      margin: const EdgeInsets.fromLTRB(12, 7, 12, 2),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFE5EAF3))),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: _dropdown('Status', _vm.status,
                  const ['All', 'Open', 'Working', 'On Hold', 'Resolved', 'Closed'],
                  _vm.setStatus)),
          const SizedBox(width: 9),
          Expanded(
              child: _dropdown('Priority', _vm.priority,
                  const ['All', 'Low', 'Medium', 'High'], _vm.setPriority)),
        ]),
        const SizedBox(height: 9),
        DropdownButtonFormField<String?>(
          value: _vm.issueType,
          isExpanded: true,
          decoration: _input('Issue Type'),
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('All Issue Types')),
            ..._vm.issueTypes.map((e) =>
                DropdownMenuItem<String?>(value: e, child: Text(e))),
          ],
          onChanged: _vm.setIssueType,
        ),
        if (_vm.hasFilters) ...[
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                onPressed: () {
                  _search.clear();
                  _vm.clearFilters();
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Clear filters')),
          ),
        ],
      ]),
    ),
  );

  Widget _activeFilters() {
    if (!_vm.hasFilters || _filtersOpen) return const SizedBox.shrink();
    final values = <String>[
      if (_vm.status != 'All') _vm.status,
      if (_vm.priority != 'All') '${_vm.priority} priority',
      if (_vm.issueType != null) _vm.issueType!,
      if (_vm.search.isNotEmpty) '“${_vm.search}”',
    ];
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 3),
        children: [
          ...values.map((value) => Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(value, style: const TextStyle(color: _blue,
                fontSize: 10.5, fontWeight: FontWeight.w700)),
          )),
          InkWell(
            onTap: () { _search.clear(); _vm.clearFilters(); },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Text('Clear', style: TextStyle(color: Color(0xFFB42318),
                  fontSize: 10.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      Future<void> Function(String) changed) =>
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: _input(label),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (value) {
          if (value != null) changed(value);
        },
      );

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF8FAFD),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
  );

  Widget _content() {
    if (_vm.loading && _vm.issues.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (_vm.errorMessage != null && _vm.issues.isEmpty) {
      return _state(Icons.lock_outline_rounded, 'Company issues unavailable',
          _vm.errorMessage!, _vm.initialize);
    }
    if (_vm.issues.isEmpty) {
      return _state(Icons.inbox_outlined, 'No matching issues',
          'Try changing or clearing the active filters.', _vm.clearFilters);
    }
    return RefreshIndicator(
      onRefresh: _vm.load,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 18),
        itemCount: _vm.issues.length + (_vm.loadingMore ? 1 : 0),
        itemBuilder: (_, index) => index == _vm.issues.length
            ? const Padding(
            padding: EdgeInsets.all(14),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : _card(_vm.issues[index]),
      ),
    );
  }

  Widget _card(IssueModel issue) {
    final color = _statusColor(issue.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE5EAF3))),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => IssueDetailsScreen(issueName: issue.name)));
          await _vm.load();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 4,
                  height: 35,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 9),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(issue.subject,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF172033))),
                        const SizedBox(height: 2),
                        Text(issue.name,
                            style: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF64748B))),
                      ])),
              _badge(issue.status, color),
            ]),
            const SizedBox(height: 9),
            Wrap(spacing: 12, runSpacing: 6, children: [
              _meta(Icons.flag_outlined, '${issue.priority} priority',
                  _priorityColor(issue.priority)),
              if (issue.issueType?.isNotEmpty == true)
                _meta(Icons.category_outlined, issue.issueType!,
                    const Color(0xFF64748B)),
              if (issue.createdByName?.isNotEmpty == true)
                _meta(Icons.person_outline_rounded, issue.createdByName!,
                    const Color(0xFF64748B)),
            ]),
            const SizedBox(height: 9),
            const Divider(height: 1, color: Color(0xFFEEF2F7)),
            const SizedBox(height: 8),
            const Row(children: [
              Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 4),
              Text('Open issue details', style: TextStyle(fontSize: 10.5,
                  color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _blue),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(.10), borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w800, color: color)));

  Widget _meta(IconData icon, String text, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
      ]);

  Widget _state(IconData icon, String title, String message,
      Future<void> Function() action) =>
      Center(
          child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 50, color: const Color(0xFFB6C2D4)),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: action, child: const Text('Try Again')),
              ])));

  Color _statusColor(String value) => switch (value.toLowerCase()) {
    'resolved' => const Color(0xFF0E9F6E),
    'closed' => const Color(0xFF64748B),
    'working' => const Color(0xFFF59E0B),
    'on hold' => const Color(0xFF8B5CF6),
    _ => _blue,
  };

  Color _priorityColor(String value) => value.toLowerCase() == 'high'
      ? const Color(0xFFDC3545)
      : value.toLowerCase() == 'low'
      ? const Color(0xFF0E9F6E)
      : const Color(0xFFF59E0B);
}
