import 'package:flutter/material.dart';

import '../../../model/leaves/leave_application_model.dart';
import 'leave_approval_details_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _ink = Color(0xFF14213D);
const _bg = Color(0xFFF5F7FB);
const _green = Color(0xFF12805C);
const _red = Color(0xFFD13B45);

class LeaveApprovalDetailsPage extends StatefulWidget {
  const LeaveApprovalDetailsPage({
    super.key,
    required this.applicationName,
  });

  final String applicationName;

  @override
  State<LeaveApprovalDetailsPage> createState() => _LeaveApprovalDetailsPageState();
}

class _LeaveApprovalDetailsPageState extends State<LeaveApprovalDetailsPage> {
  late final LeaveApprovalDetailsViewModel vm;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    vm = LeaveApprovalDetailsViewModel(widget.applicationName)..load();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<bool> _onBack() async {
    Navigator.pop(context, _changed);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, child) {
        return WillPopScope(
          onWillPop: _onBack,
          child: Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text('Approval Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              leading: IconButton(
                onPressed: () => Navigator.pop(context, _changed),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              actions: [
                IconButton(
                  onPressed: vm.isLoading || vm.isProcessing ? null : vm.load,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: RefreshIndicator(color: _blue, onRefresh: vm.load, child: _body()),
            bottomNavigationBar: _actions(),
          ),
        );
      },
    );
  }

  Widget _body() {
    if (vm.isLoading && vm.application == null) return _loading();
    if (vm.application == null) {
      return _state(Icons.description_outlined, 'Unable to load application',
          vm.error ?? 'The leave application is unavailable.',
          button: 'Try Again', onTap: vm.load);
    }
    final item = vm.application!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _hero(item),
        if (vm.error != null) ...[const SizedBox(height: 12), _errorStrip(vm.error!)],
        const SizedBox(height: 14),
        _section('Leave Information', Icons.event_note_rounded, [
          _row('Leave type', item.leaveType),
          _row('From date', _date(item.fromDate)),
          _row('To date', _date(item.toDate)),
          _row('Duration', '${_number(item.totalLeaveDays)} day${item.totalLeaveDays == 1 ? '' : 's'}'),
          if (item.halfDay) _row('Half-day date', _date(item.halfDayDate)),
          if (item.availableBalance != null)
            _row('Available balance', '${_number(item.availableBalance!)} days', valueColor: _blue),
        ]),
        const SizedBox(height: 12),
        _textSection('Reason for Leave', Icons.notes_rounded,
            item.reason.isEmpty ? 'No reason provided.' : item.reason),
        const SizedBox(height: 12),
        _section('Application Information', Icons.badge_outlined, [
          _row('Application ID', item.name),
          _row('Employee ID', item.employee),
          _row('Company', item.company),
          _row('Applied on', _dateTime(item.creation)),
          if (item.leaveApprover.isNotEmpty) _row('Leave approver', item.leaveApprover),
        ]),
        if (item.approvalHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          _history(item.approvalHistory),
        ],
        if (!item.canApprove && !item.canReject) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _statusColor(item.status).withOpacity(.08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _statusColor(item.status).withOpacity(.20)),
            ),
            child: Row(children: [
              Icon(Icons.lock_outline_rounded, color: _statusColor(item.status), size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text('This application has already been ${item.status.toLowerCase()} and cannot be processed again.',
                    style: TextStyle(color: _statusColor(item.status), fontSize: 12.5, height: 1.35)),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _hero(LeaveApplicationModel item) {
    final color = _statusColor(item.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue, Color(0xFF4E8CFF)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x261B5FE0), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0x26FFFFFF),
            child: Text(_initials(item.employeeName),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.employeeName.isEmpty ? item.employee : item.employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(item.employee,
                  style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 12)),
            ]),
          ),
          _statusBadge(item.status, color),
        ]),
        const SizedBox(height: 17),
        Container(height: 1, color: const Color(0x38FFFFFF)),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.beach_access_rounded, color: Colors.white, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.leaveType,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          Text('${_number(item.totalLeaveDays)} day${item.totalLeaveDays == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _box(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(title, icon),
      const SizedBox(height: 13),
      ...children,
    ]),
  );

  Widget _statusBadge(String status, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _textSection(String title, IconData icon, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _box(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(title, icon),
      const SizedBox(height: 12),
      Text(text, style: const TextStyle(color: Color(0xFF4F5B70), fontSize: 13.5, height: 1.5)),
    ]),
  );

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
    Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, color: _blue, size: 18),
    ),
    const SizedBox(width: 9),
    Text(title, style: const TextStyle(color: _ink, fontSize: 14.5, fontWeight: FontWeight.w800)),
  ]);

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 112,
        child: Text(label, style: const TextStyle(color: Color(0xFF7C8799), fontSize: 12.5)),
      ),
      Expanded(
        child: Text(value,
            textAlign: TextAlign.right,
            style: TextStyle(color: valueColor ?? _ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    ]),
  );

  Widget _history(List<LeaveApprovalHistoryModel> entries) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _box(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Approval Activity', Icons.history_rounded),
      const SizedBox(height: 15),
      ...entries.asMap().entries.map((entry) {
        final item = entry.value;
        final last = entry.key == entries.length - 1;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            const CircleAvatar(radius: 5, backgroundColor: _blue),
            if (!last) Container(width: 1.5, height: 55, color: const Color(0xFFDDE4EE)),
          ]),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 13),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.content,
                    style: const TextStyle(color: _ink, fontSize: 12.5, height: 1.4)),
                const SizedBox(height: 4),
                Text('${item.userName.isEmpty ? item.user : item.userName} • ${_dateTime(item.creation)}',
                    style: const TextStyle(color: Color(0xFF8993A3), fontSize: 10.5)),
              ]),
            ),
          ),
        ]);
      }),
    ]),
  );

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE5EAF2)),
  );

  Widget? _actions() {
    final item = vm.application;
    if (item == null || (!item.canApprove && !item.canReject)) return null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE3E8F0))),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;
            final rejectButton = _rejectButton(compact);
            final approveButton = _approveButton(compact);

            if (compact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  approveButton,
                  const SizedBox(height: 8),
                  rejectButton,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: rejectButton),
                const SizedBox(width: 11),
                Expanded(flex: 2, child: approveButton),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _rejectButton(bool fullWidth) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: vm.canReject ? _reject : null,
        icon: vm.isRejecting
            ? const SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _red,
          ),
        )
            : const Icon(Icons.close_rounded),
        label: const Text('Reject'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _red,
          side: const BorderSide(color: _red),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Widget _approveButton(bool fullWidth) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: vm.canApprove ? _approve : null,
        icon: vm.isApproving
            ? const SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.check_rounded),
        label: const Text('Approve Leave'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Future<void> _approve() async {
    final remark = await _remarkDialog(
      title: 'Approve Leave',
      subtitle: 'Add an optional remark for the employee.',
      hint: 'Approval remark (optional)',
      confirmText: 'Approve',
      color: _green,
      isRequired: false,
    );
    if (remark == null) return;
    final ok = await vm.approve(remark: remark);
    if (!mounted) return;
    if (ok) {
      _changed = true;
      _snack('Leave application approved.', _green);
    } else if (vm.error != null) {
      _snack(vm.error!, _red);
    }
  }

  Future<void> _reject() async {
    final reason = await _remarkDialog(
      title: 'Reject Leave',
      subtitle: 'A clear reason is required and will be shared with the employee.',
      hint: 'Reason for rejection',
      confirmText: 'Reject Leave',
      color: _red,
      isRequired: true,
    );
    if (reason == null) return;
    final ok = await vm.reject(reason);
    if (!mounted) return;
    if (ok) {
      _changed = true;
      _snack('Leave application rejected.', _red);
    } else if (vm.error != null) {
      _snack(vm.error!, _red);
    }
  }

  Future<String?> _remarkDialog({
    required String title,
    required String subtitle,
    required String hint,
    required String confirmText,
    required Color color,
    required bool isRequired,
  }) async {
    final controller = TextEditingController();
    String? validation;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF69758A),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: hint,
                    errorText: validation,
                    filled: true,
                    fillColor: const Color(0xFFF7F9FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (isRequired && value.isEmpty) {
                  setDialogState(() => validation = 'Please enter a reason.');
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
              child: Text(confirmText),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  void _snack(String text, Color color) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), backgroundColor: color));

  Widget _loading() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: const [
      SizedBox(height: 260),
      Center(child: CircularProgressIndicator(color: _blue)),
    ],
  );

  Widget _state(IconData icon, String title, String message,
      {String? button, VoidCallback? onTap}) =>
      ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 90),
        children: [
          Icon(icon, size: 52, color: const Color(0xFFAAB3C2)),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6D778A), height: 1.45)),
          if (button != null) Center(child: TextButton(onPressed: onTap, child: Text(button))),
        ],
      );

  Widget _errorStrip(String message) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFECEE), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Color(0xFFB72C37), size: 19),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB72C37), fontSize: 12.5))),
    ]),
  );

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved': return _green;
      case 'Rejected': return _red;
      case 'Cancelled': return const Color(0xFF6E7787);
      default: return const Color(0xFFE58A00);
    }
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'E';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  String _date(DateTime? date) => date == null
      ? '—'
      : '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';

  String _dateTime(DateTime? date) {
    if (date == null) return '—';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_date(date)}, $hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _number(double number) =>
      number == number.roundToDouble() ? number.toInt().toString() : number.toStringAsFixed(1);

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}
