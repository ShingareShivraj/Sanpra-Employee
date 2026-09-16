import 'package:flutter/material.dart';

import '../../../model/task_model.dart';
import 'company_tasks_viewmodel.dart';
import 'review_task_screen.dart';
import 'task_info_screen.dart';

const _primary = Color(0xFF1B5FE0);
const _accent = Color(0xFF4E8CFF);
const _dark = Color(0xFF123FA0);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF68758A);
const _canvas = Color(0xFFF5F7FC);

class CompanyTasksScreen extends StatefulWidget {
  const CompanyTasksScreen({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  State<CompanyTasksScreen> createState() => _CompanyTasksScreenState();
}

class _CompanyTasksScreenState extends State<CompanyTasksScreen> {
  late final CompanyTasksViewModel viewModel;
  final searchController = TextEditingController();
  final projectController = TextEditingController();
  final scrollController = ScrollController();
  bool filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    viewModel = CompanyTasksViewModel(initialStatus: widget.initialStatus)
      ..initialise();
    projectController.text = viewModel.project ?? '';
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 240) {
      viewModel.loadMore();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    projectController.dispose();
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Track and review team work',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: viewModel.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            return Column(
              children: [
                _topPanel(),
                if (viewModel.errorMessage != null) _errorBanner(),
                Expanded(child: _body()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _summaryCard()),
              const SizedBox(width: 9),
              _filterButton(),
            ],
          ),
          const SizedBox(height: 9),
          _searchField(),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 8),
            _activeFilters(),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: filtersExpanded
                ? Padding(
              padding: const EdgeInsets.only(top: 9),
              child: _filterPanel(),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final loaded = viewModel.tasks.length;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_dark, _primary, _accent]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261B5FE0),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${viewModel.total}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  viewModel.hasMore ? '$loaded loaded' : 'tasks found',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .84),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton() {
    final count = _activeFilterCount;
    return InkWell(
      onTap: () => setState(() => filtersExpanded = !filtersExpanded),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: filtersExpanded || count > 0
              ? const Color(0xFFEAF1FF)
              : const Color(0xFFF3F5F9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: filtersExpanded || count > 0
                ? const Color(0xFFBFD2FF)
                : const Color(0xFFE4E8F0),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              filtersExpanded ? Icons.tune_rounded : Icons.filter_list_rounded,
              color: count > 0 || filtersExpanded ? _primary : _muted,
              size: 22,
            ),
            if (count > 0)
              Positioned(
                right: 7,
                top: 6,
                child: Container(
                  width: 17,
                  height: 17,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: searchController,
        onChanged: viewModel.updateSearch,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search by task name or subject',
          hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 20),
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              searchController.clear();
              viewModel.updateSearch('');
              setState(() {});
            },
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
          filled: true,
          fillColor: const Color(0xFFF5F7FB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: _primary, width: 1.3),
          ),
        ),
      ),
    );
  }

  Widget _filterPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _compactDropdown(
                  label: 'Status',
                  icon: Icons.flag_outlined,
                  value: viewModel.status,
                  items: const [
                    'Open',
                    'Working',
                    'Pending Review',
                    'Completed',
                    'Cancelled',
                  ],
                  onChanged: viewModel.setStatus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _employeeDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _projectField()),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _hasActiveFilters ? _clearAll : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: Color(0xFFC9D6EE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 17),
                  label: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: const TextStyle(
        color: _ink,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: _compactDecoration(label, icon),
      items: items
          .map(
            (item) => DropdownMenuItem(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _employeeDropdown() {
    return DropdownButtonFormField<String>(
      value: viewModel.assignedTo,
      isExpanded: true,
      style: const TextStyle(
        color: _ink,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: _compactDecoration('Employee', Icons.person_outline_rounded),
      items: viewModel.employees
          .map(
            (employee) => DropdownMenuItem(
          value: employee.userId,
          child: Text(
            employee.employeeName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
          .toList(),
      onChanged: viewModel.setAssignedTo,
    );
  }

  Widget _projectField() {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: projectController,
        onSubmitted: viewModel.setProject,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        decoration: _compactDecoration('Project ID', Icons.folder_outlined)
            .copyWith(
          suffixIcon: IconButton(
            tooltip: 'Apply project',
            onPressed: () => viewModel.setProject(projectController.text),
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          ),
        ),
      ),
    );
  }

  InputDecoration _compactDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: _muted),
      prefixIcon: Icon(icon, size: 18, color: _muted),
      prefixIconConstraints: const BoxConstraints(minWidth: 36),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFDDE3ED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFDDE3ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _primary),
      ),
    );
  }

  Widget _activeFilters() {
    final chips = <Widget>[];
    if (viewModel.status != null) {
      chips.add(_filterChip(
        icon: Icons.flag_outlined,
        label: viewModel.status!,
        onRemove: () => viewModel.setStatus(null),
      ));
    }
    if (viewModel.assignedTo != null) {
      chips.add(_filterChip(
        icon: Icons.person_outline_rounded,
        label: _selectedEmployeeName,
        onRemove: () => viewModel.setAssignedTo(null),
      ));
    }
    if (viewModel.project != null) {
      chips.add(_filterChip(
        icon: Icons.folder_outlined,
        label: viewModel.project!,
        onRemove: () {
          projectController.clear();
          viewModel.setProject('');
        },
      ));
    }
    return SizedBox(
      height: 29,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFC9D9FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _primary),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _dark,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 14, color: _dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 9, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFFFCCC7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD4380D), size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              viewModel.errorMessage!,
              style: const TextStyle(
                color: Color(0xFF9F2A12),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: viewModel.refresh,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: const Color(0xFFD4380D),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (viewModel.loading && viewModel.tasks.isEmpty) {
      return const _LoadingList();
    }

    if (viewModel.tasks.isEmpty) {
      return RefreshIndicator(
        color: _primary,
        onRefresh: viewModel.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
          children: [
            _EmptyState(
              filtered: _hasActiveFilters || viewModel.search.isNotEmpty,
              onClear: _clearAll,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: viewModel.refresh,
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        itemCount: viewModel.tasks.length + (viewModel.loadingMore ? 1 : 0),
        itemBuilder: (_, index) {
          if (index == viewModel.tasks.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            );
          }
          final task = viewModel.tasks[index];
          return _TaskCard(task: task, onTap: () => _openTask(task));
        },
      ),
    );
  }

  Future<void> _openTask(TaskModel task) async {
    // Pending Review → open the existing review screen.
    if (task.isPendingReview) {
      final reviewed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReviewTaskScreen(task: task),
        ),
      );

      if (reviewed == true && mounted) {
        await viewModel.refresh();
      }

      return;
    }

    // All other statuses → open the new Task Info screen.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskInfoScreen(task: task),
      ),
    );
  }


  Future<void> _clearAll() async {
    searchController.clear();
    projectController.clear();
    await viewModel.clearFilters();
    if (mounted) setState(() {});
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  int get _activeFilterCount => [
    viewModel.status,
    viewModel.assignedTo,
    viewModel.project,
  ].where((value) => value != null && value!.isNotEmpty).length;

  String get _selectedEmployeeName {
    for (final employee in viewModel.employees) {
      if (employee.userId == viewModel.assignedTo) return employee.employeeName;
    }
    return viewModel.assignedTo ?? 'Employee';
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});

  final TaskModel task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(task.status);
    final dueDate = task.expectedEndDate ?? task.dueDate;
    final title = task.subject.trim().isEmpty ? task.name : task.subject.trim();
    // ==========================================================
// NEW: SHOW ALL ASSIGNED EMPLOYEES ON THE TASK CARD
// ==========================================================
// A Task can have multiple employees assigned.
// Show all employee names instead of only the first one.
    final assignee = task.assignees
        .map((employee) => employee.fullName ?? employee.user)
        .where((name) => name.trim().isNotEmpty)
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: task.isPendingReview
              ? const Color(0xFFD7C7FF)
              : const Color(0xFFE4E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D172033),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(style.icon, color: style.foreground, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 14,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          _StatusBadge(style: style, label: task.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          _MetaPill(
                            icon: _priorityIcon(task.priority),
                            label: task.priority.isEmpty ? 'Medium' : task.priority,
                            color: _priorityColor(task.priority),
                          ),
                          if (dueDate != null)
                            _MetaPill(
                              icon: Icons.event_outlined,
                              label: _date(dueDate),
                              color: _isOverdue(dueDate, task)
                                  ? const Color(0xFFD92D20)
                                  : _muted,
                            ),
                          if (assignee.trim().isNotEmpty)
                            _MetaPill(
                              icon: Icons.person_outline_rounded,
                              label: assignee,
                              color: _muted,
                            ),
                          if (task.project != null && task.project!.trim().isNotEmpty)
                            _MetaPill(
                              icon: Icons.folder_outlined,
                              label: task.project!,
                              color: _muted,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 29),
                  child: Icon(
                    task.isPendingReview
                        ? Icons.rate_review_outlined
                        : Icons.chevron_right_rounded,
                    size: 20,
                    color: task.isPendingReview ? style.foreground : const Color(0xFFABB4C3),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.style, required this.label});

  final _StatusStyle style;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.isEmpty ? 'Open' : label,
        style: TextStyle(
          color: style.foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        height: 112,
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE8EBF1)),
        ),
        padding: const EdgeInsets.all(12),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Skeleton(width: 38, height: 38, radius: 11),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Skeleton(width: double.infinity, height: 13),
                  SizedBox(height: 8),
                  _Skeleton(width: 115, height: 10),
                  SizedBox(height: 13),
                  Row(
                    children: [
                      _Skeleton(width: 70, height: 23, radius: 7),
                      SizedBox(width: 6),
                      _Skeleton(width: 88, height: 23, radius: 7),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height, this.radius = 5});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onClear});

  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF1FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            filtered ? Icons.search_off_rounded : Icons.task_alt_rounded,
            color: _primary,
            size: 34,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          filtered ? 'No matching tasks' : 'No company tasks yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          filtered
              ? 'Try changing or clearing the current filters.'
              : 'Newly created company tasks will appear here.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.35),
        ),
        if (filtered) ...[
          const SizedBox(height: 13),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Clear filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: Color(0xFFBFD1F7)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusStyle {
  const _StatusStyle(this.foreground, this.background, this.icon);

  final Color foreground;
  final Color background;
  final IconData icon;
}

_StatusStyle _statusStyle(String status) {
  switch (status.toLowerCase().trim()) {
    case 'working':
      return const _StatusStyle(
        Color(0xFF175CD3),
        Color(0xFFEAF2FF),
        Icons.play_circle_outline_rounded,
      );
    case 'pending review':
      return const _StatusStyle(
        Color(0xFF6938AF),
        Color(0xFFF3EDFF),
        Icons.rate_review_outlined,
      );
    case 'completed':
      return const _StatusStyle(
        Color(0xFF067647),
        Color(0xFFE8F8F0),
        Icons.check_circle_outline_rounded,
      );
    case 'cancelled':
      return const _StatusStyle(
        Color(0xFFB42318),
        Color(0xFFFFECEA),
        Icons.cancel_outlined,
      );
    default:
      return const _StatusStyle(
        Color(0xFFB54708),
        Color(0xFFFFF3E2),
        Icons.pending_actions_rounded,
      );
  }
}

IconData _priorityIcon(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
    case 'urgent':
      return Icons.keyboard_double_arrow_up_rounded;
    case 'low':
      return Icons.keyboard_arrow_down_rounded;
    default:
      return Icons.remove_rounded;
  }
}

Color _priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
    case 'urgent':
      return const Color(0xFFD92D20);
    case 'low':
      return const Color(0xFF067647);
    default:
      return const Color(0xFFB54708);
  }
}

bool _isOverdue(DateTime date, TaskModel task) {
  if (task.isCompleted) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(date.year, date.month, date.day);
  return due.isBefore(today);
}

String _date(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
