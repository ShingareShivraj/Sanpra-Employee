import 'package:flutter/material.dart';

import '../../model/lead_model.dart';
import 'add_lead.dart';
import 'edit_lead.dart';
import 'list_lead_viewmodel.dart';

class ListLeadScreen extends StatefulWidget {
  const ListLeadScreen({super.key});

  @override
  State<ListLeadScreen> createState() => _ListLeadScreenState();
}

class _ListLeadScreenState extends State<ListLeadScreen> {
  late final ListLeadViewModel _viewModel;
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ListLeadViewModel()..addListener(_changed);
    _scroll.addListener(_onScroll);
    _viewModel.initialise();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 280) _viewModel.loadMore();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_changed);
    _viewModel.dispose();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddLeadScreen()),
    );
    if (changed == true) _viewModel.refresh();
  }

  Future<void> _openLead(LeadModel lead, EditLeadOpenMode mode) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditLeadScreen(
          leadName: lead.name,
          initialLead: lead,
          openMode: mode,
        ),
      ),
    );
    if (changed == true) _viewModel.refresh();
  }

  Future<void> _delete(LeadModel lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete lead?'),
        content: Text('Delete ${lead.leadName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final message = await _viewModel.deleteLead(lead.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? _viewModel.error ?? 'Unable to delete lead.')),
    );
  }

  Future<void> _showFilters() async {
    var status = _viewModel.status;
    var territory = _viewModel.territory;

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

          return Container(
            margin: const EdgeInsets.only(top: 70),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0D5DD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.tune_rounded, color: leadBlue),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter leads',
                                style: TextStyle(
                                  color: leadInk,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Narrow down your leads quickly',
                                style: TextStyle(color: leadMuted, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: leadMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'STATUS',
                      style: TextStyle(
                        color: leadMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FilterSelectField(
                      icon: Icons.flag_outlined,
                      label: 'Status',
                      value: status,
                      hint: 'All statuses',
                      onTap: () async {
                        final selected = await _openFilterSelector(
                          title: 'Select status',
                          values: _viewModel.masterData.statuses,
                          selected: status,
                        );
                        if (selected != null) {
                          setSheetState(() => status = selected);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'TERRITORY',
                      style: TextStyle(
                        color: leadMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FilterSelectField(
                      icon: Icons.public_rounded,
                      label: 'Territory',
                      value: territory,
                      hint: 'All territories',
                      onTap: () async {
                        final selected = await _openFilterSelector(
                          title: 'Select territory',
                          values: _viewModel.masterData.territories,
                          selected: territory,
                        );
                        if (selected != null) {
                          setSheetState(() => territory = selected);
                        }
                      },
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context, ['', '']),
                            icon: const Icon(Icons.restart_alt_rounded, size: 18),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: leadInk,
                              side: const BorderSide(color: leadBorder),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context, [status, territory]),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Apply filters'),
                            style: FilledButton.styleFrom(
                              backgroundColor: leadBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result != null) {
      await _viewModel.applyFilters(status: result[0], territory: result[1]);
    }
  }

  Future<String?> _openFilterSelector({
    required String title,
    required List<String> values,
    required String selected,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSearchSheet(
        title: title,
        values: values,
        selected: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: leadBackground,
      appBar: AppBar(
        title: const Text('Leads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: leadInk,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _viewModel.refreshing ? null : _viewModel.refresh,
            tooltip: 'Refresh',
            icon: _viewModel.refreshing
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: leadBlue))
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: leadBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Lead', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: _viewModel.updateSearch,
                style: const TextStyle(color: leadInk, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search name, company, mobile or email',
                  hintStyle: const TextStyle(color: leadMuted, fontSize: 11.5),
                  prefixIcon: const Icon(Icons.search_rounded, size: 19, color: leadMuted),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      _viewModel.updateSearch('');
                      setState(() {});
                    },
                  ),
                  filled: true,
                  fillColor: leadBackground,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Badge(
              isLabelVisible: _viewModel.hasFilters,
              child: Container(
                decoration: BoxDecoration(
                  color: _viewModel.hasFilters ? const Color(0xFFEAF1FF) : leadBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _showFilters,
                  tooltip: 'Filters',
                  icon: Icon(Icons.tune_rounded, color: _viewModel.hasFilters ? leadBlue : leadMuted, size: 20),
                ),
              ),
            ),
          ]),
        ),
        if (_viewModel.refreshing) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _body() {
    if (_viewModel.loading) return const Center(child: CircularProgressIndicator(color: leadBlue));
    if (_viewModel.error != null && _viewModel.leads.isEmpty) {
      return _StateView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load leads',
        message: _viewModel.error!,
        action: _viewModel.refresh,
      );
    }
    if (_viewModel.leads.isEmpty) {
      return _StateView(
        icon: Icons.person_search_rounded,
        title: _viewModel.search.isNotEmpty || _viewModel.hasFilters ? 'No matching leads' : 'No leads yet',
        message: _viewModel.search.isNotEmpty || _viewModel.hasFilters
            ? 'Try another search or clear the filters.'
            : 'Create your first lead to begin tracking opportunities.',
        action: _viewModel.search.isNotEmpty || _viewModel.hasFilters ? _viewModel.clearFilters : _openAdd,
        actionLabel: _viewModel.search.isNotEmpty || _viewModel.hasFilters ? 'Clear filters' : 'Add Lead',
      );
    }
    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
        itemCount: _viewModel.leads.length + (_viewModel.loadingMore ? 1 : 0) + (_viewModel.error != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (_viewModel.error != null && index == 0) {
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: LeadInlineError(message: _viewModel.error!));
          }
          final offset = _viewModel.error != null ? 1 : 0;
          final leadIndex = index - offset;
          if (leadIndex >= _viewModel.leads.length) {
            return const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: leadBlue)));
          }
          return _LeadCard(
            lead: _viewModel.leads[leadIndex],
            onTap: () => _openLead(
              _viewModel.leads[leadIndex],
              EditLeadOpenMode.details,
            ),
            onDelete: () => _delete(_viewModel.leads[leadIndex]),
          );
        },
      ),
    );
  }
}

class _LeadCard extends StatefulWidget {
  final LeadModel lead;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LeadCard({
    required this.lead,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends State<_LeadCard> {
  bool _showDelete = false;

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        onLongPress: () => setState(() => _showDelete = !_showDelete),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showDelete ? const Color(0xFFFECACA) : leadBorder,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFEAF1FF),
                    foregroundColor: leadNavy,
                    child: Text(
                      lead.leadName.isEmpty
                          ? '?'
                          : lead.leadName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.leadName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: leadInk,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (lead.companyName.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            lead.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: leadMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_showDelete)
                    IconButton(
                      tooltip: 'Delete lead',
                      onPressed: widget.onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 22,
                      ),
                    )
                  else
                    _StatusChip(lead.status),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 7,
                children: [
                  if (lead.mobileNo.isNotEmpty)
                    _Meta(Icons.smartphone_rounded, lead.mobileNo),
                  if (lead.phone.isNotEmpty)
                    _Meta(Icons.phone_outlined, lead.phone),
                  if (lead.emailId.isNotEmpty)
                    _Meta(Icons.email_outlined, lead.emailId),
                  if (lead.location.isNotEmpty)
                    _Meta(Icons.location_on_outlined, lead.location),
                  if (lead.territory.isNotEmpty)
                    _Meta(Icons.public_rounded, lead.territory),
                ],
              ),
              if (_showDelete) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 14, color: leadMuted),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text(
                        'Delete icon is visible. Tap it to delete this lead.',
                        style: TextStyle(fontSize: 10.5, color: leadMuted),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showDelete = false),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSelectField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;

  const _FilterSelectField({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: leadBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: hasValue ? leadBlue : leadMuted),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: leadMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasValue ? value : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasValue ? leadInk : leadMuted,
                      fontSize: 12.5,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: leadMuted),
          ],
        ),
      ),
    );
  }
}

class _FilterSearchSheet extends StatefulWidget {
  final String title;
  final List<String> values;
  final String selected;

  const _FilterSearchSheet({
    required this.title,
    required this.values,
    required this.selected,
  });

  @override
  State<_FilterSearchSheet> createState() => _FilterSearchSheetState();
}

class _FilterSearchSheetState extends State<_FilterSearchSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.values
        .where((value) => value.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D5DD),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: leadInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: leadMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search_rounded, color: leadMuted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                  filled: true,
                  fillColor: leadBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.all_inclusive_rounded, color: leadBlue),
              title: const Text(
                'All',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              trailing: widget.selected.isEmpty
                  ? const Icon(Icons.check_circle_rounded, color: leadBlue)
                  : null,
              onTap: () => Navigator.pop(context, ''),
            ),
            const Divider(height: 1, color: leadBorder),
            Flexible(
              child: filtered.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'No results found',
                  style: TextStyle(color: leadMuted, fontSize: 12),
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: leadBorder),
                itemBuilder: (context, index) {
                  final value = filtered[index];
                  final selected = value == widget.selected;

                  return ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(
                      value,
                      style: TextStyle(
                        color: selected ? leadBlue : leadInk,
                        fontSize: 12.5,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                      Icons.check_circle_rounded,
                      color: leadBlue,
                    )
                        : const Icon(
                      Icons.chevron_right_rounded,
                      color: leadMuted,
                    ),
                    onTap: () => Navigator.pop(context, value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon; final String text;
  const _Meta(this.icon, this.text);
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: leadMuted), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 10.5, color: leadMuted))]);
}

class _StatusChip extends StatelessWidget {
  final String status; const _StatusChip(this.status);
  @override Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();
    return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(20)), child: Text(status, style: const TextStyle(fontSize: 9.5, color: leadBlue, fontWeight: FontWeight.w700)));
  }
}

class _StateView extends StatelessWidget {
  final IconData icon; final String title; final String message; final VoidCallback action; final String actionLabel;
  const _StateView({required this.icon, required this.title, required this.message, required this.action, this.actionLabel = 'Retry'});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 43, color: const Color(0xFF98A2B3)), const SizedBox(height: 10), Text(title, style: const TextStyle(color: leadInk, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: leadMuted, fontSize: 11)), const SizedBox(height: 14), OutlinedButton(onPressed: action, child: Text(actionLabel))])));
}
