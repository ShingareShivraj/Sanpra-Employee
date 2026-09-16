import 'package:flutter/material.dart';

import '../../model/meeting/meeting_model.dart';
import 'meeting_detail_screen.dart';
import 'meeting_form_screen.dart';
import 'meeting_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE5EAF1);

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final MeetingViewModel _viewModel = MeetingViewModel();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _viewModel.initialise();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 280) {
      _viewModel.loadMeetings(reset: false);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openMeeting(MeetingModel meeting) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MeetingDetailScreen(
          meetingName: meeting.name,
          initialMeeting: meeting,
        ),
      ),
    );
    if (changed == true) await _viewModel.refresh();
  }

  Future<void> _createMeeting() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MeetingFormScreen()),
    );
    if (changed == true) await _viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: _ink,
          title: const Text(
            'Meetings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _viewModel.refreshing ? null : _viewModel.refresh,
              icon: _viewModel.refreshing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: _viewModel.isMeetingManager
            ? FloatingActionButton.extended(
                heroTag: 'create-meeting',
                onPressed: _createMeeting,
                elevation: 3,
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Create Meeting',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              )
            : null,
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_viewModel.initialLoading) return const _MeetingSkeleton();
    if (_viewModel.access == null) {
      return _ErrorState(
        message: _viewModel.error ?? 'Unable to load meetings.',
        onRetry: _viewModel.initialise,
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _MeetingHeader(isManager: _viewModel.isMeetingManager),
                const SizedBox(height: 12),
                _SearchField(
                  controller: _searchController,
                  onChanged: _viewModel.searchMeetings,
                  onClear: () {
                    _searchController.clear();
                    _viewModel.searchMeetings('');
                  },
                ),
                const SizedBox(height: 10),
                _ViewSelector(
                  selected: _viewModel.selectedView,
                  onChanged: _viewModel.selectView,
                ),
                if (_viewModel.error != null) ...[
                  const SizedBox(height: 10),
                  _InlineError(message: _viewModel.error!),
                ],
              ]),
            ),
          ),
          if (_viewModel.contentLoading)
            const SliverFillRemaining(child: _MeetingListSkeleton())
          else if (_viewModel.meetings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                isPast: _viewModel.selectedView == MeetingListView.past,
                canCreate: _viewModel.isMeetingManager,
                onCreate: _createMeeting,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meeting = _viewModel.meetings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MeetingCard(
                        meeting: meeting,
                        onTap: () => _openMeeting(meeting),
                      ),
                    );
                  },
                  childCount: _viewModel.meetings.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: _viewModel.loadingMore
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingHeader extends StatelessWidget {
  const _MeetingHeader({required this.isManager});
  final bool isManager;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_darkBlue, _primary]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay aligned. Meet with purpose.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isManager
                      ? 'Schedule and manage company meetings.'
                      : 'View your agenda and join on time.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.78),
                    fontSize: 11.5,
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search meetings',
        hintStyle: const TextStyle(fontSize: 12, color: _muted),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded)),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.3),
        ),
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({required this.selected, required this.onChanged});
  final MeetingListView selected;
  final ValueChanged<MeetingListView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          _option('Upcoming', MeetingListView.upcoming),
          _option('Past', MeetingListView.past),
        ],
      ),
    );
  }

  Widget _option(String label, MeetingListView value) {
    final active = selected == value;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? _primary : _muted,
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting, required this.onTap});
  final MeetingModel meeting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(meeting.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF344054).withOpacity(.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(date: meeting.meetingDate),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meeting.meetingTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 14,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(.09),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            meeting.status.apiValue,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _MetaLine(
                      icon: Icons.schedule_rounded,
                      text: '${_shortTime(meeting.startTime)} – ${_shortTime(meeting.endTime)}',
                    ),
                    const SizedBox(height: 4),
                    _MetaLine(
                      icon: _platformIcon(meeting.meetingPlatform),
                      text: meeting.meetingPlatform.apiValue,
                    ),
                    const SizedBox(height: 4),
                    _MetaLine(
                      icon: Icons.person_outline_rounded,
                      text: meeting.organizerName,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Padding(
                padding: EdgeInsets.only(top: 36),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF98A2B3),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: _primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date == null ? '--' : months[date!.month - 1],
            style: const TextStyle(
              color: _primary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            date?.day.toString().padLeft(2, '0') ?? '--',
            style: const TextStyle(
              color: _ink,
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isPast,
    required this.canCreate,
    required this.onCreate,
  });
  final bool isPast;
  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_outlined, color: _primary, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                isPast ? 'No past meetings' : 'No upcoming meetings',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isPast
                    ? 'Completed and cancelled meetings appear here.'
                    : 'Your scheduled meetings will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              if (canCreate && !isPast) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create Meeting'),
                  style: FilledButton.styleFrom(backgroundColor: _primary),
                ),
              ],
            ],
          ),
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFD92D20), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 11.5))),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: _muted, size: 42),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}

class _MeetingSkeleton extends StatelessWidget {
  const _MeetingSkeleton();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: _primary, strokeWidth: 2.4),
      );
}

class _MeetingListSkeleton extends StatelessWidget {
  const _MeetingListSkeleton();
  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 116,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _border),
          ),
        ),
      );
}

Color _statusColor(MeetingStatus status) => switch (status) {
      MeetingStatus.scheduled => _primary,
      MeetingStatus.completed => const Color(0xFF12B76A),
      MeetingStatus.cancelled => const Color(0xFFD92D20),
    };

IconData _platformIcon(MeetingPlatform platform) => switch (platform) {
      MeetingPlatform.googleMeet => Icons.video_camera_front_outlined,
      MeetingPlatform.microsoftTeams => Icons.groups_outlined,
      MeetingPlatform.zoom => Icons.videocam_outlined,
      MeetingPlatform.webex => Icons.language_rounded,
      MeetingPlatform.jitsi => Icons.video_call_outlined,
      MeetingPlatform.other => Icons.link_rounded,
    };

String _shortTime(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return value;
  var hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1];
  final suffix = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return '$hour:$minute $suffix';
}
