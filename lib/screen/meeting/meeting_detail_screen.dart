import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/meeting/meeting_action_item_model.dart';
import '../../model/meeting/meeting_model.dart';
import '../../model/meeting/meeting_participant_model.dart';
import 'meeting_detail_viewmodel.dart';
import 'meeting_form_screen.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE5EAF1);

class MeetingDetailScreen extends StatefulWidget {
  final String meetingName;
  final MeetingModel? initialMeeting;

  const MeetingDetailScreen({
    super.key,
    required this.meetingName,
    this.initialMeeting,
  });

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  late final MeetingDetailViewModel _viewModel;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _viewModel = MeetingDetailViewModel(
      meetingName: widget.meetingName,
      initialMeeting: widget.initialMeeting,
    )..initialise();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _changed);
    return false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFD92D20),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _joinMeeting() async {
    final meeting = _viewModel.meeting;
    if (meeting == null || !meeting.canJoin) return;
    final uri = Uri.tryParse(meeting.meetingUrl);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _showError('Unable to open the meeting link.');
    }
  }

  Future<void> _editMeeting() async {
    final meeting = _viewModel.meeting;
    if (meeting == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MeetingFormScreen(meeting: meeting)),
    );
    if (changed == true) {
      _changed = true;
      await _viewModel.refresh();
    }
  }

  Future<void> _cancelMeeting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel meeting?'),
        content: const Text(
          'All participants will be notified that this meeting is cancelled.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD92D20)),
            child: const Text('Cancel Meeting'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await _viewModel.cancelMeeting();
    if (!mounted) return;
    if (success) {
      _changed = true;
      _showSuccess('Meeting cancelled.');
    } else if (_viewModel.error != null) {
      _showError(_viewModel.error!);
    }
  }

  Future<void> _editAttendance() async {
    final meeting = _viewModel.meeting;
    if (meeting == null) return;
    final values = {
      for (final participant in meeting.participants)
        participant.employee: participant.attendanceStatus,
    };
    final result = await showModalBottomSheet<Map<String, MeetingAttendanceStatus>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * .72,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const _SheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Meeting Attendance',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext, values),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: meeting.participants.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 52),
                    itemBuilder: (context, index) {
                      final participant = meeting.participants[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: CircleAvatar(
                          backgroundColor: _primary.withOpacity(.08),
                          foregroundColor: _primary,
                          child: Text(_initials(participant.employeeName)),
                        ),
                        title: Text(
                          participant.employeeName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          participant.designation ?? participant.department ?? '',
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        trailing: DropdownButton<MeetingAttendanceStatus>(
                          value: values[participant.employee],
                          underline: const SizedBox.shrink(),
                          items: MeetingAttendanceStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.apiValue, style: const TextStyle(fontSize: 11)),
                                ),
                              )
                              .toList(),
                          onChanged: (status) {
                            if (status != null) {
                              setSheetState(() => values[participant.employee] = status);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    final participants = meeting.participants
        .map(
          (participant) => participant.copyWith(
            attendanceStatus: result[participant.employee],
          ),
        )
        .toList();
    final success = await _viewModel.updateAttendance(participants);
    if (!mounted) return;
    if (success) {
      _changed = true;
      _showSuccess('Attendance updated.');
    } else if (_viewModel.error != null) {
      _showError(_viewModel.error!);
    }
  }

  Future<void> _editOutcome() async {
    final meeting = _viewModel.meeting;
    if (meeting == null) return;
    final outcome = TextEditingController(text: meeting.outcome);
    final decisions = TextEditingController(text: meeting.decisions);
    var completed = meeting.status.isCompleted;
    final result = await showModalBottomSheet<_OutcomeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Outcome & Decisions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          _OutcomeResult(outcome.text, decisions.text, completed),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: outcome,
                    minLines: 3,
                    maxLines: 6,
                    decoration: _dialogInput('Meeting outcome'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: decisions,
                    minLines: 3,
                    maxLines: 6,
                    decoration: _dialogInput('Key decisions'),
                  ),
                  CheckboxListTile(
                    value: completed,
                    onChanged: (value) => setSheetState(() => completed = value ?? false),
                    activeColor: _primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark meeting as completed', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    outcome.dispose();
    decisions.dispose();
    if (result == null) return;
    final success = await _viewModel.updateOutcome(
      outcome: result.outcome,
      decisions: result.decisions,
      markCompleted: result.completed,
    );
    if (!mounted) return;
    if (success) {
      _changed = true;
      _showSuccess('Meeting outcome updated.');
    } else if (_viewModel.error != null) {
      _showError(_viewModel.error!);
    }
  }

  Future<void> _showActionForm([MeetingActionItemModel? existing]) async {
    final action = TextEditingController(text: existing?.action ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    var assignedTo = existing?.assignedTo ??
        (_viewModel.companyEmployees.isNotEmpty
            ? _viewModel.companyEmployees.first.name
            : '');
    var dueDate = existing?.dueDate;
    var createTask = false;
    final result = await showModalBottomSheet<_ActionFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            existing == null ? 'Add Action Item' : 'Edit Action Item',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (action.text.trim().isEmpty || assignedTo.isEmpty) return;
                            Navigator.pop(
                              sheetContext,
                              _ActionFormResult(
                                action: action.text,
                                assignedTo: assignedTo,
                                dueDate: dueDate,
                                notes: notes.text,
                                createTask: createTask,
                              ),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: action,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _dialogInput('Action item *'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: assignedTo.isEmpty ? null : assignedTo,
                      isExpanded: true,
                      decoration: _dialogInput('Assign to *'),
                      items: _viewModel.companyEmployees
                          .map(
                            (employee) => DropdownMenuItem(
                              value: employee.name,
                              child: Text(employee.employeeName, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setSheetState(() => assignedTo = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) setSheetState(() => dueDate = picked);
                      },
                      child: InputDecorator(
                        decoration: _dialogInput('Due date'),
                        child: Text(dueDate == null ? 'No due date' : _formatDate(dueDate!)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notes,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _dialogInput('Notes'),
                    ),
                    if (existing == null)
                      SwitchListTile.adaptive(
                        value: createTask,
                        onChanged: (value) => setSheetState(() => createTask = value),
                        activeColor: _primary,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Create employee Task', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Also assign this through the existing Task system.', style: TextStyle(fontSize: 10.5)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    action.dispose();
    notes.dispose();
    if (result == null) return;
    final item = MeetingActionItemModel(
      rowName: existing?.rowName,
      action: result.action,
      assignedTo: result.assignedTo,
      dueDate: result.dueDate,
      status: existing?.status ?? MeetingActionItemStatus.pending,
      notes: result.notes,
      createTask: result.createTask,
    );
    final success = existing == null
        ? await _viewModel.addActionItem(item)
        : await _viewModel.updateActionItem(item);
    if (!mounted) return;
    if (success) {
      _changed = true;
      _showSuccess(existing == null ? 'Action item added.' : 'Action item updated.');
    } else if (_viewModel.error != null) {
      _showError(_viewModel.error!);
    }
  }

  Future<void> _createTask(MeetingActionItemModel item) async {
    if (item.rowName == null) return;
    final result = await _viewModel.createTask(item.rowName!);
    if (!mounted) return;
    if (result != null) {
      _showSuccess(result.alreadyCreated
          ? 'Task ${result.task ?? ''} already exists.'
          : 'Task ${result.task ?? ''} created and assigned.');
    } else if (_viewModel.error != null) {
      _showError(_viewModel.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final meeting = _viewModel.meeting;
          return Scaffold(
            backgroundColor: _background,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              foregroundColor: _ink,
              title: const Text('Meeting Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              actions: [
                if (_viewModel.canManage && meeting?.status.isScheduled == true)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editMeeting();
                      if (value == 'cancel') _cancelMeeting();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit meeting')),
                      PopupMenuItem(value: 'cancel', child: Text('Cancel meeting')),
                    ],
                  ),
              ],
            ),
            body: _body(),
            bottomNavigationBar: meeting?.canJoin == true
                ? SafeArea(
                    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      onPressed: _joinMeeting,
                      icon: const Icon(Icons.video_call_rounded),
                      label: Text('Join on ${meeting!.meetingPlatform.apiValue}'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_viewModel.loading && _viewModel.meeting == null) {
      return const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2));
    }
    final meeting = _viewModel.meeting;
    if (meeting == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_viewModel.error ?? 'Unable to load meeting.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _viewModel.initialise, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 14, 16, meeting.canJoin ? 24 : 90),
        children: [
          _HeroCard(meeting: meeting),
          if (_viewModel.error != null) ...[
            const SizedBox(height: 10),
            _InlineError(message: _viewModel.error!),
          ],
          const SizedBox(height: 14),
          _InfoCard(meeting: meeting),
          if (meeting.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            _TextSection(icon: Icons.notes_rounded, title: 'Description', text: meeting.description),
          ],
          if (meeting.hasAgenda) ...[
            const SizedBox(height: 14),
            _TextSection(icon: Icons.format_list_bulleted_rounded, title: 'Agenda', text: meeting.meetingAgenda),
          ],
          const SizedBox(height: 14),
          _SectionHeader(
            icon: Icons.people_outline_rounded,
            title: 'Participants (${meeting.participants.length})',
            action: _viewModel.canManage
                ? TextButton(onPressed: _editAttendance, child: const Text('Attendance'))
                : null,
          ),
          const SizedBox(height: 8),
          _ParticipantsCard(participants: meeting.participants),
          const SizedBox(height: 14),
          _SectionHeader(
            icon: Icons.fact_check_outlined,
            title: 'Outcome & Decisions',
            action: _viewModel.canManage
                ? TextButton(onPressed: _editOutcome, child: const Text('Update'))
                : null,
          ),
          const SizedBox(height: 8),
          _OutcomeCard(meeting: meeting),
          const SizedBox(height: 14),
          _SectionHeader(
            icon: Icons.task_alt_rounded,
            title: 'Action Items (${meeting.actionItems.length})',
            action: _viewModel.canManage
                ? TextButton.icon(
                    onPressed: () => _showActionForm(),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Add'),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          _ActionItemsCard(
            items: meeting.actionItems,
            canManage: _viewModel.canManage,
            onEdit: _showActionForm,
            onCreateTask: _createTask,
          ),
          if (_viewModel.actionLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: _primary, minHeight: 2),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.meeting});
  final MeetingModel meeting;
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(meeting.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_darkBlue, _primary]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _primary.withOpacity(.18), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: color == _primary ? Colors.white : color),
                    const SizedBox(width: 5),
                    Text(meeting.status.apiValue, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Spacer(),
              Text(meeting.name, style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 13),
          Text(meeting.meetingTitle, style: const TextStyle(color: Colors.white, fontSize: 19, height: 1.2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 15),
              const SizedBox(width: 6),
              Text(_formatDate(meeting.meetingDate), style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
              const SizedBox(width: 14),
              const Icon(Icons.schedule_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              Expanded(child: Text('${_shortTime(meeting.startTime)} – ${_shortTime(meeting.endTime)}', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.meeting});
  final MeetingModel meeting;
  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          children: [
            _InfoRow(icon: Icons.video_camera_front_outlined, label: 'Platform', value: meeting.meetingPlatform.apiValue),
            const Divider(height: 18),
            _InfoRow(icon: Icons.person_outline_rounded, label: 'Organizer', value: meeting.organizerName),
            const Divider(height: 18),
            _InfoRow(icon: Icons.business_outlined, label: 'Company', value: meeting.company),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: _primary.withOpacity(.07), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _primary, size: 17)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(width: 10),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      );
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          _SectionHeader(icon: icon, title: title),
          const SizedBox(height: 8),
          _Card(child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(color: _ink, fontSize: 12, height: 1.55)))),
        ],
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.action});
  final IconData icon;
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: _primary, size: 18),
          const SizedBox(width: 7),
          Expanded(child: Text(title, style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700))),
          if (action != null) action!,
        ],
      );
}

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({required this.participants});
  final List<MeetingParticipantModel> participants;
  @override
  Widget build(BuildContext context) => _Card(
        padding: EdgeInsets.zero,
        child: participants.isEmpty
            ? const Padding(padding: EdgeInsets.all(14), child: Text('No participants', style: TextStyle(color: _muted, fontSize: 12)))
            : Column(
                children: [
                  for (var index = 0; index < participants.length; index++) ...[
                    _ParticipantRow(participant: participants[index]),
                    if (index != participants.length - 1) const Divider(height: 1, indent: 58),
                  ],
                ],
              ),
      );
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant});
  final MeetingParticipantModel participant;
  @override
  Widget build(BuildContext context) {
    final color = switch (participant.attendanceStatus) {
      MeetingAttendanceStatus.attended => const Color(0xFF12B76A),
      MeetingAttendanceStatus.absent => const Color(0xFFD92D20),
      MeetingAttendanceStatus.invited => _primary,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: _primary.withOpacity(.08), foregroundColor: _primary, child: Text(_initials(participant.employeeName), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(participant.employeeName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)), if ((participant.designation ?? participant.department)?.isNotEmpty == true) Text(participant.designation ?? participant.department!, style: const TextStyle(color: _muted, fontSize: 10))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(20)), child: Text(participant.attendanceStatus.apiValue, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.meeting});
  final MeetingModel meeting;
  @override
  Widget build(BuildContext context) => _Card(
        child: !meeting.hasOutcome && !meeting.hasDecisions
            ? const Row(children: [Icon(Icons.hourglass_empty_rounded, color: _muted, size: 19), SizedBox(width: 8), Expanded(child: Text('Outcome and decisions will appear after the meeting.', style: TextStyle(color: _muted, fontSize: 11.5)))])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (meeting.hasOutcome) ...[const Text('OUTCOME', style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .7)), const SizedBox(height: 4), Text(meeting.outcome, style: const TextStyle(fontSize: 12, height: 1.5))], if (meeting.hasOutcome && meeting.hasDecisions) const Divider(height: 22), if (meeting.hasDecisions) ...[const Text('DECISIONS', style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .7)), const SizedBox(height: 4), Text(meeting.decisions, style: const TextStyle(fontSize: 12, height: 1.5))]]),
      );
}

class _ActionItemsCard extends StatelessWidget {
  const _ActionItemsCard({required this.items, required this.canManage, required this.onEdit, required this.onCreateTask});
  final List<MeetingActionItemModel> items;
  final bool canManage;
  final ValueChanged<MeetingActionItemModel> onEdit;
  final ValueChanged<MeetingActionItemModel> onCreateTask;
  @override
  Widget build(BuildContext context) => _Card(
        padding: EdgeInsets.zero,
        child: items.isEmpty
            ? const Padding(padding: EdgeInsets.all(14), child: Text('No action items added.', style: TextStyle(color: _muted, fontSize: 11.5)))
            : Column(children: [for (var index = 0; index < items.length; index++) ...[_ActionRow(item: items[index], canManage: canManage, onEdit: () => onEdit(items[index]), onCreateTask: () => onCreateTask(items[index])), if (index != items.length - 1) const Divider(height: 1, indent: 48)]]),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.item, required this.canManage, required this.onEdit, required this.onCreateTask});
  final MeetingActionItemModel item;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onCreateTask;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(item.status.isCompleted ? Icons.task_alt_rounded : Icons.radio_button_unchecked_rounded, size: 20, color: item.status.isCompleted ? const Color(0xFF12B76A) : _primary), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.action, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text('${item.assignedToName}${item.dueDate == null ? '' : ' · Due ${_formatDate(item.dueDate)}'}', style: const TextStyle(color: _muted, fontSize: 10.5))])), if (canManage) PopupMenuButton<String>(padding: EdgeInsets.zero, iconSize: 20, onSelected: (value) { if (value == 'edit') onEdit(); if (value == 'task') onCreateTask(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'task', child: Text('Create employee Task'))])]),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(13)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: padding, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border), boxShadow: [BoxShadow(color: const Color(0xFF344054).withOpacity(.04), blurRadius: 12, offset: const Offset(0, 4))]), child: child);
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(child: Container(width: 38, height: 4, margin: const EdgeInsets.only(top: 9, bottom: 13), decoration: BoxDecoration(color: const Color(0xFFD0D5DD), borderRadius: BorderRadius.circular(4))));
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFEF3F2), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.error_outline_rounded, color: Color(0xFFD92D20), size: 18), const SizedBox(width: 8), Expanded(child: Text(message, style: const TextStyle(fontSize: 11.5)))]));
}

class _OutcomeResult {
  const _OutcomeResult(this.outcome, this.decisions, this.completed);
  final String outcome;
  final String decisions;
  final bool completed;
}

class _ActionFormResult {
  const _ActionFormResult({required this.action, required this.assignedTo, required this.dueDate, required this.notes, required this.createTask});
  final String action;
  final String assignedTo;
  final DateTime? dueDate;
  final String notes;
  final bool createTask;
}

InputDecoration _dialogInput(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 12), filled: true, fillColor: const Color(0xFFF9FAFB), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary)));

Color _statusColor(MeetingStatus status) => switch (status) { MeetingStatus.scheduled => _primary, MeetingStatus.completed => const Color(0xFF12B76A), MeetingStatus.cancelled => const Color(0xFFD92D20) };

String _shortTime(String value) { final parts = value.split(':'); if (parts.length < 2) return value; var hour = int.tryParse(parts[0]) ?? 0; final suffix = hour >= 12 ? 'PM' : 'AM'; hour %= 12; if (hour == 0) hour = 12; return '$hour:${parts[1]} $suffix'; }

String _formatDate(DateTime? date) { if (date == null) return '--'; const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; return '${date.day} ${months[date.month - 1]} ${date.year}'; }

String _initials(String name) => name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).map((part) => part[0].toUpperCase()).join();
