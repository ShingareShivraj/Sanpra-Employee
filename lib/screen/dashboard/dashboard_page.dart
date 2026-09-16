import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/secure_storage_service.dart';
import '../action_needed/actions_needed_screen.dart';
import '../attendance/attendance_page.dart';
import '../chat/chat_screen.dart';
import '../chat/manager/chat_manager_screen.dart';
import '../issues/company_issues_screen.dart';
import '../issues/issue_screen.dart';
import '../knowledge_hub/knowledge_hub_screen.dart';
import '../leave/approver/leave_management_page.dart';
import '../leave/employee/leave_page.dart';
import '../login/login_page.dart';
import '../notes/notes_screen.dart';
import '../payroll/salary_page.dart';
import '../performance/performance_screen.dart';
import '../profile/employee_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/employee/my_tasks_screen.dart';
import '../tasks/employee/task_details_screen.dart';
import '../tasks/manager/task_dashboard_screen.dart';
import '../todo/todo_screen.dart';
import 'dashboard_viewmodel.dart';
import '../../model/my_work_model.dart';
import '../work/my_work_screen.dart';
import '../meeting/meeting_screen.dart';

const kBluePrimary = Color(0xFF1B5FE0);
const kBlueAccent = Color(0xFF4E8CFF);
const kBlueDark = Color(0xFF0B3FA8);
const kBgGrey = Color(0xFFF5F7FC);
const kTextPrimary = Color(0xFF111827);
const kTextSecondary = Color(0xFF667085);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardViewModel vm = DashboardViewModel();
  bool _isLeaveApprover = false;
  bool _canAccessMobileIssue = false;
  int _selectedTab = 0;
  Timer? _workTimer;
  Duration _workedDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    vm.loadData().then((_) {
      if (!mounted) return;

      if (_isCheckedIn) {
        _startWorkTimer();
      } else {
        _stopWorkTimer();
      }
    });

    _loadLeaveRole();
  }

  void _startWorkTimer() {
    _workTimer?.cancel();

    _updateWorkedDuration();

    _workTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _updateWorkedDuration(),
    );
  }

  void _stopWorkTimer() {
    _workTimer?.cancel();
    _workTimer = null;
  }

  void _updateWorkedDuration() {
    if (!_isCheckedIn || vm.checkInDateTime == null) {
      return;
    }

    final duration = DateTime.now().difference(
      vm.checkInDateTime!,
    );

    if (duration.isNegative) return;

    if (mounted) {
      setState(() {
        _workedDuration = duration;
      });
    }
  }
  String _formatWorkedDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes =
    (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
    (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    vm.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveRole() async {
    final roles = await SecureStorageService.instance.getRoles();

    if (!mounted) return;

    setState(() {
      // Existing role check.
      _isLeaveApprover = roles.contains('Leave Approver');

      // NEW: Employee can see the Issues button ONLY
      // when the "Mobile Issue" role is assigned.
      _canAccessMobileIssue = roles.contains('Mobile Issue');
    });
  }

  bool get _isCheckedIn {
    final status = vm.attendanceStatus.toLowerCase();
    if (status.contains('not checked') ||
        status.contains('checked out') ||
        status.contains('absent')) {
      return false;
    }
    return status.contains('checked in') || status.contains('present');
  }

  Future<void> _handleCheckIn() async {
    final now = DateTime.now();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(.45),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.16),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Small top handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D5DD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: kBluePrimary.withOpacity(.09),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.login_rounded,
                        color: kBluePrimary,
                        size: 25,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Title
                    const Text(
                      'Start your day?',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Ready to begin work?',
                      style: TextStyle(
                        color: kTextSecondary.withOpacity(.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Check-in information
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: kBgGrey,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFEAECF0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kBluePrimary.withOpacity(.09),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: kBluePrimary,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CHECK-IN TIME',
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .7,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Your current time',
                                  style: TextStyle(
                                    color: kTextPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('hh:mm a').format(now),
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kTextSecondary,
                              side: const BorderSide(
                                color: Color(0xFFD0D5DD),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: kBluePrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Check In'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      await vm.checkIn();

      if (mounted) {
        _startWorkTimer();
        _showSnack(vm.attendanceStatus);
      }
    } catch (error) {
      if (mounted) {
        _showSnack(error.toString(), isError: true);
      }
    }
  }

  Future<void> _handleCheckOut() async {
    final now = DateTime.now();

    Duration currentWorkedDuration = _workedDuration;

    if (vm.checkInDateTime != null) {
      final calculatedDuration =
      now.difference(vm.checkInDateTime!);

      if (!calculatedDuration.isNegative) {
        currentWorkedDuration = calculatedDuration;
      }
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(.45),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.16),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Small top handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D5DD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF79009).withOpacity(.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFF79009),
                        size: 25,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Title
                    const Text(
                      'End your day?',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'You are about to check out for today.',
                      style: TextStyle(
                        color: kTextSecondary.withOpacity(.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Attendance times
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kBgGrey,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFEAECF0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _CheckoutTimeInfo(
                                  label: 'CHECK-IN',
                                  value: vm.checkInTime.isEmpty
                                      ? '--:--'
                                      : vm.checkInTime,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 34,
                                color: const Color(0xFFE4E7EC),
                              ),
                              Expanded(
                                child: _CheckoutTimeInfo(
                                  label: 'CHECK-OUT',
                                  value: DateFormat('hh:mm a').format(now),
                                  alignEnd: true,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 13),

                          // Total worked
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: kBluePrimary.withOpacity(.07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: kBluePrimary.withOpacity(.10),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.timer_outlined,
                                    color: kBluePrimary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'TOTAL WORKED',
                                    style: TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatWorkedDuration(
                                    currentWorkedDuration,
                                  ),
                                  style: const TextStyle(
                                    color: kBluePrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kTextSecondary,
                              side: const BorderSide(
                                color: Color(0xFFD0D5DD),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFFF04438),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Check Out'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      await vm.checkOut();

      if (mounted) {
        _updateWorkedDuration();
        _stopWorkTimer();
        _showSnack(vm.attendanceStatus);
      }
    } catch (error) {
      if (mounted) {
        _showSnack(error.toString(), isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 104),
          backgroundColor: isError ? const Color(0xFFD92D20) : kTextPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
  Future<void> _openMyWork() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyWorkScreen(),
      ),
    );

    if (mounted) {
      await vm.loadDashboardWork();
    }
  }

  Future<void> _openTaskDetails(String taskName) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(taskName: taskName),
      ),
    );

    if (mounted) {
      await vm.loadDashboardWork();
    }
  }

  Future<void> _openWorkItem(MyWorkItemModel item) async {
    if (item.isTask) {
      final taskName = item.taskName;

      if (taskName == null || taskName.isEmpty) {
        _showSnack('Task ID is missing.', isError: true);
        return;
      }

      await _openTaskDetails(taskName);
      return;
    }

    // Ordinary ToDo is opened inside My Work, where it can be completed safely.
    await _openMyWork();
  }

  Future<void> _openTaskManager() async {
    if (!vm.isTaskManager) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskDashboardScreen()),
    );
    await vm.loadDashboardWork();
  }

  Future<void> _openLeave() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeavePage()),
    );
  }

  Future<void> _openLeaveManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaveManagementPage()),
    );
  }



  List<_DashboardAction> _availableActions() {
    return [
      _DashboardAction(
        icon: Icons.calendar_month_rounded,
        label: 'Attendance',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttendancePage()),
        ),
      ),
      _DashboardAction(
        icon: Icons.work_outline_rounded,
        label: 'My Work',
        onTap: _openMyWork,
      ),
      // NEW: Show Issues only when the logged-in employee
// has the "Mobile Issue" role.
      if (_canAccessMobileIssue)
        _DashboardAction(
          icon: Icons.report_problem_outlined,
          label: 'Issues',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IssueScreen()),
          ),
        ),
      if (vm.isIssueManager)
        _DashboardAction(
          icon: Icons.support_agent_rounded,
          label: 'Issue Management',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompanyIssuesScreen()),
          ),
        ),
      _DashboardAction(
        icon: Icons.event_available_rounded,
        label: 'Leave',
        onTap: _openLeave,
      ),
      if (_isLeaveApprover)
        _DashboardAction(
          icon: Icons.groups_2_outlined,
          label: 'Leave Management',
          onTap: _openLeaveManagement,
        ),
      _DashboardAction(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Payroll',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalaryPage()),
        ),
      ),
      _DashboardAction(
        icon: Icons.bar_chart_rounded,
        label: 'Reports',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PerformanceScreen()),
        ),
      ),
      _DashboardAction(
        icon: Icons.menu_book_rounded,
        label: 'Knowledge Hub',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KnowledgeHubScreen()),
        ),
      ),
      _DashboardAction(
        icon: Icons.note_alt_outlined,
        label: 'My Notes',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotesScreen()),
        ),
      ),
      if (vm.isTaskManager)
        _DashboardAction(
          icon: Icons.manage_accounts_outlined,
          label: 'Task Management',
          onTap: _openTaskManager,
        ),

      _DashboardAction(
        icon: Icons.video_camera_front_outlined,
        label: 'Meetings',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MeetingScreen(),
          ),
        ),
      ),
    ];
  }

  void _openAllFeatures(List<_DashboardAction> actions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllFeaturesScreen(actions: actions),
      ),
    );
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
  }

  Widget _buildDemoContactInfo() {
    final isDemoUser =
        vm.email.trim().toLowerCase() == 'demo@sanpra.com';

    if (!isDemoUser) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 12,
      ),
      child: Center(
        child: Text(
          'For more info, connect to Sanpra Software Solution\n'
              'Contact: 9766459844',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        final pages = <Widget>[
          _buildHome(),
          ChatScreen(
            onOpenManager: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatManagerScreen(),
                ),
              );
            },
          ),
          const EmployeeProfileScreen(),
          SettingsScreen(onLogout: _handleLogout),
        ];

        return Scaffold(
          backgroundColor: kBgGrey,
          extendBody: false,
          body: IndexedStack(index: _selectedTab, children: pages),
          bottomNavigationBar: _GlassNavigationBar(
            selectedIndex: _selectedTab,
            onSelected: _selectTab,
          ),
        );
      },
    );
  }

  Widget _buildHome() {
    if (vm.loading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: kBluePrimary),
        ),
      );
    }

    final actions = _availableActions();
    final visibleActions = actions.take(12).toList(growable: false);

    return RefreshIndicator(
      color: kBluePrimary,
      edgeOffset: 10,
      onRefresh: vm.loadData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _SectionHeader(
                  icon: Icons.bolt_rounded,
                  title: 'Quick Actions',
                  actionLabel: actions.length > 12 ? 'View all' : null,
                  onAction: actions.length > 12
                      ? () => _openAllFeatures(actions)
                      : null,
                ),
                const SizedBox(height: 0),
                _ActionGrid(actions: visibleActions),
                const SizedBox(height: 0),
                _SectionHeader(
                  icon: Icons.work_outline_rounded,
                  title: 'My Work',
                  actionLabel: 'View all',
                  onAction: _openMyWork,
                ),
                const SizedBox(height: 3),
                _buildWorkPreview(),
                _buildDemoContactInfo(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      '',
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBlueDark, kBluePrimary, kBlueAccent],
          stops: [0, .58, 1],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -70,
            top: 88,
            child: _HeaderGlow(size: 220),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(.24),
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        vm.company.isNotEmpty ? vm.company : 'SANPRA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Semantics(
                        button: true,
                        label: 'Notifications',
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ActionsNeededScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.13),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(.22),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                              Positioned(
                                right: 7,
                                top: 7,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF4D4F),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          vm.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white.withOpacity(.82),
                        size: 17,
                      ),

                      const SizedBox(width: 9),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weekdays[now.weekday - 1],
                            style: TextStyle(
                              color: Colors.white.withOpacity(.76),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${now.day} ${months[now.month]} ${now.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAttendancePanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePanel() {
    final checkedIn = _isCheckedIn;
    final checkedOut =
    vm.attendanceStatus.toLowerCase().contains('checked out');

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(.32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF082D78).withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attendance icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              checkedOut
                  ? Icons.check_circle_outline_rounded
                  : Icons.punch_clock_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),

          const SizedBox(width: 10),

          // Time / timer information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkedOut
                      ? 'TOTAL WORKED'
                      : checkedIn
                      ? 'WORKED TODAY'
                      : 'CHECK IN',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.72),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  ),
                ),

                const SizedBox(height: 3),

                if (checkedIn && !checkedOut)
                  Row(
                    children: [
                      Text(
                        _formatWorkedDuration(_workedDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Small live indicator
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF32D583),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  )
                else if (checkedOut)
                  Text(
                    // Keep the final total from the stopped timer.
                    _formatWorkedDuration(_workedDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                  )
                else
                  Text(
                    'Ready to start',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.90),
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Check In / Check Out button
          ElevatedButton.icon(
            onPressed: vm.attendanceLoading
                ? null
                : checkedIn
                ? _handleCheckOut
                : _handleCheckIn,

            icon: vm.attendanceLoading
                ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kBluePrimary,
              ),
            )
                : Icon(
              checkedIn
                  ? Icons.logout_rounded
                  : Icons.login_rounded,
              size: 16,
            ),

            label: Text(
              checkedIn ? 'Check Out' : 'Check In',
            ),

            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: kBluePrimary,
              disabledBackgroundColor:
              Colors.white.withOpacity(.75),
              disabledForegroundColor: kBluePrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkPreview() {
    if (vm.dashboardWork.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 16,
        ),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF12B76A).withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF12B76A),
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're all caught up",
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'No active work assigned to you',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final workItems = vm.dashboardWork.take(3).toList(growable: false);

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < workItems.length; index++) ...[
            _DashboardWorkTile(
              item: workItems[index],
              onTap: () => _openWorkItem(workItems[index]),
            ),
            if (index != workItems.length - 1)
              const Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
              ),
          ],
          if (vm.dashboardWorkCount > workItems.length)
            InkWell(
              onTap: _openMyWork,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  '+${vm.dashboardWorkCount - workItems.length} more work items',
                  style: const TextStyle(
                    color: kBluePrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEAECF0)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF344054).withOpacity(.055),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: kBluePrimary.withOpacity(.09),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: kBluePrimary, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -.25,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: kBluePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              minimumSize: const Size(0, 28),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded, size: 11),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_DashboardAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final tileWidth = (constraints.maxWidth - gap * 3) / 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            mainAxisExtent: tileWidth.clamp(76.0, 92.0).toDouble(),
          ),
          itemBuilder: (context, index) => _ActionTile(action: actions[index]),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAECF0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF344054).withOpacity(.045),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: kBluePrimary.withOpacity(.075),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(action.icon, color: kBluePrimary, size: 20),
                ),
                const SizedBox(height: 5),
                Text(
                  action.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 10.5,
                    height: 1.12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardWorkTile extends StatelessWidget {
  const _DashboardWorkTile({
    required this.item,
    required this.onTap,
  });

  final MyWorkItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = item.status.trim().toLowerCase();

    final Color statusColor;

    if (normalizedStatus == 'completed' ||
        normalizedStatus == 'closed') {
      statusColor = const Color(0xFF12B76A);
    } else if (normalizedStatus == 'pending review') {
      statusColor = const Color(0xFF8157C8);
    } else if (normalizedStatus == 'working') {
      statusColor = const Color(0xFFF79009);
    } else {
      statusColor = kBluePrimary;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 10, 10, 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isTask
                    ? Icons.assignment_outlined
                    : Icons.checklist_rounded,
                color: statusColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(.09),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.isTask ? 'TASK' : 'TODO',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllFeaturesScreen extends StatelessWidget {
  const _AllFeaturesScreen({required this.actions});

  final List<_DashboardAction> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kTextPrimary,
        title: const Text(
          'All Features',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          child: _ActionGrid(actions: actions),
        ),
      ),
    );
  }
}
class _GlassNavigationBar extends StatelessWidget {
  const _GlassNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
      (icon: Icons.settings_outlined, label: 'Settings'),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),

          // Subtle glass border
          border: Border.all(
            color: Colors.white.withOpacity(.22),
            width: 1,
          ),

          // Soft floating shadow
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B2451).withOpacity(.12),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),

          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 28,
              sigmaY: 28,
            ),

            child: Stack(
              children: [

                // =========================================================
                // MAIN TRANSPARENT GLASS BACKGROUND
                // =========================================================
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(.14),
                          Colors.white.withOpacity(.06),
                        ],
                      ),
                    ),
                  ),
                ),

                // =========================================================
                // SUBTLE TOP GLASS HIGHLIGHT
                // =========================================================
                Positioned(
                  left: 20,
                  right: 20,
                  top: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // =========================================================
                // NAVIGATION ITEMS
                // =========================================================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      for (var index = 0; index < items.length; index++)
                        Expanded(
                          child: _NavigationItem(
                            icon: items[index].icon,
                            label: items[index].label,
                            selected: selectedIndex == index,
                            onTap: () => onSelected(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.72),
                kBluePrimary.withOpacity(.10),
              ],
            )
                : null,
            borderRadius: BorderRadius.circular(17),
            border: selected
                ? Border.all(color: Colors.white.withOpacity(.72))
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    scale: selected ? 1.08 : 1,
                    child: Icon(
                      icon,
                      size: 21,
                      color: selected
                          ? kBluePrimary
                          : const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? kBluePrimary
                          : const Color(0xFF667085),
                      fontSize: 10,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 30,
                    height: 3,
                    decoration: BoxDecoration(
                      color: kBluePrimary,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: kBluePrimary.withOpacity(.32),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
class _CheckoutTimeInfo extends StatelessWidget {
  const _CheckoutTimeInfo({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HeaderGlow extends StatelessWidget {
  const _HeaderGlow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(.14), Colors.transparent],
        ),
      ),
    );
  }
}
