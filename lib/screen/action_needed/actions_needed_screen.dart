import 'package:flutter/material.dart';

import '../../model/actions_needed_model.dart';
import '../chat/chat_conversation_screen.dart';
import '../issues/issue_details_screen.dart';
import '../leave/employee/leave_details_page.dart';
import '../meeting/meeting_detail_screen.dart';
import '../tasks/employee/task_details_screen.dart';
import 'actions_needed_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF5F7FC);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE4E9F1);

class ActionsNeededScreen extends StatefulWidget {
  const ActionsNeededScreen({super.key});

  @override
  State<ActionsNeededScreen> createState() => _ActionsNeededScreenState();
}

class _ActionsNeededScreenState extends State<ActionsNeededScreen> {
  late final ActionsNeededViewModel _viewModel;
  String? _openingActionId;

  @override
  void initState() {
    super.initState();
    _viewModel = ActionsNeededViewModel()..initialise();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openAction(ActionNeededItemModel action) async {
    if (_openingActionId != null) return;
    setState(() => _openingActionId = action.id);
    try {
      switch (action.category) {
        case ActionNeededCategory.myWork:
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskDetailsScreen(taskName: action.name),
            ),
          );
          break;
        case ActionNeededCategory.issues:
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IssueDetailsScreen(issueName: action.name),
            ),
          );
          break;
        case ActionNeededCategory.chat:
          final group = await _viewModel.loadChatGroup(action.name);
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatConversationScreen(initialGroup: group),
            ),
          );
          _viewModel.removeReadChatAction(action.id);
          break;
        case ActionNeededCategory.meetings:
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MeetingDetailScreen(meetingName: action.name),
            ),
          );
          break;
        case ActionNeededCategory.leave:
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LeaveDetailsPage(applicationName: action.name),
            ),
          );
          break;
        case ActionNeededCategory.unknown:
          _showSnack('This action cannot be opened yet.', isError: true);
          break;
      }
    } catch (error) {
      _showSnack(_cleanError(error), isError: true);
    } finally {
      if (mounted) setState(() => _openingActionId = null);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xFFD92D20) : const Color(0xFF25324A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions Needed',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 1),
          Text(
            'Things that need your attention',
            style: TextStyle(fontSize: 10, color: Color(0xFFD8E4FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.loading && !_viewModel.hasLoaded) {
      return const _LoadingState();
    }
    if (_viewModel.error != null && !_viewModel.hasLoaded) {
      return _ErrorState(
        message: _viewModel.error!,
        onRetry: _viewModel.retry,
      );
    }
    if (_viewModel.isEmpty) {
      return RefreshIndicator(
        color: _primary,
        onRefresh: _viewModel.refresh,
        child: const _EmptyState(),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            sliver: SliverToBoxAdapter(child: _buildSummary()),
          ),
          if (_viewModel.error != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              sliver: SliverToBoxAdapter(
                child: _InlineError(
                  message: _viewModel.error!,
                  onClose: _viewModel.clearError,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
            sliver: SliverList.separated(
              itemCount: _viewModel.visibleCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final category = _viewModel.visibleCategories[index];
                return _CategoryCard(
                  category: category,
                  actions: _viewModel.groupedActions[category] ?? const [],
                  openingActionId: _openingActionId,
                  onActionTap: _openAction,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final sectionCount = _viewModel.visibleCategories.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_darkBlue, _primary]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x241B5FE0),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              size: 19,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_viewModel.actions.length} action${_viewModel.actions.length == 1 ? '' : 's'} need attention',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Across $sectionCount ${sectionCount == 1 ? 'section' : 'sections'} • Pull down to refresh',
                  style: const TextStyle(
                    color: Color(0xFFD8E4FF),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          if (_viewModel.refreshing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ActionNeededCategory category;
  final List<ActionNeededItemModel> actions;
  final String? openingActionId;
  final ValueChanged<ActionNeededItemModel> onActionTap;

  const _CategoryCard({
    required this.category,
    required this.actions,
    required this.openingActionId,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyle(category);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C101828),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            color: style.background,
            child: Row(
              children: [
                Icon(style.icon, color: style.color, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    category.label.toUpperCase(),
                    style: TextStyle(
                      color: style.color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .35,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${actions.length}',
                    style: TextStyle(
                      color: style.color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < actions.length; index++) ...[
            _ActionRow(
              action: actions[index],
              style: style,
              opening: openingActionId == actions[index].id,
              enabled: openingActionId == null,
              onTap: () => onActionTap(actions[index]),
            ),
            if (index != actions.length - 1)
              const Divider(height: 1, indent: 52, color: _border),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final ActionNeededItemModel action;
  final _CategoryStyle style;
  final bool opening;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionRow({
    required this.action,
    required this.style,
    required this.opening,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 9, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(style.icon, color: style.color, size: 16),
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
                            action.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (action.hasUnreadMessages) ...[
                          const SizedBox(width: 6),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              action.unreadCount > 99
                                  ? '99+'
                                  : '${action.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (action.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        action.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (_actionDate(action).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _actionDate(action),
                        style: TextStyle(
                          color: style.color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: opening
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: _primary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: Color(0xFF98A2B3),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: const [
        _LoadingBlock(height: 58),
        SizedBox(height: 11),
        _LoadingBlock(height: 124),
        SizedBox(height: 11),
        _LoadingBlock(height: 160),
        SizedBox(height: 11),
        _LoadingBlock(height: 105),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final double height;
  const _LoadingBlock({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 150, 28, 40),
      children: [
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.done_all_rounded,
              size: 34,
              color: Color(0xFF159455),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "You're all caught up",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Nothing needs your attention right now.\nPull down whenever you want to check again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 11.5, height: 1.45),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 31,
                color: Color(0xFFD92D20),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load actions',
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
              style: const TextStyle(color: _muted, fontSize: 11.5),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _InlineError({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFFFC9CE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD92D20),
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 10.5,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFFB42318),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStyle {
  final IconData icon;
  final Color color;
  final Color background;

  const _CategoryStyle({
    required this.icon,
    required this.color,
    required this.background,
  });
}

_CategoryStyle _categoryStyle(ActionNeededCategory category) {
  switch (category) {
    case ActionNeededCategory.myWork:
      return const _CategoryStyle(
        icon: Icons.task_alt_rounded,
        color: Color(0xFF1B5FE0),
        background: Color(0xFFEAF1FF),
      );
    case ActionNeededCategory.issues:
      return const _CategoryStyle(
        icon: Icons.report_problem_outlined,
        color: Color(0xFFD97706),
        background: Color(0xFFFFF4DF),
      );
    case ActionNeededCategory.chat:
      return const _CategoryStyle(
        icon: Icons.mark_chat_unread_outlined,
        color: Color(0xFF7C3AED),
        background: Color(0xFFF2ECFF),
      );
    case ActionNeededCategory.meetings:
      return const _CategoryStyle(
        icon: Icons.video_camera_front_outlined,
        color: Color(0xFF087E8B),
        background: Color(0xFFE5F7F8),
      );
    case ActionNeededCategory.leave:
      return const _CategoryStyle(
        icon: Icons.event_busy_outlined,
        color: Color(0xFFCC3A65),
        background: Color(0xFFFFECF2),
      );
    case ActionNeededCategory.unknown:
      return const _CategoryStyle(
        icon: Icons.notifications_none_rounded,
        color: _muted,
        background: Color(0xFFF0F2F5),
      );
  }
}

String _actionDate(ActionNeededItemModel action) {
  final date = action.date;
  if (date == null) return '';
  const months = [
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
  ];
  final dateText = '${date.day} ${months[date.month - 1]} ${date.year}';
  final timeText = _friendlyTime(action.time);
  return timeText.isEmpty ? dateText : '$dateText • $timeText';
}

String _friendlyTime(String? value) {
  final parts = value?.split(':') ?? const <String>[];
  if (parts.length < 2) return '';
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return '';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
}

String _cleanError(Object error) {
  return error
      .toString()
      .replaceFirst(RegExp(r'^(Exception|ChatServiceException):\s*'), '');
}
