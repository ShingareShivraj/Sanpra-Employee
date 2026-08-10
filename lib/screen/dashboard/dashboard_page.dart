import 'package:flutter/material.dart';

import '../issues/company_issues_screen.dart';
import '../issues/issue_screen.dart';
import '../login/login_page.dart';
import '../tasks/employee/my_tasks_screen.dart';
import '../tasks/employee/task_details_screen.dart';
import '../tasks/manager/task_dashboard_screen.dart';
import 'dashboard_viewmodel.dart';
import '../todo/todo_screen.dart';
import '../profile/employee_profile_screen.dart';
import '../attendance/attendance_page.dart';
import '../leave/employee/leave_page.dart';
import '../leave/approver/leave_management_page.dart';
import '../../services/secure_storage_service.dart';

// ---- Design tokens ----
const kBluePrimary = Color(0xFF1B5FE0);
const kBlueAccent = Color(0xFF4E8CFF);
const kBlueDark = Color(0xFF123FA0);
const kBgGrey = Color(0xFFF4F6FA);
const kCardRadius = 16.0;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardViewModel vm = DashboardViewModel();
  bool _isLeaveApprover = false;

  @override
  void initState() {
    super.initState();
    vm.loadData();
    _loadLeaveRole();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveRole() async {
    final roles =
    await SecureStorageService.instance.getRoles();

    if (!mounted) return;

    setState(() {
      _isLeaveApprover =
          roles.contains('Leave Approver');
    });
  }
  Future<void> _openLeave() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LeavePage(),
      ),
    );
  }
  Future<void> _openLeaveManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LeaveManagementPage(),
      ),
    );
  }

  bool get _isCheckedIn {
    final s = vm.attendanceStatus.toLowerCase();

    if (s.contains('not checked') ||
        s.contains('checked out') ||
        s.contains('absent')) {
      return false;
    }

    return s.contains('checked in') || s.contains('present');
  }

  String _checkInTimeLabel() {
    if (vm.checkInTime.isEmpty) {
      return "--:--";
    }

    return vm.checkInTime;
  }

  Future<void> _handleCheckIn() async {
    try {
      await vm.checkIn();
      if (!mounted) return;
      _showSnack(vm.attendanceStatus);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _handleCheckOut() async {
    try {
      await vm.checkOut();
      if (!mounted) return;
      _showSnack(vm.attendanceStatus);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade600 : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Text(msg),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await vm.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _openTasks() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyTasksScreen(),
      ),
    );

    // Refresh dashboard count when returning from Tasks.
    await vm.loadDashboardTasks();
  }

  Future<void> _openTaskDetails(String taskName) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(taskName: taskName),
      ),
    );

    if (changed == true) {
      await vm.loadDashboardTasks();
    }
  }

  Future<void> _openTaskManager() async {
    if (!vm.isTaskManager) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskDashboardScreen(),
      ),
    );

    await vm.loadDashboardTasks();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (_, __) {
        if (vm.loading) {
          return const Scaffold(
            backgroundColor: kBgGrey,
            body: Center(child: CircularProgressIndicator(color: kBluePrimary)),
          );
        }

        return Scaffold(
          backgroundColor: kBgGrey,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: kBluePrimary,
              onRefresh: () async => vm.loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: _buildCheckInCard(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // _buildStatsRow(),
                          // const SizedBox(height: 18),
                          //  _sectionTitle('Profile'),
                          // const SizedBox(height: 10),
                          // _buildProfileCard(),
                          // const SizedBox(height: 18),
                          _sectionTitle('Quick Actions'),
                          const SizedBox(height: 10),
                          _buildQuickActions(),
                          const SizedBox(height: 18),
                          _sectionTitle('Pending Actions'),
                          const SizedBox(height: 10),
                          _buildPendingActions(),
                          const SizedBox(height: 18),
                          // _sectionTitle('Today at a Glance'),
                          // const SizedBox(height: 10),
                          // _buildTodayOverview(),
                          // const SizedBox(height: 22),
                          // _buildAttendanceDetailCard(),
                          // const SizedBox(height: 14),
                          // _buildNoticeCard(),
                          // const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr =
        '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month]} ${now.year}';
    final checkInTime = _checkInTimeLabel();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBlueDark, kBluePrimary, kBlueAccent],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // InkWell(
              //   borderRadius: BorderRadius.circular(8),
              //   onTap: () => Scaffold.of(context).openDrawer(),
              //   child: const Icon(Icons.menu, color: Colors.white, size: 26),
              // ),
              Row(
                children: [
                  // Stack(
                  //   clipBehavior: Clip.none,
                  //   children: [
                  //     const Icon(Icons.notifications_none_rounded,
                  //         color: Colors.white, size: 26),
                  //     Positioned(
                  //       right: -2,
                  //       top: -2,
                  //       child: Container(
                  //         padding: const EdgeInsets.all(3),
                  //         decoration: const BoxDecoration(
                  //           color: Colors.redAccent,
                  //           shape: BoxShape.circle,
                  //         ),
                  //         constraints:
                  //         const BoxConstraints(minWidth: 14, minHeight: 14),
                  //         child: const Text(
                  //           '',
                  //           style: TextStyle(fontSize: 8, color: Colors.white),
                  //           textAlign: TextAlign.center,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: _handleLogout,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.logout, color: kBluePrimary, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Text(
              //   'Good Morning, ',
              //   style: TextStyle(
              //       color: Colors.white.withOpacity(0.92), fontSize: 15),
              // ),
              // const Text('👋', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            vm.employeeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            vm.designation,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: Colors.white.withOpacity(0.9), size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        dateStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.95), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHECK IN TIME',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.login_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text(checkInTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Check-in card ----------------
  Widget _buildCheckInCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kBluePrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: kBluePrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Location Verified',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade600, size: 15),
                    ],
                  ),
                  // const SizedBox(height: 3),
                  // Text(
                  //   vm.department.isNotEmpty ? vm.department : vm.company,
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                  // ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _isCheckedIn
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: vm.attendanceLoading ? null : _handleCheckOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: vm.attendanceLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Check Out',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.attendanceStatus,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: vm.attendanceLoading ? null : _handleCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: vm.attendanceLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Check In',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                // const SizedBox(height: 4),
                // Text(
                //   vm.attendanceStatus.isNotEmpty
                //       ? vm.attendanceStatus
                //       : 'Not Checked In Yet',
                //   style: TextStyle(
                //       color: Colors.grey.shade600, fontSize: 11),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Stats ----------------
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.event_available_rounded,
            iconColor: Colors.green,
            value: _isCheckedIn ? 'Present' : 'Absent',
            label: 'Today Status',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.assignment_turned_in_rounded,
            iconColor: kBluePrimary,
            value: vm.attendanceStatus.isNotEmpty ? vm.attendanceStatus : '-',
            label: 'Status',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ---------------- Section title ----------------
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  // ---------------- Profile card ----------------
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vm.employeeName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _infoRow(Icons.badge_outlined, vm.designation),
          _infoRow(Icons.apartment_rounded, vm.department),
          _infoRow(Icons.business_rounded, vm.company),
          _infoRow(Icons.email_outlined, vm.email),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: kBluePrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Quick actions ----------------
  Widget _buildQuickActions() {
    final actions = <({IconData icon, String label, VoidCallback onTap})>[
      (
      icon: Icons.person_pin_circle_rounded,
      label: 'Attendance',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AttendancePage(),
          ),
        );
      },
      ),
      (
      icon: Icons.assignment_outlined,
      label: 'My Tasks',
      onTap: _openTasks,
      ),
      (
      icon: Icons.checklist_rounded,
      label: 'ToDos',
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TodoScreen(),
          ),
        );
      },
      ),
      if (vm.isTaskManager)
        (
        icon: Icons.manage_accounts_rounded,
        label: 'Task Manager',
        onTap: _openTaskManager,
        ),
      (
      icon: Icons.report_problem_outlined,
      label: 'Issues',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const IssueScreen(),
          ),
        );
      },
      ),
      if (vm.isIssueManager)
        (
        icon: Icons.support_agent_rounded,
        label: 'Issue Manager',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CompanyIssuesScreen(),
            ),
          );
        },
        ),

      (
      icon: Icons.calendar_month_rounded,
      label: 'Leave',
      onTap: _openLeave,
      ),
      if (_isLeaveApprover)
        (
        icon: Icons.manage_accounts_rounded,
        label: 'Leave Management',
        onTap: _openLeaveManagement,
        ),
      (
      icon: Icons.account_balance_wallet_outlined,
      label: 'Payroll',
      onTap: () {},
      ),
      (
      icon: Icons.campaign_outlined,
      label: 'Notice Board',
      onTap: () {},
      ),
      (
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      onTap: () {},
      ),
      (
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Chat',
      onTap: () {},
      ),
      (
      icon: Icons.person_outline_rounded,
      label: 'Profile',
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EmployeeProfileScreen(),
          ),
        );
      },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: action.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: kBluePrimary, size: 22),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- Pending actions ----------------
  Widget _buildPendingActions() {
    final String taskSubtitle;

    if (vm.todayTaskCount == 0) {
      taskSubtitle = 'No pending tasks for today';
    } else if (vm.todayTaskCount == 1) {
      taskSubtitle = '1 task pending for today';
    } else {
      taskSubtitle = '${vm.todayTaskCount} tasks pending for today';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Today's tasks heading
          InkWell(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(kCardRadius),
            ),
            onTap: _openTasks,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7)
                              .withOpacity(0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.task_alt_rounded,
                          color: Color(0xFF6C5CE7),
                          size: 20,
                        ),
                      ),
                      if (vm.todayTaskCount > 0)
                        Positioned(
                          right: -7,
                          top: -7,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              vm.todayTaskCount > 99
                                  ? '99+'
                                  : vm.todayTaskCount.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete today’s tasks',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          taskSubtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: vm.todayTaskCount == 0
                                ? Colors.green.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          // Today's individual tasks
          if (vm.todayTasks.isNotEmpty) ...[
            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Column(
                children: vm.todayTasks.map((task) {
                  final title = task.subject.trim().isNotEmpty
                      ? task.subject
                      : task.description.trim().isNotEmpty
                      ? task.description
                      : task.name;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _openTaskDetails(task.name),
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF20A464).withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        color: Color(0xFF20A464),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: task.status.trim().isEmpty
                        ? null
                        : Text(
                      task.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          Divider(
            height: 1,
            indent: 66,
            color: Colors.grey.shade200,
          ),

          _buildPendingActionRow(
            icon: Icons.timer_outlined,
            title: 'Submit timesheet',
            subtitle: 'Add today’s work hours',
            color: const Color(0xFFF39C12),
            onTap: () {},
          ),

          Divider(
            height: 1,
            indent: 66,
            color: Colors.grey.shade200,
          ),

          _buildPendingActionRow(
            icon: Icons.event_note_rounded,
            title: 'Attendance regularization',
            subtitle: 'Review missing or incorrect punches',
            color: const Color(0xFFE74C3C),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
  // ---------------- Today overview ----------------
  Widget _buildTodayOverview() {
    return Row(
      children: [
        Expanded(
          child: _overviewCard(
            icon: Icons.verified_rounded,
            color: _isCheckedIn ? Colors.green : Colors.orange,
            value: _isCheckedIn ? 'Present' : 'Not In',
            label: 'Attendance',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _overviewCard(
            icon: Icons.work_history_outlined,
            color: kBluePrimary,
            value: vm.todayTaskCount.toString(),
            label: 'Open Tasks',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _overviewCard(
            icon: Icons.beach_access_outlined,
            color: const Color(0xFF8E44AD),
            value: '--',
            label: 'Leave Balance',
          ),
        ),
      ],
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 7),
          Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ---------------- Attendance detail card ----------------
  Widget _buildAttendanceDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Attendance",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.more_vert, color: Colors.grey.shade500, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          _detailRow(Icons.login_rounded, 'Status',
              vm.attendanceStatus.isNotEmpty ? vm.attendanceStatus : '--'),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------- Notice card ----------------
  Widget _buildNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBluePrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded, color: kBluePrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latest Notice',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                const Text(
                  'Welcome to your dashboard',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
