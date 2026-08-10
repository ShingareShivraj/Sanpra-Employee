import 'package:flutter/material.dart';

import '../../../model/task_model.dart';
import 'submit_task_screen.dart';
import 'submit_task_viewmodel.dart';
import 'task_details_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _accent = Color(0xFF4E8CFF);
const _dark = Color(0xFF123FA0);
const _background = Color(0xFFF4F7FC);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({
    super.key,
    required this.taskName,
    this.photoUploader,
    this.locationProvider,
  });

  final String taskName;
  final TaskPhotoUploader? photoUploader;
  final TaskLocationProvider? locationProvider;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late final TaskDetailsViewModel viewModel;
  bool changed = false;

  @override
  void initState() {
    super.initState();
    viewModel = TaskDetailsViewModel(taskName: widget.taskName)..loadDetails();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!await viewModel.startTask()) return;
    changed = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task started. You can now submit your work.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubmitTaskScreen(
          taskName: widget.taskName,
          photoUploader: widget.photoUploader,
          locationProvider: widget.locationProvider,
        ),
      ),
    );
    if (result == true) {
      changed = true;
      await viewModel.loadDetails();
    }
  }

  Future<void> _refresh() => viewModel.loadDetails();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(changed);
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          titleSpacing: 0,
          title: const Text(
            'Task Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 22),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            if (viewModel.loading && viewModel.task == null) {
              return const _LoadingView();
            }
            if (viewModel.task == null) {
              return _ErrorView(
                message: viewModel.errorMessage ?? 'Task details could not be loaded.',
                onRetry: _refresh,
              );
            }
            return _content(viewModel.task!);
          },
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            final task = viewModel.task;
            if (task == null ||
                (!viewModel.canStart && !viewModel.canSubmitCompletion)) {
              return const SizedBox.shrink();
            }
            return _BottomAction(
              isStarting: viewModel.starting,
              canStart: viewModel.canStart,
              onPressed: viewModel.canStart ? _start : _submit,
            );
          },
        ),
      ),
    );
  }

  Widget _content(TaskModel task) {
    return RefreshIndicator(
      color: _primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          14,
          12,
          14,
          (viewModel.canStart || viewModel.canSubmitCompletion) ? 100 : 28,
        ),
        children: [
          _TaskHero(task: task),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Task information',
            icon: Icons.assignment_outlined,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.tag_rounded,
                  label: 'Task ID',
                  value: task.name,
                ),
                _InfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Priority',
                  value: task.priority.isEmpty ? 'Normal' : task.priority,
                  valueColor: _priorityColor(task.priority),
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Due date',
                  value: _date(task.dueDate),
                ),
                _InfoRow(
                  icon: Icons.folder_outlined,
                  label: 'Project',
                  value: _valueOrDash(task.project),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Description',
            icon: Icons.notes_rounded,
            child: Text(
              task.description.trim().isEmpty
                  ? 'No description provided.'
                  : task.description.trim(),
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          if (_hasText(task.reviewRemarks) &&
              task.status.toLowerCase() == 'working') ...[
            const SizedBox(height: 10),
            _ReturnedCard(
              reviewer: _valueOrDash(task.reviewedBy),
              reason: task.reviewRemarks!.trim(),
              reviewedAt: _dateTime(task.reviewTime),
            ),
          ],
          if (_hasText(task.completionRemarks)) ...[
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Completion submission',
              icon: Icons.task_alt_rounded,
              accentColor: const Color(0xFF12A06A),
              child: Text(
                task.completionRemarks!.trim(),
                style: const TextStyle(
                  color: Color(0xFF475467),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ],
          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: 10),
            _InlineError(message: viewModel.errorMessage!),
          ],
          if (task.status.toLowerCase() == 'pending review') ...[
            const SizedBox(height: 10),
            const _StateNotice(
              icon: Icons.hourglass_top_rounded,
              color: Color(0xFFB7791F),
              title: 'Waiting for manager review',
              message: 'Your work has been submitted. No action is needed now.',
            ),
          ] else if (task.status.toLowerCase() == 'completed') ...[
            const SizedBox(height: 10),
            const _StateNotice(
              icon: Icons.verified_rounded,
              color: Color(0xFF078A5B),
              title: 'Task completed',
              message: 'This task has been reviewed and completed.',
            ),
          ] else if (task.status.toLowerCase() == 'cancelled') ...[
            const SizedBox(height: 10),
            const _StateNotice(
              icon: Icons.cancel_outlined,
              color: Color(0xFFC43D4B),
              title: 'Task cancelled',
              message: 'This task is closed and no further action is available.',
            ),
          ],
        ],
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String _valueOrDash(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value.trim();
  }

  String _date(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
  }

  String _dateTime(DateTime? value) {
    if (value == null) return '-';
    final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day.toString().padLeft(2, '0')} ${_month(value.month)} '
        '${value.year}, ${hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')} $period';
  }

  String _month(int month) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month];
}

class _TaskHero extends StatelessWidget {
  const _TaskHero({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(task.status);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_dark, _primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x241B5FE0),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .17),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: .22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      task.status.isEmpty ? 'Open' : task.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                task.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.subject.trim().isEmpty ? 'Untitled task' : task.subject.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _statusMessage(task.status),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .82),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor = _primary,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE7ECF3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A172033),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accentColor, size: 17),
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        child,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: const Color(0xFF98A2B3)),
            const SizedBox(width: 9),
            SizedBox(
              width: 75,
              child: Text(
                label,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: valueColor ?? _ink,
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      if (showDivider)
        const Divider(height: 1, indent: 26, color: Color(0xFFEEF1F5)),
    ],
  );
}

class _ReturnedCard extends StatelessWidget {
  const _ReturnedCard({
    required this.reviewer,
    required this.reason,
    required this.reviewedAt,
  });

  final String reviewer;
  final String reason;
  final String reviewedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8EB),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFF3D296)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.assignment_return_outlined,
                color: Color(0xFFB26A00), size: 19),
            SizedBox(width: 8),
            Text(
              'Changes requested',
              style: TextStyle(
                color: Color(0xFF8D5200),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          reason,
          style: const TextStyle(color: Color(0xFF744B10), fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'By $reviewer',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF9A6A26), fontSize: 12.5),
              ),
            ),
            Text(
              reviewedAt,
              style: const TextStyle(color: Color(0xFF9A6A26), fontSize: 12.5),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StateNotice extends StatelessWidget {
  const _StateNotice({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(message,
                  style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.3)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFCDD2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFC43D4B), size: 19),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF9C2835)))),
      ],
    ),
  );
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.isStarting,
    required this.canStart,
    required this.onPressed,
  });

  final bool isStarting;
  final bool canStart;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7ECF3))),
        boxShadow: [
          BoxShadow(color: Color(0x12172033), blurRadius: 14, offset: Offset(0, -4)),
        ],
      ),
      child: SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: isStarting ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: const Color(0xFFB9C7DF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          icon: isStarting
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Icon(canStart ? Icons.play_arrow_rounded : Icons.upload_rounded, size: 21),
          label: Text(
            isStarting ? 'Starting task...' : (canStart ? 'Start Task' : 'Submit Completion'),
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ),
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      Container(
        height: 145,
        decoration: BoxDecoration(
          color: const Color(0xFFE6ECF5),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      const SizedBox(height: 10),
      ...List.generate(
        2,
            (_) => Container(
          height: 130,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
        ),
      ),
    ],
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(color: Color(0xFFEAF0FF), shape: BoxShape.circle),
            child: const Icon(Icons.cloud_off_rounded, color: _primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text('Unable to load task',
              style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}

class _StatusStyle {
  const _StatusStyle(this.icon);
  final IconData icon;
}

_StatusStyle _statusStyle(String status) {
  switch (status.toLowerCase()) {
    case 'working':
      return const _StatusStyle(Icons.play_circle_outline_rounded);
    case 'pending review':
      return const _StatusStyle(Icons.hourglass_top_rounded);
    case 'completed':
      return const _StatusStyle(Icons.verified_rounded);
    case 'cancelled':
      return const _StatusStyle(Icons.cancel_outlined);
    default:
      return const _StatusStyle(Icons.radio_button_unchecked_rounded);
  }
}

String _statusMessage(String status) {
  switch (status.toLowerCase()) {
    case 'working':
      return 'In progress — submit your work when it is ready.';
    case 'pending review':
      return 'Submitted and waiting for manager review.';
    case 'completed':
      return 'Reviewed and successfully completed.';
    case 'cancelled':
      return 'This task has been cancelled.';
    default:
      return 'Review the details below and start when ready.';
  }
}

Color _priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
    case 'urgent':
      return const Color(0xFFC43D4B);
    case 'medium':
      return const Color(0xFFB26A00);
    case 'low':
      return const Color(0xFF078A5B);
    default:
      return _ink;
  }
}
