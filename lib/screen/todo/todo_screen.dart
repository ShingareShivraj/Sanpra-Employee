import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/todo_model.dart';
import 'todo_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _page = Color(0xFFF4F7FC);
const _green = Color(0xFF159B65);
const _orange = Color(0xFFF28C28);
const _red = Color(0xFFE04F5F);

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin {
  final TodoViewModel vm = TodoViewModel();
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    vm.loadTodos();
  }

  @override
  void dispose() {
    _tabs.dispose();
    vm.dispose();
    super.dispose();
  }

  Future<void> _complete(TodoModel todo) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DCE5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFFE8F7F0),
                    child: Icon(Icons.task_alt_rounded, color: _green),
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Mark ToDo as completed?',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                todo.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: _green),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      icon: const Icon(Icons.check_rounded, size: 19),
                      label: const Text('Complete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final success = await vm.completeTodo(todo.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(success
            ? 'ToDo completed successfully'
            : vm.errorMessage),
        backgroundColor: success ? _green : _red,
      ),
    );
    if (success) _tabs.animateTo(3);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (_, __) => Scaffold(
        backgroundColor: _page,
        appBar: _appBar(),
        body: _body(),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: _blue,
    foregroundColor: Colors.white,
    titleSpacing: 18,
    title: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My ToDos',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        Text(
          'Plan, prioritize and complete your work',
          style: TextStyle(fontSize: 12.5, color: Colors.white70),
        ),
      ],
    ),
    actions: [
      IconButton(
        tooltip: 'Refresh',
        onPressed: vm.loading ? null : vm.loadTodos,
        icon: vm.loading
            ? const SizedBox(
          width: 19,
          height: 19,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.refresh_rounded),
      ),
      const SizedBox(width: 5),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(53),
      child: Container(
        height: 44,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 9),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _darkBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabs,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
          ),
          labelColor: _darkBlue,
          unselectedLabelColor: Colors.white,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          labelPadding: EdgeInsets.zero,
          tabs: [
            _tab('Today', vm.today.length),
            _tab('Overdue', vm.overdue.length),
            _tab('Upcoming', vm.upcoming.length),
            _tab('Completed', vm.completed.length),
          ],
        ),
      ),
    ),
  );

  Widget _tab(String label, int count) => Tab(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text('$label  $count'),
    ),
  );

  Widget _body() {
    if (vm.loading && !vm.hasTodos && vm.completed.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _blue),
      );
    }
    if (vm.errorMessage.isNotEmpty && !vm.hasTodos && vm.completed.isEmpty) {
      return _errorState();
    }
    return Column(
      children: [
        _summary(),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _list(vm.today, TodoSection.today),
              _list(vm.overdue, TodoSection.overdue),
              _list(vm.upcoming, TodoSection.upcoming),
              _list(vm.completed, TodoSection.completed),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summary() => Container(
    margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFF7FAFF)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE3E9F3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A173B70),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.checklist_rounded, color: _blue),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open ToDos',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF667085)),
              ),
              SizedBox(height: 2),
              Text(
                'Items requiring your attention',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${vm.openCount}',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _blue,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _list(List<TodoModel> items, TodoSection section) {
    return RefreshIndicator(
      color: _blue,
      onRefresh: vm.loadTodos,
      child: items.isEmpty
          ? _empty(section)
          : ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) => _card(items[index], section),
      ),
    );
  }

  Widget _card(TodoModel todo, TodoSection section) {
    final completed = section == TodoSection.completed;
    final accent = completed
        ? _green
        : section == TodoSection.overdue
        ? _red
        : section == TodoSection.today
        ? _orange
        : _blue;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: completed || vm.isCompleting(todo.name)
            ? null
            : () => _complete(todo),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE4E9F1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  completed
                      ? Icons.task_alt_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 21,
                  color: accent,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: completed
                            ? const Color(0xFF667085)
                            : const Color(0xFF172033),
                        decoration:
                        completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(
                          Icons.flag_rounded,
                          todo.priority,
                          _priorityColor(todo.priority),
                        ),
                        _chip(
                          completed
                              ? Icons.verified_rounded
                              : Icons.event_rounded,
                          _dateText(todo, completed),
                          accent,
                        ),
                        if (todo.referenceName.isNotEmpty)
                          _chip(Icons.link_rounded, todo.referenceName, _blue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (vm.isCompleting(todo.name))
                const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (!completed)
                Icon(Icons.check_circle_outline_rounded, color: accent)
              else
                const Icon(Icons.check_circle_rounded, color: _green),
            ],
          ),
        ),
      ),
    );
  }

  String _dateText(TodoModel todo, bool completed) {
    if (completed && todo.completedOn != null) {
      return 'Done ${DateFormat('dd MMM').format(todo.completedOn!)}';
    }
    return todo.dueDate == null
        ? 'No due date'
        : DateFormat('dd MMM yyyy').format(todo.dueDate!);
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return _red;
      case 'low':
        return _green;
      default:
        return _orange;
    }
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _empty(TodoSection section) {
    final data = switch (section) {
      TodoSection.today => ('No ToDos for today', 'Your day is clear.', Icons.wb_sunny_outlined),
      TodoSection.overdue => ('Nothing overdue', 'You are all caught up.', Icons.auto_awesome_rounded),
      TodoSection.upcoming => ('No upcoming ToDos', 'New ToDos will appear here.', Icons.event_available_rounded),
      TodoSection.completed => ('No completed ToDos', 'Completed items will appear here.', Icons.task_alt_rounded),
    };
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFE8F0FF),
          child: Icon(data.$3, size: 30, color: _blue),
        ),
        const SizedBox(height: 13),
        Center(
          child: Text(
            data.$1,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            data.$2,
            style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
          ),
        ),
      ],
    );
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFFFECEE),
            child: Icon(Icons.cloud_off_rounded, color: _red, size: 30),
          ),
          const SizedBox(height: 13),
          const Text(
            'Unable to load ToDos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            vm.errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: vm.loadTodos,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

enum TodoSection { today, overdue, upcoming, completed }
