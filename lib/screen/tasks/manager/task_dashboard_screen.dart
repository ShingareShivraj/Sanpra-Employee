import 'package:flutter/material.dart';

import 'company_tasks_screen.dart';
import 'create_task_screen.dart';
import 'task_dashboard_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _accent = Color(0xFF4E8CFF);
const _dark = Color(0xFF123FA0);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF657189);
const _canvas = Color(0xFFF4F7FC);

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({super.key});

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen> {
  late final TaskDashboardViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = TaskDashboardViewModel()..load();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _openTasks({String? status}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanyTasksScreen(initialStatus: status),
      ),
    );
    if (mounted) await viewModel.refresh();
  }

  Future<void> _createTask() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    );
    if (created == true && mounted) await viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Management',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'Team workspace',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => viewModel.refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.loading && !viewModel.hasData) {
            return const _DashboardLoading();
          }
          if (viewModel.errorMessage != null && !viewModel.hasData) {
            return _DashboardError(
              message: viewModel.errorMessage!,
              retry: () => viewModel.load(),
            );
          }
          return RefreshIndicator(
            color: _primary,
            onRefresh: viewModel.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
              children: [
                _OverviewHero(
                  company: viewModel.company,
                  total: viewModel.totalTasks,
                  open: viewModel.openCount + viewModel.workingCount,
                  completed: viewModel.completedCount,
                ),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 9),
                  _InlineError(message: viewModel.errorMessage!),
                ],
                const SizedBox(height: 11),
                if (viewModel.pendingReviewCount > 0) ...[
                  _ReviewBanner(
                    count: viewModel.pendingReviewCount,
                    onTap: () => _openTasks(status: 'Pending Review'),
                  ),
                  const SizedBox(height: 11),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _PrimaryAction(
                        icon: Icons.add_task_rounded,
                        label: 'Create Task',
                        caption: 'Assign new work',
                        filled: true,
                        onTap: _createTask,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _PrimaryAction(
                        icon: Icons.view_list_rounded,
                        label: 'Company Tasks',
                        caption: 'View and manage',
                        onTap: () => _openTasks(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionTitle(
                  title: 'Workload overview',
                  subtitle: 'Tap a status to view its tasks',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Open',
                        count: viewModel.openCount,
                        icon: Icons.inbox_rounded,
                        color: const Color(0xFF2375E8),
                        onTap: () => _openTasks(status: 'Open'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        label: 'Working',
                        count: viewModel.workingCount,
                        icon: Icons.timelapse_rounded,
                        color: const Color(0xFFF09A24),
                        onTap: () => _openTasks(status: 'Working'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'In Review',
                        count: viewModel.pendingReviewCount,
                        icon: Icons.fact_check_outlined,
                        color: const Color(0xFF8957D8),
                        onTap: () => _openTasks(status: 'Pending Review'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        label: 'Completed',
                        count: viewModel.completedCount,
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF1A9B70),
                        onTap: () => _openTasks(status: 'Completed'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                _SectionTitle(
                  title: 'Recently updated',
                  subtitle: viewModel.recentTasks.isEmpty
                      ? 'No recent activity'
                      : 'Latest team task activity',
                  trailing: viewModel.recentTasks.isEmpty
                      ? null
                      : TextButton(
                    onPressed: () => _openTasks(),
                    style: TextButton.styleFrom(
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                if (viewModel.recentTasks.isEmpty)
                  const _EmptyRecent()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6EBF3)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A1B3764),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (var i = 0;
                        i < viewModel.recentTasks.take(5).length;
                        i++) ...[
                          _RecentTaskTile(
                            task: viewModel.recentTasks[i],
                            onTap: () => _openTasks(
                              status: viewModel.recentTasks[i].status,
                            ),
                          ),
                          if (i < viewModel.recentTasks.take(5).length - 1)
                            const Divider(
                              height: 1,
                              indent: 55,
                              endIndent: 12,
                              color: Color(0xFFEDF0F5),
                            ),
                        ],
                      ],
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

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({
    required this.company,
    required this.total,
    required this.open,
    required this.completed,
  });

  final String? company;
  final int total;
  final int open;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final completion = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_dark, _primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331B5FE0),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team Task Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (company != null && company!.trim().isNotEmpty)
                      Text(
                        company!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.78),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'TOTAL TASKS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.70),
                      fontSize: 9.5,
                      letterSpacing: .55,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStat(label: 'Active', value: '$open'),
              ),
              Container(width: 1, height: 25, color: Colors.white24),
              Expanded(
                child: _HeroStat(label: 'Completed', value: '$completed'),
              ),
              Container(width: 1, height: 25, color: Colors.white24),
              Expanded(
                child: _HeroStat(
                  label: 'Progress',
                  value: '${(completion * 100).round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(.72),
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF4EEFF),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFDCCBFA)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF8957D8),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.rate_review_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${count == 1 ? 'task needs' : 'tasks need'} review',
                    style: const TextStyle(
                      color: Color(0xFF3C2862),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Check submissions and take action',
                    style: TextStyle(
                      color: Color(0xFF765D99),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Row(
                children: [
                  Text(
                    'Review',
                    style: TextStyle(
                      color: Color(0xFF7042B5),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF7042B5),
                    size: 15,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Material(
    color: filled ? _primary : Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: const Color(0xFFDCE4F0)),
          boxShadow: filled
              ? const [
            BoxShadow(
              color: Color(0x201B5FE0),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: filled
                    ? Colors.white.withOpacity(.17)
                    : const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: filled ? Colors.white : _primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: filled ? Colors.white : _ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: filled ? Colors.white70 : _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: _muted,
                fontSize: 10.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 67,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5EAF2)),
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: color.withOpacity(.11),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 19,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: Color(0xFFB4BDCB),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecentTaskTile extends StatelessWidget {
  const _RecentTaskTile({required this.task, required this.onTap});
  final dynamic task;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'working':
        return const Color(0xFFF09A24);
      case 'pending review':
        return const Color(0xFF8957D8);
      case 'completed':
        return const Color(0xFF1A9B70);
      case 'cancelled':
        return const Color(0xFF8993A4);
      default:
        return const Color(0xFF2375E8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = task.status.toString();
    final color = _statusColor(status);
    final title = task.subject.toString().trim().isEmpty
        ? task.name.toString()
        : task.subject.toString();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.task_alt_rounded, color: color, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '$status  •  ${task.priority}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFFB5BECC),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFFFD7D7)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded,
            color: Color(0xFFD74444), size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF9E3333),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE5EAF2)),
    ),
    child: const Column(
      children: [
        Icon(Icons.history_toggle_off_rounded,
            color: Color(0xFFA8B2C1), size: 30),
        SizedBox(height: 6),
        Text(
          'No task activity yet',
          style: TextStyle(
            color: _ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'New and updated tasks will appear here.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _primary),
        ),
        SizedBox(height: 11),
        Text(
          'Preparing task workspace...',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFD84B4B),
              size: 25,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load dashboard',
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: retry,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Try Again',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}
