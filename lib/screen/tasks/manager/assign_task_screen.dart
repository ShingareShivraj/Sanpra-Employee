import 'package:flutter/material.dart';

import 'assign_task_viewmodel.dart';

const kBluePrimary = Color(0xFF1B5FE0);
const kBlueAccent = Color(0xFF4E8CFF);
const kBlueDark = Color(0xFF123FA0);

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key, required this.taskName});

  final String taskName;

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen>
    with SingleTickerProviderStateMixin {
  late final AssignTaskViewModel viewModel;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    viewModel = AssignTaskViewModel(taskName: widget.taskName)..initialise();
  }

  @override
  void dispose() {
    _tabController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    final success = await viewModel.assignSelected();
    if (!mounted || !success) return;
    _message('Task assigned successfully.');
  }

  Future<void> _reassign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        title: const Row(
          children: [
            _IconBadge(icon: Icons.swap_horiz_rounded),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Confirm reassignment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'The task will be removed from the current employee and assigned to the selected employee.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBluePrimary),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reassign'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final success = await viewModel.reassign();
    if (!mounted || !success) return;
    _message('Task reassigned successfully.');
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 19),
              const SizedBox(width: 9),
              Expanded(child: Text(value)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16865B),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign Task',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Manage task responsibility',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF778198),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.loading) return const _LoadingView();

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: kBluePrimary,
                  onRefresh: viewModel.initialise,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                        sliver: SliverToBoxAdapter(
                          child: _TaskHeader(
                            taskName: widget.taskName,
                            subject:
                            viewModel.task?.subject ?? widget.taskName,
                            status: viewModel.task?.status ?? 'Open',
                            assigneeCount: viewModel.assignees.length,
                            canEdit: viewModel.canEdit,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                        sliver: SliverToBoxAdapter(
                          child: _CurrentAssignees(
                            assignees: viewModel.assignees,
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabHeaderDelegate(
                          TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: kBluePrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: const Color(0xFF5F6B82),
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: const [
                              Tab(
                                height: 38,
                                icon: Icon(Icons.group_add_rounded, size: 17),
                                text: 'Add Employees',
                                iconMargin: EdgeInsets.only(bottom: 2),
                              ),
                              Tab(
                                height: 38,
                                icon: Icon(Icons.swap_horiz_rounded, size: 18),
                                text: 'Reassign',
                                iconMargin: EdgeInsets.only(bottom: 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: true,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _AddEmployeesTab(
                              viewModel: viewModel,
                              onAssign: _assign,
                            ),
                            _ReassignTab(
                              viewModel: viewModel,
                              onReassign: _reassign,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (viewModel.errorMessage != null)
                _ErrorBanner(message: viewModel.errorMessage!),
            ],
          );
        },
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({
    required this.taskName,
    required this.subject,
    required this.status,
    required this.assigneeCount,
    required this.canEdit,
  });

  final String taskName;
  final String subject;
  final String status;
  final int assigneeCount;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kBlueDark, kBluePrimary, kBlueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kBluePrimary.withValues(alpha: .2),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  taskName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            subject,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded,
                  size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                '$assigneeCount ${assigneeCount == 1 ? 'assignee' : 'assignees'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!canEdit) ...[
                const Spacer(),
                const Icon(Icons.lock_outline_rounded,
                    size: 15, color: Colors.white70),
                const SizedBox(width: 4),
                const Text(
                  'Read only',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentAssignees extends StatelessWidget {
  const _CurrentAssignees({required this.assignees});

  final List<dynamic> assignees;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: kBluePrimary, size: 18),
              const SizedBox(width: 7),
              const Text(
                'Current assignees',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202A3C),
                ),
              ),
              const Spacer(),
              Text(
                '${assignees.length}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF778198),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (assignees.isEmpty)
            const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 17, color: Color(0xFF8A94A8)),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'No employee is currently assigned.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF69758C)),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: assignees.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final item = assignees[index];
                  final name = item.fullName ?? item.user;
                  return Container(
                    padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: kBluePrimary,
                          child: Text(
                            _initials(name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF34425B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AddEmployeesTab extends StatelessWidget {
  const _AddEmployeesTab({required this.viewModel, required this.onAssign});

  final AssignTaskViewModel viewModel;
  final Future<void> Function() onAssign;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: TextField(
            enabled: viewModel.canEdit,
            onChanged: viewModel.searchEmployees,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search employee, designation or department',
              hintStyle:
              const TextStyle(fontSize: 13, color: Color(0xFF9099AA)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: viewModel.selectedUsers.isEmpty
                  ? null
                  : Center(
                widthFactor: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${viewModel.selectedUsers.length} selected',
                    style: const TextStyle(
                      color: kBluePrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBluePrimary, width: 1.4),
              ),
            ),
          ),
        ),
        Expanded(
          child: viewModel.employees.isEmpty
              ? const _EmptyEmployees()
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 92),
            itemCount: viewModel.employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 7),
            itemBuilder: (context, index) {
              final employee = viewModel.employees[index];
              final selected =
              viewModel.selectedUsers.contains(employee.userId);
              final details = [
                employee.designation,
                employee.department,
                employee.userId,
              ]
                  .whereType<String>()
                  .where((value) => value.trim().isNotEmpty)
                  .join('  •  ');

              return Material(
                color: selected
                    ? const Color(0xFFEDF3FF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: viewModel.canEdit
                      ? () => viewModel.toggleUser(employee.userId)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: selected
                            ? kBluePrimary.withValues(alpha: .38)
                            : const Color(0xFFE7EAF1),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: selected
                              ? kBluePrimary
                              : const Color(0xFFEFF2F8),
                          child: Text(
                            _initials(employee.employeeName),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF536078),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.employeeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF263247),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  details,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF778198),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Checkbox(
                          value: selected,
                          activeColor: kBluePrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          onChanged: viewModel.canEdit
                              ? (_) => viewModel
                              .toggleUser(employee.userId)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _BottomAction(
          label: viewModel.selectedUsers.isEmpty
              ? 'Select employees to assign'
              : 'Assign ${viewModel.selectedUsers.length} ${viewModel.selectedUsers.length == 1 ? 'Employee' : 'Employees'}',
          icon: Icons.person_add_alt_1_rounded,
          loading: viewModel.assigning,
          enabled: viewModel.canEdit &&
              viewModel.selectedUsers.isNotEmpty &&
              !viewModel.assigning,
          onPressed: onAssign,
        ),
      ],
    );
  }
}

class _ReassignTab extends StatelessWidget {
  const _ReassignTab({required this.viewModel, required this.onReassign});

  final AssignTaskViewModel viewModel;
  final Future<void> Function() onReassign;

  @override
  Widget build(BuildContext context) {
    final canSubmit = viewModel.canEdit &&
        viewModel.fromUser != null &&
        viewModel.toUser != null &&
        viewModel.fromUser != viewModel.toUser &&
        !viewModel.reassigning;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 92),
            children: [
              const _SectionIntro(
                icon: Icons.swap_horiz_rounded,
                title: 'Move responsibility',
                message:
                'Choose the current assignee, then select the employee who will take over this task.',
              ),
              const SizedBox(height: 10),
              _FieldCard(
                step: '1',
                title: 'Current assignee',
                child: DropdownButtonFormField<String>(
                  value: viewModel.fromUser,
                  isExpanded: true,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF263247),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _dropdownDecoration(
                    'Select employee to remove',
                    Icons.person_remove_alt_1_outlined,
                  ),
                  items: viewModel.assignees
                      .map(
                        (item) => DropdownMenuItem<String>(
                      value: item.user,
                      child: Text(
                        item.fullName ?? item.user,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                      .toList(),
                  onChanged:
                  viewModel.canEdit ? viewModel.setFromUser : null,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Center(
                  child: Icon(Icons.arrow_downward_rounded,
                      color: kBluePrimary, size: 20),
                ),
              ),
              _FieldCard(
                step: '2',
                title: 'New employee',
                child: DropdownButtonFormField<String>(
                  value: viewModel.toUser,
                  isExpanded: true,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF263247),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _dropdownDecoration(
                    'Select new employee',
                    Icons.person_add_alt_1_outlined,
                  ),
                  items: viewModel.employees
                      .where((employee) =>
                  employee.userId != viewModel.fromUser)
                      .map(
                        (employee) => DropdownMenuItem<String>(
                      value: employee.userId,
                      child: Text(
                        employee.employeeName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: viewModel.canEdit ? viewModel.setToUser : null,
                ),
              ),
              if (viewModel.assignees.isEmpty) ...[
                const SizedBox(height: 10),
                const _InlineNotice(
                  message:
                  'This task has no current assignee. Use Add Employees instead.',
                ),
              ],
            ],
          ),
        ),
        _BottomAction(
          label: 'Confirm Reassignment',
          icon: Icons.swap_horiz_rounded,
          loading: viewModel.reassigning,
          enabled: canSubmit,
          onPressed: onReassign,
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.step,
    required this.title,
    required this.child,
  });

  final String step;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: kBluePrimary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF263247),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F1FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: kBluePrimary, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF263247),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Color(0xFF6F7A90),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        9,
        14,
        9 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E9F1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        height: 46,
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: kBluePrimary,
            disabledBackgroundColor: const Color(0xFFD8DEEA),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: enabled ? onPressed : null,
          icon: loading
              ? const _Loader()
              : Icon(icon, size: 19, color: Colors.white),
          label: Text(
            loading ? 'Please wait...' : label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
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
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color: const Color(0xFFFFEDEC),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFCC3D3D), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF9E3030),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E5),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFF4D894)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFA96D08), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF8B620E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEmployees extends StatelessWidget {
  const _EmptyEmployees();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded,
                size: 42, color: Color(0xFFABB4C5)),
            SizedBox(height: 9),
            Text(
              'No employees found',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF46536A),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Try a different search term.',
              style: TextStyle(fontSize: 13, color: Color(0xFF7D8799)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: kBluePrimary,
              strokeWidth: 2.7,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Loading assignment details...',
            style: TextStyle(fontSize: 13, color: Color(0xFF758096)),
          ),
        ],
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 19,
      height: 19,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: kBluePrimary, size: 20),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabHeaderDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => 54;

  @override
  double get maxExtent => 54;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF5F7FC),
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 9),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) => false;
}

InputDecoration _dropdownDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF929BAC)),
    prefixIcon: Icon(icon, size: 19, color: kBluePrimary),
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF8FAFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: kBluePrimary, width: 1.4),
    ),
  );
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return const Color(0xFF16865B);
    case 'cancelled':
      return const Color(0xFFCC3D3D);
    case 'pending review':
      return const Color(0xFFB56E08);
    case 'working':
      return const Color(0xFF7A50CE);
    default:
      return kBluePrimary;
  }
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
