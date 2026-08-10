import 'package:flutter/material.dart';

import '../../../model/task_model.dart';
import 'my_tasks_viewmodel.dart';
import 'submit_task_screen.dart';
import 'submit_task_viewmodel.dart';
import 'task_details_screen.dart';

const _primary = Color(0xFF1B5FE0);
const _primaryDark = Color(0xFF123FA0);
const _accent = Color(0xFF4E8CFF);
const _ink = Color(0xFF17213A);
const _muted = Color(0xFF667085);
const _surface = Color(0xFFF4F7FC);

enum _TaskFilter { overdue, today, upcoming, pendingReview, completed }

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({
    super.key,
    this.photoPicker,
    this.photoUploader,
    this.locationProvider,
  });

  final TaskPhotoPicker? photoPicker;
  final TaskPhotoUploader? photoUploader;
  final TaskLocationProvider? locationProvider;

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  late final MyTasksViewModel viewModel;
  _TaskFilter selectedFilter = _TaskFilter.today;

  @override
  void initState() {
    super.initState();
    viewModel = MyTasksViewModel()..loadTasks();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _open(TaskModel task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          taskName: task.name,
          // photoPicker: widget.photoPicker,
          photoUploader: widget.photoUploader,
          locationProvider: widget.locationProvider,
        ),
      ),
    );
    if (changed == true) await viewModel.refreshTasks();
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
        centerTitle: false,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Plan, focus and finish',
              style: TextStyle(fontSize: 12, color: Color(0xFFCAD9FF)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => viewModel.refreshTasks(),
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.loading && !viewModel.hasTasks) {
            return const _LoadingView();
          }
          if (viewModel.errorMessage != null && !viewModel.hasTasks) {
            return _ErrorView(
              message: viewModel.errorMessage!,
              retry: () => viewModel.loadTasks(force: true),
            );
          }

          return RefreshIndicator(
            color: _primary,
            onRefresh: viewModel.refreshTasks,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _overview()),
                if (viewModel.errorMessage != null)
                  SliverToBoxAdapter(
                    child: _ErrorBanner(message: viewModel.errorMessage!),
                  ),
                SliverToBoxAdapter(child: _filters()),
                SliverToBoxAdapter(child: _sectionHeading()),
                _taskContent(),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _overview() {
    final activeCount = viewModel.overdue.length +
        viewModel.today.length +
        viewModel.upcoming.length;
    final totalCount = activeCount +
        viewModel.pendingReview.length +
        viewModel.completed.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryDark, _primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x281B5FE0),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
            ),
            child: const Icon(Icons.task_alt_rounded,
                color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeCount == 0 ? 'You are all caught up' : '$activeCount active tasks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${viewModel.today.length} today  •  ${viewModel.overdue.length} overdue',
                  style: const TextStyle(
                    color: Color(0xFFDCE6FF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '$totalCount',
                  style: const TextStyle(
                    color: _primaryDark,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('TOTAL',
                    style: TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return SizedBox(
      height: 49,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _filterChip(_TaskFilter.overdue, 'Overdue', viewModel.overdue.length,
              Icons.warning_amber_rounded, const Color(0xFFE5484D)),
          _filterChip(_TaskFilter.today, 'Today', viewModel.today.length,
              Icons.today_rounded, _primary),
          _filterChip(_TaskFilter.upcoming, 'Upcoming',
              viewModel.upcoming.length, Icons.event_rounded, const Color(0xFF7A5AF8)),
          _filterChip(_TaskFilter.pendingReview, 'Review',
              viewModel.pendingReview.length, Icons.hourglass_top_rounded, const Color(0xFFF79009)),
          _filterChip(_TaskFilter.completed, 'Done', viewModel.completed.length,
              Icons.verified_rounded, const Color(0xFF12A474)),
        ],
      ),
    );
  }

  Widget _filterChip(
      _TaskFilter filter,
      String label,
      int count,
      IconData icon,
      Color color,
      ) {
    final selected = selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => selectedFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xFFE4E9F2),
            ),
            boxShadow: selected
                ? [BoxShadow(color: color.withValues(alpha: .2), blurRadius: 7)]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                constraints: const BoxConstraints(minWidth: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .22)
                      : color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskContent() {
    final tasks = _selectedTasks();
    if (tasks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(filter: selectedFilter),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 0),
      sliver: SliverList.separated(
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 7),
        itemBuilder: (_, index) => _TaskCard(
          task: tasks[index],
          filter: selectedFilter,
          onTap: () => _open(tasks[index]),
        ),
      ),
    );
  }

  Widget _sectionHeading() {
    final tasks = _selectedTasks();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _filterLabel(selectedFilter),
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<TaskModel> _selectedTasks() {
    switch (selectedFilter) {
      case _TaskFilter.overdue:
        return viewModel.overdue;
      case _TaskFilter.today:
        return viewModel.today;
      case _TaskFilter.upcoming:
        return viewModel.upcoming;
      case _TaskFilter.pendingReview:
        return viewModel.pendingReview;
      case _TaskFilter.completed:
        return viewModel.completed;
    }
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.filter,
    required this.onTap,
  });

  final TaskModel task;
  final _TaskFilter filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(filter);
    final title = task.subject.isEmpty ? task.name : task.subject;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A17213A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 43,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (task.priority.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _PriorityBadge(priority: task.priority),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MetaItem(
                          icon: Icons.circle,
                          text: task.status.isEmpty ? _filterLabel(filter) : task.status,
                          color: color,
                          tinyIcon: true,
                        ),
                        if (task.dueDate != null) ...[
                          const SizedBox(width: 11),
                          _MetaItem(
                            icon: Icons.calendar_today_rounded,
                            text: _formatDate(task.dueDate!),
                            color: _muted,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 11, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(_TaskFilter filter) {
    switch (filter) {
      case _TaskFilter.overdue:
        return const Color(0xFFE5484D);
      case _TaskFilter.today:
        return _primary;
      case _TaskFilter.upcoming:
        return const Color(0xFF7A5AF8);
      case _TaskFilter.pendingReview:
        return const Color(0xFFF79009);
      case _TaskFilter.completed:
        return const Color(0xFF12A474);
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final normalized = priority.toLowerCase();
    final color = normalized == 'high'
        ? const Color(0xFFE5484D)
        : normalized == 'medium'
        ? const Color(0xFFF79009)
        : const Color(0xFF12A474);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .25,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.text,
    required this.color,
    this.tinyIcon = false,
  });
  final IconData icon;
  final String text;
  final Color color;
  final bool tinyIcon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: tinyIcon ? 6 : 11, color: color),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(
          color: tinyIcon ? _ink : _muted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFE5ECFA),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      const SizedBox(height: 13),
      const LinearProgressIndicator(
        minHeight: 3,
        color: _primary,
        backgroundColor: Color(0xFFDCE5F7),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      const SizedBox(height: 12),
      ...List.generate(
        4,
            (_) => Container(
          height: 64,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE8ECF3)),
          ),
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final _TaskFilter filter;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 70),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.task_alt_rounded, color: _primary, size: 27),
          ),
          const SizedBox(height: 10),
          Text(
            'No ${_filterLabel(filter).toLowerCase()} tasks',
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'New tasks will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                color: Color(0xFFE5484D), size: 26),
          ),
          const SizedBox(height: 10),
          const Text('Unable to load tasks',
              style: TextStyle(
                  color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: retry,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 1, 12, 3),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9EA),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFFC7C9)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded,
            color: Color(0xFFE5484D), size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ink, fontSize: 11.5)),
        ),
      ],
    ),
  );
}

String _filterLabel(_TaskFilter filter) {
  switch (filter) {
    case _TaskFilter.overdue:
      return 'Overdue';
    case _TaskFilter.today:
      return 'Today';
    case _TaskFilter.upcoming:
      return 'Upcoming';
    case _TaskFilter.pendingReview:
      return 'Pending Review';
    case _TaskFilter.completed:
      return 'Completed';
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
