import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/lead_model.dart';
import 'add_lead.dart';
import 'edit_lead_viewmodel.dart';

enum EditLeadOpenMode { details, edit, addEvent, events, addTask, tasks }

class EditLeadScreen extends StatefulWidget {
  final String leadName;
  final LeadModel? initialLead;
  final EditLeadOpenMode openMode;

  const EditLeadScreen({
    super.key,
    required this.leadName,
    this.initialLead,
    this.openMode = EditLeadOpenMode.details,
  });

  @override
  State<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends State<EditLeadScreen> {
  late final EditLeadViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _fields = LeadFormControllers();
  final _taskSearch = TextEditingController();
  final _eventSearch = TextEditingController();

  bool _editing = false;
  bool _dirty = false;
  bool _seeded = false;
  int _tab = 0;
  String _taskFilter = 'All';
  String _eventFilter = 'All';

  @override
  void initState() {
    super.initState();
    _editing = widget.openMode == EditLeadOpenMode.edit;
    _tab = widget.openMode == EditLeadOpenMode.tasks ||
        widget.openMode == EditLeadOpenMode.addTask
        ? 1
        : widget.openMode == EditLeadOpenMode.events ||
        widget.openMode == EditLeadOpenMode.addEvent
        ? 2
        : 0;
    _viewModel = EditLeadViewModel(
      leadName: widget.leadName,
      initialLead: widget.initialLead,
    )..addListener(_onChanged);
    _viewModel.initialise().then((_) {
      if (!mounted) return;
      _seedFields();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.openMode == EditLeadOpenMode.addTask) _showTaskForm();
        if (widget.openMode == EditLeadOpenMode.addEvent) _showEventForm();
      });
    });
  }

  void _onChanged() {
    if (!mounted) return;
    _seedFields();
    setState(() {});
  }

  void _seedFields() {
    final lead = _viewModel.lead;
    if (lead == null || _seeded) return;
    _fields.fill(lead);
    for (final controller in _fields.all) {
      controller.addListener(_markDirty);
    }
    _seeded = true;
  }

  void _markDirty() {
    if (_editing && !_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    _fields.dispose();
    _taskSearch.dispose();
    _eventSearch.dispose();
    super.dispose();
  }

  Future<bool> _canPop() async {
    if (!_editing || !_dirty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your lead changes have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _saveLead() async {
    if (!(_formKey.currentState?.validate() ?? false) || _viewModel.saving) {
      return;
    }
    final message = await _viewModel.updateLead(
      _fields.toLead(
        name: _viewModel.currentLeadId,
        company: _viewModel.lead?.company ?? '',
      ),
    );
    if (!mounted) return;
    if (message != null) {
      setState(() {
        _dirty = false;
        _editing = false;
      });
      _snack(message);
    } else {
      _snack(_viewModel.error ?? 'Unable to update lead.');
    }
  }

  Future<void> _launch(String value, String scheme) async {
    if (value.trim().isEmpty) return;
    final uri = Uri(scheme: scheme, path: value.trim());
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      _snack('Unable to open this action.');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAddMenu() async {
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddToLeadSheet(),
    );
    if (!mounted || choice == null) return;
    if (choice == _AddChoice.task) {
      setState(() => _tab = 1);
      await _showTaskForm();
    } else {
      setState(() => _tab = 2);
      await _showEventForm();
    }
  }

  Future<void> _showEventForm([LeadEventModel? event]) async {
    final value = await showModalBottomSheet<LeadEventModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventFormSheet(
        event: event,
        leadName: _viewModel.currentLeadId,
        categories: _viewModel.masterData.eventCategories,
      ),
    );
    if (value == null) return;
    final message = await _viewModel.saveEvent(value);
    if (!mounted) return;
    _snack(message ?? _viewModel.eventsError ?? 'Unable to save event.');
  }

  Future<void> _showTaskForm([LeadTaskModel? task]) async {
    final value = await showModalBottomSheet<LeadTaskModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskFormSheet(
        task: task,
        leadName: _viewModel.currentLeadId,
        assignees: _viewModel.taskAssignees,
        statuses: _viewModel.taskStatuses,
        priorities: _viewModel.taskPriorities,
      ),
    );
    if (value == null) return;
    final message = await _viewModel.saveTask(value);
    if (!mounted) return;
    _snack(message ?? _viewModel.tasksError ?? 'Unable to save task.');
  }

  Future<void> _deleteEvent(LeadEventModel event) async {
    if (!await _confirmDelete('event', event.subject)) return;
    final message = await _viewModel.deleteEvent(event.name);
    if (mounted) {
      _snack(message ?? _viewModel.eventsError ?? 'Unable to delete event.');
    }
  }

  Future<void> _deleteTask(LeadTaskModel task) async {
    if (!await _confirmDelete('task', task.taskDescription)) return;
    final message = await _viewModel.deleteTask(task.name);
    if (mounted) {
      _snack(message ?? _viewModel.tasksError ?? 'Unable to delete task.');
    }
  }

  Future<bool> _confirmDelete(String type, String label) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text('Delete “$label”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _canPop,
      child: Scaffold(
        backgroundColor: leadBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: Text(_editing ? 'Edit Lead' : 'Lead Details'),
          titleTextStyle: const TextStyle(
            color: leadInk,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          actions: [
            if (!_editing && _viewModel.lead != null)
              IconButton(
                tooltip: 'Edit lead',
                onPressed: () => setState(() {
                  _editing = true;
                  _dirty = false;
                }),
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: !_editing && _viewModel.lead != null
            ? FloatingActionButton(
          onPressed: _tab == 1
              ? _showTaskForm
              : _tab == 2
              ? _showEventForm
              : _showAddMenu,
          backgroundColor: leadBlue,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded),
        )
            : null,
        bottomNavigationBar: _editing ? _saveBar() : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.loading && _viewModel.lead == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.lead == null) {
      return _StateMessage(
        icon: Icons.person_search_outlined,
        title: 'Lead unavailable',
        message: _viewModel.error ?? 'Unable to load this lead.',
        action: _viewModel.refresh,
      );
    }
    if (_editing) return _editForm();
    final lead = _viewModel.lead!;
    return Column(
      children: [
        ColoredBox(
          color: Colors.white,
          child: Column(
            children: [
              _LeadSummary(
                lead: lead,
                onPhone: lead.primaryPhone.isEmpty
                    ? null
                    : () => _launch(lead.primaryPhone, 'tel'),
                onEmail: lead.emailId.isEmpty
                    ? null
                    : () => _launch(lead.emailId, 'mailto'),
              ),
              _LeadTabs(
                selected: _tab,
                taskCount: _viewModel.tasks.length,
                eventCount: _viewModel.events.length,
                onSelected: (value) => setState(() => _tab = value),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [_overview(lead), _tasks(), _events()],
          ),
        ),
      ],
    );
  }

  Widget _editForm() {
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (_viewModel.error != null) ...[
            LeadInlineError(message: _viewModel.error!),
            const SizedBox(height: 10),
          ],
          LeadFormFields(
            controllers: _fields,
            masterData: _viewModel.masterData,
            onChanged: _markDirty,
          ),
        ],
      ),
    );
  }

  Widget _saveBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: leadBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _viewModel.saving
                    ? null
                    : () => setState(() => _editing = false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _viewModel.saving ? null : _saveLead,
                child: _viewModel.saving
                    ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overview(LeadModel lead) {
    final rows = <(String, String)>[
      ('Company', lead.companyName),
      ('Contact person', lead.leadName),
      ('Mobile', lead.mobileNo),
      ('Phone', lead.phone),
      ('Email', lead.emailId),
      ('Status', lead.status),
      ('Source', lead.source),
      ('Territory', lead.territory),
      ('City', lead.city),
      ('State', lead.state),
      ('Created on', _date(lead.creation)),
    ].where((row) => row.$2.trim().isNotEmpty).toList();
    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 92),
        children: [
          _Surface(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Lead Information',
                        style: TextStyle(
                          color: leadInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _editing = true;
                        _dirty = false;
                      }),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                for (var index = 0; index < rows.length; index++)
                  _InfoRow(
                    label: rows[index].$1,
                    value: rows[index].$2,
                    divider: index != rows.length - 1,
                  ),
                if (lead.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes_rounded,
                                size: 17, color: leadBlue),
                            SizedBox(width: 7),
                            Text('Notes',
                                style: TextStyle(
                                    color: leadInk,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(lead.description,
                            style: const TextStyle(
                                color: leadInk, fontSize: 12.5, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tasks() {
    final query = _taskSearch.text.trim().toLowerCase();
    final tasks = _viewModel.tasks.where((task) {
      final matchesSearch = query.isEmpty ||
          task.taskDescription.toLowerCase().contains(query) ||
          _assigneeName(task.assignedTo).toLowerCase().contains(query);
      final matchesFilter = _taskFilter == 'All' ||
          (_taskFilter == 'Overdue' && task.isOverdue) ||
          (_taskFilter == 'Completed' && task.isCompleted) ||
          (_taskFilter == 'Open' && !task.isCompleted && !task.isCancelled);
      return matchesSearch && matchesFilter;
    }).toList();
    return RefreshIndicator(
      onRefresh: _viewModel.loadTasks,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Column(
                children: [
                  _SearchField(
                    controller: _taskSearch,
                    hint: 'Search tasks...',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  _FilterRow(
                    values: const ['All', 'Open', 'Completed', 'Overdue'],
                    selected: _taskFilter,
                    onSelected: (value) =>
                        setState(() => _taskFilter = value),
                  ),
                  if (_viewModel.tasksError != null) ...[
                    const SizedBox(height: 8),
                    LeadInlineError(message: _viewModel.tasksError!),
                  ],
                ],
              ),
            ),
          ),
          if (tasks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _InlineEmpty(
                icon: Icons.task_alt_rounded,
                title: 'No tasks found',
                message: 'Add a task or change the current filter.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == tasks.length - 1 ? 0 : 8,
                    ),
                    child: _TaskCard(
                      task: tasks[index],
                      assigneeName: _assigneeName(tasks[index].assignedTo),
                      onEdit: () => _showTaskForm(tasks[index]),
                      onDelete: () => _deleteTask(tasks[index]),
                    ),
                  ),
                  childCount: tasks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _assigneeName(String userId) {
    for (final assignee in _viewModel.taskAssignees) {
      if (assignee.userId == userId) return assignee.employeeName;
    }
    return userId;
  }

  Widget _events() {
    final query = _eventSearch.text.trim().toLowerCase();
    final events = _viewModel.events.where((event) {
      final matchesSearch = query.isEmpty ||
          event.subject.toLowerCase().contains(query) ||
          event.category.toLowerCase().contains(query);
      return matchesSearch &&
          (_eventFilter == 'All' || event.category == _eventFilter);
    }).toList();
    final categories = <String>{
      'All',
      ..._viewModel.masterData.eventCategories,
      ..._viewModel.events.map((event) => event.category).where((e) => e.isNotEmpty),
    }.toList();
    return RefreshIndicator(
      onRefresh: _viewModel.loadEvents,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Column(
                children: [
                  _SearchField(
                    controller: _eventSearch,
                    hint: 'Search events...',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  _FilterRow(
                    values: categories,
                    selected: _eventFilter,
                    onSelected: (value) =>
                        setState(() => _eventFilter = value),
                  ),
                  if (_viewModel.eventsError != null) ...[
                    const SizedBox(height: 8),
                    LeadInlineError(message: _viewModel.eventsError!),
                  ],
                ],
              ),
            ),
          ),
          if (events.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _InlineEmpty(
                icon: Icons.event_available_outlined,
                title: 'No events found',
                message: 'Add an event or change the current filter.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == events.length - 1 ? 0 : 8,
                    ),
                    child: _EventCard(
                      event: events[index],
                      onEdit: () => _showEventForm(events[index]),
                      onDelete: () => _deleteEvent(events[index]),
                    ),
                  ),
                  childCount: events.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadSummary extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback? onPhone;
  final VoidCallback? onEmail;

  const _LeadSummary({required this.lead, this.onPhone, this.onEmail});

  @override
  Widget build(BuildContext context) {
    final title = lead.companyName.isNotEmpty ? lead.companyName : lead.leadName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF625BEF),
                child: Text(
                  title.isEmpty ? 'L' : title[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: leadInk,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(lead.name,
                        style: const TextStyle(color: leadMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              _StatusPill(label: lead.status),
            ],
          ),
          if (lead.primaryPhone.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ContactLine(
                icon: Icons.phone_outlined,
                text: lead.primaryPhone,
                onTap: onPhone),
          ],
          if (lead.emailId.isNotEmpty)
            _ContactLine(
                icon: Icons.email_outlined, text: lead.emailId, onTap: onEmail),
          if (lead.location.isNotEmpty)
            _ContactLine(icon: Icons.location_on_outlined, text: lead.location),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _ContactLine({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 17, color: leadMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: leadInk, fontSize: 12.5)),
          ),
        ],
      ),
    ),
  );
}

class _LeadTabs extends StatelessWidget {
  final int selected;
  final int taskCount;
  final int eventCount;
  final ValueChanged<int> onSelected;
  const _LeadTabs({
    required this.selected,
    required this.taskCount,
    required this.eventCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['Overview', 'Tasks ($taskCount)', 'Events ($eventCount)'];
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = selected == index;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? leadBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? const [
                    BoxShadow(
                        color: Color(0x332168F3),
                        blurRadius: 8,
                        offset: Offset(0, 3)),
                  ]
                      : null,
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: active ? Colors.white : leadMuted,
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;
  const _Surface({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: leadBorder),
    ),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool divider;
  const _InfoRow({required this.label, required this.value, required this.divider});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(
      border: divider
          ? const Border(bottom: BorderSide(color: Color(0xFFEDF0F5)))
          : null,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label,
              style: const TextStyle(color: leadMuted, fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: leadInk, fontSize: 12.5)),
        ),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField(
      {required this.controller, required this.hint, required this.onChanged});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: leadMuted, fontSize: 12.5),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: leadBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: leadBorder),
        ),
      ),
    ),
  );
}

class _FilterRow extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;
  const _FilterRow(
      {required this.values, required this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(width: 7),
      itemBuilder: (_, index) {
        final value = values[index];
        final active = value == selected;
        return ChoiceChip(
          selected: active,
          onSelected: (_) => onSelected(value),
          label: Text(value),
          labelStyle: TextStyle(
            color: active ? leadBlue : leadInk,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          selectedColor: const Color(0xFFEDF4FF),
          backgroundColor: Colors.white,
          side: BorderSide(color: active ? leadBlue : leadBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    ),
  );
}

class _TaskCard extends StatelessWidget {
  final LeadTaskModel task;
  final String assigneeName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TaskCard(
      {required this.task,
        required this.assigneeName,
        required this.onEdit,
        required this.onDelete});

  @override
  Widget build(BuildContext context) => _Surface(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          task.isCompleted
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: task.isCompleted ? const Color(0xFF19A66A) : leadMuted,
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(task.taskDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: leadInk,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700)),
                  ),
                  _StatusPill(label: task.status),
                ],
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 12,
                runSpacing: 5,
                children: [
                  if (task.dueDate != null)
                    _Meta(icon: Icons.calendar_today_outlined, text: _date(task.dueDate)),
                  if (assigneeName.isNotEmpty)
                    _Meta(icon: Icons.person_outline_rounded, text: assigneeName),
                  if (task.priority.isNotEmpty)
                    _Meta(icon: Icons.flag_outlined, text: task.priority),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          iconSize: 19,
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit task')),
            PopupMenuItem(value: 'delete', child: Text('Delete task')),
          ],
        ),
      ],
    ),
  );
}

class _EventCard extends StatelessWidget {
  final LeadEventModel event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _EventCard(
      {required this.event, required this.onEdit, required this.onDelete});
  @override
  Widget build(BuildContext context) => _Surface(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.event_rounded,
              color: Color(0xFF625BEF), size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(event.subject,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: leadInk,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700)),
                  ),
                  _StatusPill(label: event.category),
                ],
              ),
              if (event.startsOn != null) ...[
                const SizedBox(height: 7),
                _Meta(
                    icon: Icons.calendar_today_outlined,
                    text: _dateTime(event.startsOn)),
              ],
            ],
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          iconSize: 19,
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit event')),
            PopupMenuItem(value: 'delete', child: Text('Delete event')),
          ],
        ),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: leadMuted),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: leadMuted, fontSize: 11.5)),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});
  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final positive = normalized.contains('open') ||
        normalized.contains('complete') ||
        normalized.contains('meeting');
    final color = positive ? const Color(0xFF159A62) : leadBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label.isEmpty ? 'Open' : label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

enum _AddChoice { task, event }

class _AddToLeadSheet extends StatelessWidget {
  const _AddToLeadSheet();
  @override
  Widget build(BuildContext context) => _SheetShell(
    title: 'Add to Lead',
    child: Column(
      children: [
        _AddOption(
          icon: Icons.task_alt_rounded,
          title: 'Add Task',
          subtitle: 'Assign a follow-up directly to an employee',
          onTap: () => Navigator.pop(context, _AddChoice.task),
        ),
        const SizedBox(height: 10),
        _AddOption(
          icon: Icons.event_available_rounded,
          title: 'Add Event',
          subtitle: 'Schedule a meeting, call, or follow-up',
          onTap: () => Navigator.pop(context, _AddChoice.event),
        ),
      ],
    ),
  );
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AddOption(
      {required this.icon,
        required this.title,
        required this.subtitle,
        required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: leadBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: leadBlue, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: leadInk,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: leadMuted, fontSize: 11.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: leadMuted),
        ],
      ),
    ),
  );
}

class _TaskFormSheet extends StatefulWidget {
  final LeadTaskModel? task;
  final String leadName;
  final List<LeadTaskAssigneeModel> assignees;
  final List<String> statuses;
  final List<String> priorities;
  const _TaskFormSheet({
    this.task,
    required this.leadName,
    required this.assignees,
    required this.statuses,
    required this.priorities,
  });

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _description;
  late DateTime _dueDate;
  late String _priority;
  late String _status;
  late String _assignedTo;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _description = TextEditingController(text: task?.taskDescription ?? '');
    _dueDate = task?.dueDate ?? DateTime.now();
    _priority = task?.priority.isNotEmpty == true ? task!.priority : 'Medium';
    _status = task?.status.isNotEmpty == true ? task!.status : 'Open';
    _assignedTo = task?.assignedTo ?? '';
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) setState(() => _dueDate = value);
  }

  void _submit() {
    if (!(_key.currentState?.validate() ?? false)) return;
    final description = _description.text.trim();
    Navigator.pop(
      context,
      LeadTaskModel(
        name: widget.task?.name ?? '',
        leadId: widget.leadName,
        subject: description,
        description: description,
        status: _status,
        priority: _priority,
        dueDate: _dueDate,
        assignedTo: _assignedTo,
        owner: widget.task?.owner ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = <String>{'Open', ...widget.statuses, _status}.toList();
    final priorities = <String>{'Low', 'Medium', 'High', ...widget.priorities, _priority}.toList();
    return _SheetShell(
      title: widget.task == null ? 'Add Task' : 'Edit Task',
      child: Form(
        key: _key,
        child: Column(
          children: [
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 3,
              autofocus: widget.task == null,
              decoration: _input('Description *', Icons.notes_rounded),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Description is required.'
                  : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _assignedTo.isEmpty ? null : _assignedTo,
              isExpanded: true,
              decoration: _input('Assign to *', Icons.person_outline_rounded),
              items: widget.assignees
                  .map((item) => DropdownMenuItem(
                value: item.userId,
                child: Text(item.employeeName,
                    overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: (value) => setState(() => _assignedTo = value ?? ''),
              validator: (value) => value == null || value.isEmpty
                  ? 'Select an employee.'
                  : null,
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _input('Due date *', Icons.calendar_today_outlined),
                child: Text(_date(_dueDate)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: _input('Priority', Icons.flag_outlined),
                    items: priorities
                        .map((item) => DropdownMenuItem(
                        value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _priority = value ?? 'Medium'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _input('Status', Icons.check_circle_outline),
                    items: statuses
                        .map((item) => DropdownMenuItem(
                        value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _status = value ?? 'Open'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.task == null ? 'Create Task' : 'Save Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventFormSheet extends StatefulWidget {
  final LeadEventModel? event;
  final String leadName;
  final List<String> categories;
  const _EventFormSheet(
      {this.event, required this.leadName, required this.categories});
  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _subject;
  late DateTime _dateValue;
  late String _category;

  @override
  void initState() {
    super.initState();
    _subject = TextEditingController(text: widget.event?.subject ?? '');
    _dateValue = widget.event?.startsOn ?? DateTime.now();
    _category = widget.event?.category ?? '';
  }

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dateValue,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) setState(() => _dateValue = value);
  }

  void _submit() {
    if (!(_key.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      LeadEventModel(
        name: widget.event?.name ?? '',
        leadId: widget.leadName,
        subject: _subject.text.trim(),
        category: _category,
        startsOn: _dateValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{...widget.categories, if (_category.isNotEmpty) _category}.toList();
    return _SheetShell(
      title: widget.event == null ? 'Add Event' : 'Edit Event',
      child: Form(
        key: _key,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _category.isEmpty ? null : _category,
              isExpanded: true,
              decoration: _input('Category *', Icons.category_outlined),
              items: categories
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value ?? ''),
              validator: (value) =>
              value == null || value.isEmpty ? 'Select a category.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _subject,
              autofocus: widget.event == null,
              decoration: _input('Summary *', Icons.subject_rounded),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Summary is required.'
                  : null,
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _input('Event date *', Icons.calendar_today_outlined),
                child: Text(_date(_dateValue)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.event == null ? 'Create Event' : 'Save Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetShell({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 9, 18, 18),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DCE5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: leadInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: leadMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    ),
  );
}

class _InlineEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _InlineEmpty(
      {required this.icon, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: const Color(0xFFBCC7D8)),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  color: leadInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: leadMuted, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() action;
  const _StateMessage(
      {required this.icon,
        required this.title,
        required this.message,
        required this.action});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: leadMuted),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: leadInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: leadMuted, fontSize: 12.5)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: action,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _input(String label, IconData icon) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: leadMuted, fontSize: 12),
  prefixIcon: Icon(icon, size: 18, color: leadMuted),
  prefixIconConstraints: const BoxConstraints(minWidth: 42),
  isDense: true,
  filled: true,
  fillColor: const Color(0xFFF9FAFC),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: const BorderSide(color: leadBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: const BorderSide(color: leadBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: const BorderSide(color: leadBlue, width: 1.2),
  ),
);

String _date(DateTime? value) {
  if (value == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String _dateTime(DateTime? value) {
  if (value == null) return '';
  final hour = value.hour == 0 ? 12 : value.hour > 12 ? value.hour - 12 : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${_date(value)}, $hour:$minute $period';
}
