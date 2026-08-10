import 'package:flutter/material.dart';

import '../../../model/leaves/leave_application_model.dart';
import 'apply_leave_page.dart';
import 'leave_details_page.dart';
import 'leave_viewmodel.dart';

const _primaryBlue = Color(0xFF1B5FE0);
const _accentBlue = Color(0xFF4E8CFF);
const _ink = Color(0xFF14213D);
const _background = Color(0xFFF5F7FB);
const _border = Color(0xFFE4EAF3);

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  late final LeaveViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LeaveViewModel()..initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openApplyLeave() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ApplyLeavePage()),
    );
    if (changed == true) await _viewModel.refresh();
  }

  Future<void> _openDetails(LeaveApplicationModel application) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeaveDetailsPage(applicationName: application.name),
      ),
    );
    if (changed == true) await _viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'My Leaves',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _viewModel.isLoading ? null : _viewModel.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openApplyLeave,
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Apply Leave',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: RefreshIndicator(
            color: _primaryBlue,
            onRefresh: _viewModel.refresh,
            child: _buildBody(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.applications.isEmpty) {
      return const _LoadingView();
    }

    if (_viewModel.error != null && _viewModel.summary == null) {
      return _StateView(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to load leaves',
        message: _viewModel.error!,
        actionLabel: 'Try Again',
        onAction: _viewModel.refresh,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 240) {
          _viewModel.loadMore();
        }
        return false;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        children: [
          _buildOverview(),
          const SizedBox(height: 20),
          _buildBalances(),
          const SizedBox(height: 22),
          _buildApplicationsHeader(),
          const SizedBox(height: 12),
          _buildStatusFilters(),
          const SizedBox(height: 14),
          if (_viewModel.error != null) ...[
            _ErrorBanner(message: _viewModel.error!),
            const SizedBox(height: 12),
          ],
          if (_viewModel.applications.isEmpty)
            _StateView(
              icon: Icons.event_available_outlined,
              title: 'No leave applications',
              message:
              'Your ${_viewModel.selectedStatus.toLowerCase()} leave '
                  'applications will appear here.',
            )
          else
            ..._viewModel.applications.map(_buildApplicationCard),
          if (_viewModel.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(color: _primaryBlue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final summary = _viewModel.summary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, _accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261B5FE0),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.beach_access_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary?.employeeName.isNotEmpty == true
                      ? summary!.employeeName
                      : 'Employee',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary?.company ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  '${summary?.counts.open ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Pending',
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalances() {
    final balances = _viewModel.summary?.balances ?? [];
    if (balances.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Available Balance',
          subtitle: 'Your current leave availability',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: balances.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final balance = balances[index];
              return Container(
                width: 150,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatNumber(balance.balance),
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'days',
                          style: TextStyle(
                            color: Color(0xFF7A8598),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      balance.leaveType,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsHeader() {
    return const _SectionTitle(
      title: 'Leave Applications',
      subtitle: 'Track your requests and approvals',
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LeaveViewModel.statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = LeaveViewModel.statuses[index];
          final selected = _viewModel.selectedStatus == status;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => _viewModel.changeStatus(status),
            label: Text('$status  ${_viewModel.countFor(status)}'),
            selectedColor: _primaryBlue,
            backgroundColor: Colors.white,
            side: BorderSide(color: selected ? _primaryBlue : _border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(LeaveApplicationModel application) {
    final statusColor = _statusColor(application.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => _openDetails(application),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              application.leaveType,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(
                            label: application.status,
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.date_range_outlined,
                            size: 15,
                            color: Color(0xFF7A8598),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${_formatDate(application.fromDate)}  →  '
                                  '${_formatDate(application.toDate)}',
                              style: const TextStyle(
                                color: Color(0xFF59657A),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${_formatNumber(application.totalLeaveDays)} '
                            '${application.totalLeaveDays == 1 ? 'day' : 'days'}'
                            '${application.halfDay ? '  •  Half-day included' : ''}',
                        style: const TextStyle(
                          color: _primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 13),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA4B5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF12805C);
      case 'Rejected':
        return const Color(0xFFD13B45);
      case 'Cancelled':
        return const Color(0xFF6E7787);
      default:
        return const Color(0xFFE58A00);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${_months[date.month - 1]} ${date.year}';
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF7A8598), fontSize: 12),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB72C37)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB72C37)),
            ),
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
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 260),
        Center(child: CircularProgressIndicator(color: _primaryBlue)),
      ],
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      children: [
        Icon(icon, size: 50, color: const Color(0xFFAAB3C2)),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6D778A), height: 1.4),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ],
    );
  }
}
