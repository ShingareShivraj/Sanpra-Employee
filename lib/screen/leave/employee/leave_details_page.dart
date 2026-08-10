import 'package:flutter/material.dart';

import '../../../model/leaves/leave_application_model.dart';
import 'leave_details_viewmodel.dart';

const _primaryBlue = Color(0xFF1B5FE0);
const _accentBlue = Color(0xFF4E8CFF);
const _ink = Color(0xFF14213D);
const _background = Color(0xFFF5F7FB);
const _border = Color(0xFFE4EAF3);
const _danger = Color(0xFFD13B45);

class LeaveDetailsPage extends StatefulWidget {
  const LeaveDetailsPage({
    super.key,
    required this.applicationName,
  });

  final String applicationName;

  @override
  State<LeaveDetailsPage> createState() => _LeaveDetailsPageState();
}

class _LeaveDetailsPageState extends State<LeaveDetailsPage> {
  late final LeaveDetailsViewModel _viewModel;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _viewModel = LeaveDetailsViewModel(widget.applicationName)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirmCancellation() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _danger),
              SizedBox(width: 10),
              Expanded(child: Text('Cancel application?')),
            ],
          ),
          content: const Text(
            'This pending leave request will be cancelled. '
                'This action cannot be undone.',
            style: TextStyle(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Leave'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _danger),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancel Leave'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;
    final success = await _viewModel.cancel();
    if (!mounted) return;

    if (success) {
      _hasChanged = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave application cancelled.')),
      );
    }
  }

  void _closePage() {
    Navigator.of(context).pop(_hasChanged);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) _closePage();
          },
          child: Scaffold(
            backgroundColor: _background,
            appBar: AppBar(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Leave Details',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _viewModel.isLoading ? null : _viewModel.load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomAction(),
            body: _buildBody(),
          ),
        );
      },
    );
  }

  Widget? _buildBottomAction() {
    if (_viewModel.application?.canCancel != true) return null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: OutlinedButton.icon(
          onPressed:
          _viewModel.isCancelling ? null : _confirmCancellation,
          style: OutlinedButton.styleFrom(
            foregroundColor: _danger,
            side: const BorderSide(color: _danger),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: _viewModel.isCancelling
              ? const SizedBox.square(
            dimension: 19,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _danger,
            ),
          )
              : const Icon(Icons.cancel_outlined),
          label: Text(
            _viewModel.isCancelling
                ? 'Cancelling...'
                : 'Cancel Application',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.application == null) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }

    final application = _viewModel.application;
    if (application == null) {
      return _DetailsErrorView(
        message: _viewModel.error ?? 'Leave application not found.',
        onRetry: _viewModel.load,
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _viewModel.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _buildHero(application),
          const SizedBox(height: 14),
          _buildInformationSection(application),
          const SizedBox(height: 12),
          _DetailsSection(
            title: 'Reason',
            icon: Icons.notes_rounded,
            child: Text(
              application.reason.trim().isEmpty
                  ? 'No reason provided.'
                  : application.reason,
              style: const TextStyle(
                color: Color(0xFF4F5B70),
                height: 1.5,
              ),
            ),
          ),
          if (application.leaveApprover.isNotEmpty ||
              application.availableBalance != null) ...[
            const SizedBox(height: 12),
            _buildApprovalSection(application),
          ],
          if (application.approvalHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTimeline(application.approvalHistory),
          ],
          if (_viewModel.error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _viewModel.error!),
          ],
        ],
      ),
    );
  }

  Widget _buildHero(LeaveApplicationModel application) {
    final statusColor = _statusColor(application.status);
    return Container(
      padding: const EdgeInsets.all(19),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  application.leaveType,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  application.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatDate(application.fromDate)}  →  '
                      '${_formatDate(application.toDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroMetric(
                icon: Icons.timelapse_rounded,
                label:
                '${_formatNumber(application.totalLeaveDays)} '
                    '${application.totalLeaveDays == 1 ? 'day' : 'days'}',
              ),
              if (application.halfDay)
                const _HeroMetric(
                  icon: Icons.schedule_rounded,
                  label: 'Half-day included',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(LeaveApplicationModel application) {
    return _DetailsSection(
      title: 'Leave Information',
      icon: Icons.event_note_rounded,
      child: Column(
        children: [
          _InfoRow(label: 'Application ID', value: application.name),
          _InfoRow(label: 'Leave Type', value: application.leaveType),
          _InfoRow(
            label: 'From Date',
            value: _formatDate(application.fromDate),
          ),
          _InfoRow(
            label: 'To Date',
            value: _formatDate(application.toDate),
          ),
          if (application.halfDay)
            _InfoRow(
              label: 'Half-day Date',
              value: _formatDate(application.halfDayDate),
            ),
          _InfoRow(
            label: 'Total Leave',
            value:
            '${_formatNumber(application.totalLeaveDays)} '
                '${application.totalLeaveDays == 1 ? 'day' : 'days'}',
          ),
          _InfoRow(
            label: 'Applied On',
            value: _formatDate(application.postingDate),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSection(LeaveApplicationModel application) {
    return _DetailsSection(
      title: 'Approval',
      icon: Icons.verified_user_outlined,
      child: Column(
        children: [
          if (application.leaveApprover.isNotEmpty)
            _InfoRow(
              label: 'Leave Approver',
              value: application.leaveApprover,
              showDivider: application.availableBalance != null,
            ),
          if (application.availableBalance != null)
            _InfoRow(
              label: 'Available Balance',
              value: '${_formatNumber(application.availableBalance!)} days',
              showDivider: false,
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<LeaveApprovalHistoryModel> history) {
    return _DetailsSection(
      title: 'Activity',
      icon: Icons.history_rounded,
      child: Column(
        children: List.generate(history.length, (index) {
          final item = history[index];
          final isLast = index == history.length - 1;
          final user = item.userName.isNotEmpty ? item.userName : item.user;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: _primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: const Color(0xFFDCE5F5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.content,
                          style: const TextStyle(
                            color: _ink,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$user  •  ${_formatDateTime(item.creation)}',
                          style: const TextStyle(
                            color: Color(0xFF8A94A6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF12805C);
      case 'Rejected':
        return _danger;
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

  String _formatDateTime(DateTime? date) {
    if (date == null) return '—';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)}, $hour:$minute';
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

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryBlue, size: 19),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 118,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7A8598),
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.trim().isEmpty ? '—' : value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 21, color: Color(0xFFEDF0F5)),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

class _DetailsErrorView extends StatelessWidget {
  const _DetailsErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: _danger,
            ),
            const SizedBox(height: 13),
            const Text(
              'Unable to load details',
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
              style: const TextStyle(color: Color(0xFF6D778A), height: 1.4),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
