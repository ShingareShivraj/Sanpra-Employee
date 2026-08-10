import 'package:flutter/material.dart';

import '../../../model/leaves/leave_application_model.dart';
import 'leave_approval_details_page.dart';
import 'leave_management_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _accent = Color(0xFF4E8CFF);
const _ink = Color(0xFF14213D);
const _bg = Color(0xFFF5F7FB);

class LeaveManagementPage extends StatefulWidget {
  const LeaveManagementPage({super.key});

  @override
  State<LeaveManagementPage> createState() => _LeaveManagementPageState();
}

class _LeaveManagementPageState extends State<LeaveManagementPage> {
  late final LeaveManagementViewModel vm;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    vm = LeaveManagementViewModel()..initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    vm.dispose();
    super.dispose();
  }

  Future<void> _open(LeaveApplicationModel item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LeaveApprovalDetailsPage(applicationName: item.name),
      ),
    );
    if (changed == true) vm.refresh();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: vm,
    builder: (_, __) => Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leave Approvals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Review employee requests',
                style: TextStyle(fontSize: 11.5, color: Color(0xD9FFFFFF))),
          ],
        ),
        actions: [
          IconButton(
            onPressed: vm.isLoading ? null : vm.refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: vm.refresh,
        child: _body(),
      ),
    ),
  );

  Widget _body() {
    if (vm.isLoading && vm.access == null) return _loading();
    if (vm.error != null && vm.access == null) {
      return _state(Icons.cloud_off_rounded, 'Unable to load approvals', vm.error!,
          button: 'Try Again', onTap: vm.initialize);
    }
    if (!vm.isApprover) {
      return _state(
        Icons.admin_panel_settings_outlined,
        'Leave Approver access required',
        'Only a user with the Leave Approver role can view and process company leave requests.',
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 240) vm.loadMore();
        return false;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _overview(),
          const SizedBox(height: 18),
          _queueHeading(),
          const SizedBox(height: 10),
          _search(),
          if (vm.error != null) ...[
            const SizedBox(height: 10),
            _errorStrip(vm.error!),
          ],
          const SizedBox(height: 12),
          if (vm.isLoading)
            const Padding(
              padding: EdgeInsets.all(42),
              child: Center(child: CircularProgressIndicator(color: _blue)),
            )
          else if (vm.applications.isEmpty)
            _empty()
          else
            ...vm.applications.map(_card),
          if (vm.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator(color: _blue)),
            ),
        ],
      ),
    );
  }

  Widget _queueHeading() => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Requests',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Review the oldest applications first',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF748095)),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${vm.applications.length} shown',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: _blue,
          ),
        ),
      ),
    ],
  );

  Widget _overview() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_blue, _accent]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Color(0x261B5FE0), blurRadius: 18, offset: Offset(0, 8)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 27),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Company Leave Desk',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(vm.company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 12.5)),
          ]),
        ),
      ]),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          _metric('Pending', vm.summary?.counts.open ?? 0),
          _divider(),
          _metric('Approved', vm.summary?.counts.approved ?? 0),
          _divider(),
          _metric('Rejected', vm.summary?.counts.rejected ?? 0),
        ]),
      ),
    ]),
  );

  Widget _metric(String label, int value) => Expanded(
    child: Column(children: [
      Text('$value',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 11.5)),
    ]),
  );

  Widget _divider() => Container(width: 1, height: 34, color: const Color(0x40FFFFFF));

  Widget _search() => TextField(
    controller: _searchController,
    onChanged: vm.updateSearch,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'Search employee or application ID',
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF909AAA)),
      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF708099)),
      suffixIcon: vm.search.isEmpty
          ? null
          : IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () {
          _searchController.clear();
          vm.clearSearch();
        },
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E6EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E6EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    ),
  );

  Widget _card(LeaveApplicationModel item) => Card(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE5EAF2)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _open(item),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFFEAF1FF),
            child: Text(_initials(item.employeeName),
                style: const TextStyle(color: _blue, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(item.employeeName.isEmpty ? item.employee : item.employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _ink, fontSize: 14.5, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                _pendingChip(),
              ]),
              const SizedBox(height: 5),
              Wrap(
                spacing: 7,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    item.leaveType,
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.halfDay) _halfDayChip(),
                ],
              ),
              const SizedBox(height: 7),
              Row(children: [
                const Icon(Icons.date_range_rounded, size: 15, color: Color(0xFF748095)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text('${_date(item.fromDate)}  →  ${_date(item.toDate)}',
                      style: const TextStyle(color: Color(0xFF59657A), fontSize: 12)),
                ),
                Flexible(
                  child: Text(
                    '${_number(item.totalLeaveDays)} '
                        '${item.totalLeaveDays == 1 ? 'day' : 'days'}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 7),
              Text(item.name,
                  style: const TextStyle(color: Color(0xFF929BAA), fontSize: 10.5)),
            ]),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFA3ACBA)),
        ]),
      ),
    ),
  );

  Widget _halfDayChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFF0EBFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'Half day',
      style: TextStyle(
        color: Color(0xFF6C4EC7),
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _pendingChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3DC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text('Pending',
        style: TextStyle(color: Color(0xFFD77A00), fontSize: 10, fontWeight: FontWeight.w800)),
  );

  Widget _empty() => _state(
    Icons.task_alt_rounded,
    vm.search.isEmpty ? 'No pending requests' : 'No matching requests',
    vm.search.isEmpty
        ? 'All company leave applications have been reviewed.'
        : 'Try a different employee name or application ID.',
  );

  Widget _loading() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 260),
      const Center(child: CircularProgressIndicator(color: _blue)),
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

  Widget _state(IconData icon, String title, String message,
      {String? button, VoidCallback? onTap}) =>
      ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 90),
        children: [
          Icon(icon, size: 52, color: const Color(0xFFAAB3C2)),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6D778A), height: 1.45)),
          if (button != null)
            Center(child: TextButton(onPressed: onTap, child: Text(button))),
        ],
      );

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'E';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  String _date(DateTime? date) => date == null
      ? '—'
      : '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';

  String _number(double number) =>
      number == number.roundToDouble() ? number.toInt().toString() : number.toStringAsFixed(1);

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}
