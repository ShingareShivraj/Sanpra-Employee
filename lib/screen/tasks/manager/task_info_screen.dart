import 'package:flutter/material.dart';
import '../../../services/task_manager_service.dart';
import '../../../model/task_model.dart';

const Color _bg = Color(0xFFF6F8FC);
const Color _card = Colors.white;
const Color _ink = Color(0xFF182230);
const Color _muted = Color(0xFF667085);
const Color _line = Color(0xFFE6EAF0);
const Color _blue = Color(0xFF2563EB);

class TaskInfoScreen extends StatefulWidget {
  const TaskInfoScreen({
    super.key,
    required this.task,
  });

  final TaskModel task;

  @override
  State<TaskInfoScreen> createState() => _TaskInfoScreenState();
}

class _TaskInfoScreenState extends State<TaskInfoScreen> {
  final TaskManagerService _service = TaskManagerService();

  late TaskModel _task;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    try {
      final result = await _service.getTaskDetails(
        taskName: widget.task.name,
      );

      if (!mounted) return;

      setState(() {
        _task = result.task ?? widget.task;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _bg,
        foregroundColor: _ink,
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
              children: [
                _TaskHeader(task: _task),
                const SizedBox(height: 8),
                _OverviewCard(task: _task),
                const SizedBox(height: 8),
                _AssignmentCard(task: _task),
                if (_hasProject(_task)) ...[
                  const SizedBox(height: 8),
                  _ProjectCard(task: _task),
                ],
                if (_task.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DescriptionCard(description: _task.description),
                ],
                if (_hasCompletionInfo(_task)) ...[
                  const SizedBox(height: 8),
                  _CompletionCard(task: _task),
                ],
                if (_hasReviewInfo(_task)) ...[
                  const SizedBox(height: 8),
                  _ReviewCard(task: _task),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorCard(
                    message: _error!,
                    onRetry: _loadTaskDetails,
                  ),
                ],
              ],
            ),
            if (_isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasProject(TaskModel task) =>
      task.project?.trim().isNotEmpty ?? false;

  bool _hasCompletionInfo(TaskModel task) =>
      task.completionRemarks?.trim().isNotEmpty == true ||
          task.completionTime != null ||
          task.completionPhotoUrl?.trim().isNotEmpty == true ||
          task.completionLatitude != null ||
          task.completionLongitude != null;

  bool _hasReviewInfo(TaskModel task) =>
      task.reviewedBy?.trim().isNotEmpty == true ||
          task.reviewRemarks?.trim().isNotEmpty == true ||
          task.reviewTime != null;
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Couldn\'t refresh',
      icon: Icons.cloud_off_rounded,
      children: [
        Text(
          message,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(task.status);
    final priority = _priorityStyle(task.priority);

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.subject.trim().isEmpty ? task.name : task.subject,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 19,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(
                label: task.status.isEmpty ? 'Unknown' : task.status,
                icon: status.icon,
                foreground: status.foreground,
                background: status.background,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            task.name,
            style: const TextStyle(
              color: _muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniPill(
                label: task.priority.isEmpty ? 'Medium' : task.priority,
                icon: Icons.flag_rounded,
                foreground: priority.foreground,
                background: priority.background,
              ),
              if (task.progress > 0) ...[
                const SizedBox(width: 6),
                _MiniPill(
                  label: '${_formatNumber(task.progress)}% complete',
                  icon: Icons.trending_up_rounded,
                  foreground: _blue,
                  background: const Color(0xFFEAF1FF),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Task Overview',
      icon: Icons.assignment_rounded,
      children: [
        _InfoGrid(
          items: [
            _InfoItem(
              label: 'Start Date',
              value: _formatDate(task.expectedStartDate),
              icon: Icons.calendar_today_rounded,
            ),
            _InfoItem(
              label: 'Due Date',
              value: _formatDate(task.dueDate),
              icon: Icons.event_rounded,
            ),
            _InfoItem(
              label: 'Created By',
              value: _display(task.ownerName ?? task.owner),
              icon: Icons.person_outline_rounded,
            ),
            _InfoItem(
              label: 'Created On',
              value: _formatDateTime(task.creation),
              icon: Icons.access_time_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final assignee = task.assignees.isNotEmpty
        ? task.assignees.first
        : null;

    final employeeName = assignee?.fullName?.trim().isNotEmpty == true
        ? assignee!.fullName!
        : (task.assignedTo?.trim().isNotEmpty == true
        ? task.assignedTo!
        : 'Not assigned');

    final user = assignee?.user ?? task.assignedTo;

    return _SectionCard(
      title: 'Assignment',
      icon: Icons.group_rounded,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: _blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employeeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (user?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      user!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (task.assignedBy?.trim().isNotEmpty == true ||
            task.assignedOn != null) ...[
          const SizedBox(height: 9),
          Row(
            children: [
              if (task.assignedBy?.trim().isNotEmpty == true)
                Expanded(
                  child: _CompactMeta(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Assigned by',
                    value: task.ownerName!,
                  ),
                ),
              if (task.assignedBy?.trim().isNotEmpty == true &&
                  task.assignedOn != null)
                const SizedBox(width: 8),
              if (task.assignedOn != null)
                Expanded(
                  child: _CompactMeta(
                    icon: Icons.schedule_rounded,
                    label: 'Assigned on',
                    value: _formatDateTime(task.assignedOn),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CompactMeta extends StatelessWidget {
  const _CompactMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Project',
      icon: Icons.folder_rounded,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                color: _blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.project!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (task.company?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.company!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Description',
      icon: Icons.notes_rounded,
      children: [
        Text(
          description,
          style: const TextStyle(
            color: Color(0xFF475467),
            fontSize: 12.5,
            height: 1.42,
          ),
        ),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Completion',
      icon: Icons.check_circle_outline_rounded,
      children: [
        if (task.completionRemarks?.trim().isNotEmpty == true)
          _TextBlock(
            label: 'Completion Remarks',
            value: task.completionRemarks!,
          ),
        if (task.completionTime != null)
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Completed On',
            value: _formatDateTime(task.completionTime),
          ),
        if (task.completionPhotoUrl?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              task.completionPhotoUrl!,
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 90,
                alignment: Alignment.center,
                color: const Color(0xFFF2F4F7),
                child: const Text(
                  'Completion photo unavailable',
                  style: TextStyle(color: _muted, fontSize: 11.5),
                ),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 170,
                  alignment: Alignment.center,
                  color: const Color(0xFFF2F4F7),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Review',
      icon: Icons.rate_review_outlined,
      children: [
        if (task.reviewedBy?.trim().isNotEmpty == true)
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Reviewed By',
            value: task.reviewedBy!,
          ),
        if (task.reviewTime != null)
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Reviewed On',
            value: _formatDateTime(task.reviewTime),
          ),
        if (task.reviewRemarks?.trim().isNotEmpty == true)
          _TextBlock(
            label: 'Review Remarks',
            value: task.reviewRemarks!,
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: _blue),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ..._withSpacing(children, 7),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 430;
        final width = wide
            ? (constraints.maxWidth - 8) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => SizedBox(
              width: width,
              child: _InfoTile(item: item),
            ),
          )
              .toList(),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 15, color: _muted),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _muted),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label  ',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _StatusStyle {
  const _StatusStyle({
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
}

class _PriorityStyle {
  const _PriorityStyle({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}

_StatusStyle _statusStyle(String value) {
  switch (value.trim().toLowerCase()) {
    case 'working':
      return const _StatusStyle(
        foreground: Color(0xFF2563EB),
        background: Color(0xFFEAF1FF),
        icon: Icons.play_circle_outline_rounded,
      );
    case 'pending review':
      return const _StatusStyle(
        foreground: Color(0xFF7C3AED),
        background: Color(0xFFF1EAFE),
        icon: Icons.rate_review_outlined,
      );
    case 'completed':
      return const _StatusStyle(
        foreground: Color(0xFF15803D),
        background: Color(0xFFEAF8EF),
        icon: Icons.check_circle_outline_rounded,
      );
    case 'cancelled':
      return const _StatusStyle(
        foreground: Color(0xFFDC2626),
        background: Color(0xFFFEECEC),
        icon: Icons.cancel_outlined,
      );
    case 'overdue':
      return const _StatusStyle(
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFF4DF),
        icon: Icons.warning_amber_rounded,
      );
    default:
      return const _StatusStyle(
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFF4DF),
        icon: Icons.radio_button_checked_rounded,
      );
  }
}

_PriorityStyle _priorityStyle(String value) {
  switch (value.trim().toLowerCase()) {
    case 'urgent':
      return const _PriorityStyle(
        foreground: Color(0xFFDC2626),
        background: Color(0xFFFEECEC),
      );
    case 'high':
      return const _PriorityStyle(
        foreground: Color(0xFFD97706),
        background: Color(0xFFFFF4DF),
      );
    case 'low':
      return const _PriorityStyle(
        foreground: Color(0xFF15803D),
        background: Color(0xFFEAF8EF),
      );
    default:
      return const _PriorityStyle(
        foreground: Color(0xFF475467),
        background: Color(0xFFF2F4F7),
      );
  }
}

List<Widget> _withSpacing(List<Widget> children, double spacing) {
  final result = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    if (i > 0) result.add(SizedBox(height: spacing));
    result.add(children[i]);
  }
  return result;
}

String _display(String? value) {
  if (value == null || value.trim().isEmpty) return 'Not available';
  return value.trim();
}

String _formatDate(DateTime? value) {
  if (value == null) return 'Not set';
  return '${_two(value.day)}/${_two(value.month)}/${value.year}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Not available';
  return '${_two(value.day)}/${_two(value.month)}/${value.year} '
      '${_two(value.hour)}:${_two(value.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}
