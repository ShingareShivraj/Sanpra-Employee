import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/my_work_model.dart';
import '../tasks/employee/submit_task_viewmodel.dart';
import '../tasks/employee/task_details_screen.dart';
import 'my_work_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _primaryDark = Color(0xFF123FA0);
const _ink = Color(0xFF17213A);
const _muted = Color(0xFF667085);
const _surface = Color(0xFFF4F7FC);
const _success = Color(0xFF168765);
const _warning = Color(0xFFF09A24);
const _danger = Color(0xFFE04F5F);
const _purple = Color(0xFF8157C8);

class MyWorkScreen extends StatefulWidget {
  const MyWorkScreen({
    super.key,
    this.photoUploader,
    this.locationProvider,
  });

  final TaskPhotoUploader? photoUploader;
  final TaskLocationProvider? locationProvider;

  @override
  State<MyWorkScreen> createState() => _MyWorkScreenState();
}

class _MyWorkScreenState extends State<MyWorkScreen> {
  late final MyWorkViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = MyWorkViewModel()..load();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _openWork(MyWorkItemModel item) async {
    if (item.isTask) {
      final taskName = item.taskName;
      if (taskName == null) {
        _message('Task ID is missing.', error: true);
        return;
      }
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(
            taskName: taskName,
            photoUploader: widget.photoUploader,
            locationProvider: widget.locationProvider,
          ),
        ),
      );
      if (mounted) await viewModel.refresh();
      return;
    }

    if (item.isTodo) {
      await _showTodo(item);
      return;
    }

    _message('This work type is not supported yet.', error: true);
  }

  Future<void> _showTodo(MyWorkItemModel item) async {
    final shouldComplete = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TodoSheet(item: item),
    );
    if (shouldComplete != true || !mounted) return;

    final success = await viewModel.completeTodo(item);
    if (!mounted) return;
    _message(
      success
          ? 'Work completed successfully.'
          : (viewModel.errorMessage ?? 'Unable to complete work.'),
      error: !success,
    );
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _danger : _success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Work',
              style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800),
            ),
            Text(
              'Everything assigned to you',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFFCAD9FF),
              ),
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: viewModel,
            builder: (_, __) => IconButton(
              tooltip: 'Refresh',
              onPressed: viewModel.refreshing ? null : viewModel.refresh,
              icon: viewModel.refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 21),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.loading && !viewModel.hasAnyWork) {
            return const _LoadingView();
          }
          if (viewModel.errorMessage != null && !viewModel.hasAnyWork) {
            return _ErrorView(
              message: viewModel.errorMessage!,
              retry: () => viewModel.load(force: true),
            );
          }

          return RefreshIndicator(
            color: _primary,
            onRefresh: viewModel.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Column(
                      children: [
                        _OverviewCard(viewModel: viewModel),
                        if (viewModel.errorMessage != null) ...[
                          const SizedBox(height: 9),
                          _InlineError(
                            message: viewModel.errorMessage!,
                            close: viewModel.clearError,
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeader(
                    selected: viewModel.selectedSection,
                    countFor: viewModel.countFor,
                    onSelected: viewModel.selectSection,
                  ),
                ),
                if (viewModel.selectedItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(section: viewModel.selectedSection),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                    sliver: SliverList.separated(
                      itemCount: viewModel.selectedItems.length,
                      itemBuilder: (_, index) {
                        final item = viewModel.selectedItems[index];
                        return _WorkCard(
                          item: item,
                          completing: viewModel.isCompleting(item.todoName),
                          onTap: () => _openWork(item),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.viewModel});

  final MyWorkViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, Color(0xFF397AF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_outline_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${viewModel.openCount} active work ${viewModel.openCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  viewModel.counts.overdue > 0
                      ? '${viewModel.counts.overdue} overdue • Prioritise these first'
                      : 'Tasks and ToDos in one place',
                  style: const TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 11.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (viewModel.counts.pendingReview > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${viewModel.counts.pendingReview} in review',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterHeader extends SliverPersistentHeaderDelegate {
  _FilterHeader({
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final MyWorkSection selected;
  final int Function(MyWorkSection) countFor;
  final ValueChanged<MyWorkSection> onSelected;

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _surface,
      alignment: Alignment.center,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        itemCount: MyWorkSection.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, index) {
          final section = MyWorkSection.values[index];
          final active = section == selected;
          return ChoiceChip(
            selected: active,
            onSelected: (_) => onSelected(section),
            showCheckmark: false,
            side: BorderSide(
              color: active ? _primary : const Color(0xFFE1E6EF),
            ),
            selectedColor: _primary,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            label: Text(
              '${_sectionLabel(section)}  ${countFor(section)}',
              style: TextStyle(
                color: active ? Colors.white : _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeader oldDelegate) {
    // Counts may change after refresh/completion even when selection does not.
    return true;
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({
    required this.item,
    required this.completing,
    required this.onTap,
  });

  final MyWorkItemModel item;
  final bool completing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _workStyle(item);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: completing ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE5EAF2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: style.color.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Pill(
                          text: item.isTask ? 'TASK' : 'TODO',
                          color: item.isTask ? _primary : _success,
                        ),
                        const SizedBox(width: 6),
                        _Pill(text: item.status, color: style.color),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.description.isNotEmpty &&
                        item.description != item.title) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      children: [
                        _Meta(
                          icon: Icons.flag_outlined,
                          text: item.priority,
                        ),
                        if (item.dueDate != null)
                          _Meta(
                            icon: Icons.event_outlined,
                            text: _dateText(item.dueDate!),
                          ),
                        if ((item.referenceType ?? '').isNotEmpty && !item.isTask)
                          _Meta(
                            icon: Icons.link_rounded,
                            text: item.referenceType!,
                          ),
                      ],
                    ),
                    if ((item.reviewRemarks ?? '').isNotEmpty &&
                        !item.isPendingReview) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5E8),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          'Review: ${item.reviewRemarks}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF985D12),
                            fontSize: 10.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              completing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFFADB7C7),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoSheet extends StatelessWidget {
  const _TodoSheet({required this.item});

  final MyWorkItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DCE5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: Color(0xFFE8F7F0),
                  child: Icon(Icons.task_alt_rounded, color: _success),
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Complete this work?',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (item.description.isNotEmpty && item.description != item.title) ...[
              const SizedBox(height: 5),
              Text(
                item.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ],
            if ((item.referenceType ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${item.referenceType}${(item.referenceName ?? '').isEmpty ? '' : ' • ${item.referenceName}'}',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _success),
                    onPressed: item.canCompleteDirectly
                        ? () => Navigator.pop(context, true)
                        : null,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Complete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.2,
          fontWeight: FontWeight.w800,
          letterSpacing: .25,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _muted),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            color: _muted,
            fontSize: 10.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.close});

  final String message;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 5, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFFFD3D9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _danger, fontSize: 11.5),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: close,
            icon: const Icon(Icons.close_rounded, size: 17, color: _danger),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => Container(
        height: index == 0 ? 72 : 112,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE7EBF2)),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.retry});

  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: _muted),
            const SizedBox(height: 12),
            const Text(
              'Unable to load My Work',
              style: TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12.5),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.section});

  final MyWorkSection section;

  @override
  Widget build(BuildContext context) {
    final title = switch (section) {
      MyWorkSection.overdue => 'Nothing overdue',
      MyWorkSection.today => 'No work for today',
      MyWorkSection.upcoming => 'No upcoming work',
      MyWorkSection.pendingReview => 'Nothing under review',
      MyWorkSection.completed => 'No completed work',
    };
    final icon = switch (section) {
      MyWorkSection.overdue => Icons.auto_awesome_rounded,
      MyWorkSection.today => Icons.wb_sunny_outlined,
      MyWorkSection.upcoming => Icons.event_available_rounded,
      MyWorkSection.pendingReview => Icons.fact_check_outlined,
      MyWorkSection.completed => Icons.task_alt_rounded,
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _primary.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'New assignments will appear here.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkStyle {
  const _WorkStyle(this.color, this.icon);

  final Color color;
  final IconData icon;
}

_WorkStyle _workStyle(MyWorkItemModel item) {
  final status = item.status.toLowerCase();
  if (status == 'pending review') {
    return const _WorkStyle(_purple, Icons.fact_check_outlined);
  }
  if (status == 'working') {
    return const _WorkStyle(_warning, Icons.timelapse_rounded);
  }
  if (status == 'completed' || status == 'closed') {
    return const _WorkStyle(_success, Icons.task_alt_rounded);
  }
  if (item.dueDate != null &&
      DateUtils.dateOnly(item.dueDate!).isBefore(DateUtils.dateOnly(DateTime.now()))) {
    return const _WorkStyle(_danger, Icons.warning_amber_rounded);
  }
  return _WorkStyle(
    item.isTask ? _primary : _success,
    item.isTask ? Icons.assignment_outlined : Icons.checklist_rounded,
  );
}

String _sectionLabel(MyWorkSection section) {
  switch (section) {
    case MyWorkSection.overdue:
      return 'Overdue';
    case MyWorkSection.today:
      return 'Today';
    case MyWorkSection.upcoming:
      return 'Upcoming';
    case MyWorkSection.pendingReview:
      return 'Review';
    case MyWorkSection.completed:
      return 'Done';
  }
}

String _dateText(DateTime date) {
  final current = DateUtils.dateOnly(DateTime.now());
  final value = DateUtils.dateOnly(date);
  if (value == current) return 'Today';
  if (value == current.add(const Duration(days: 1))) return 'Tomorrow';
  return DateFormat('dd MMM').format(date);
}
