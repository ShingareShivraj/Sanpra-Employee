import 'package:flutter/material.dart';

import '../../../model/employee_model.dart';
import 'create_task_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _blueDark = Color(0xFF123FA0);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF687386);
const _surface = Color(0xFFF5F7FB);

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _projectController = TextEditingController();
  final _employeeSearchController = TextEditingController();
  late final CreateTaskViewModel viewModel;
  String _employeeQuery = '';

  @override
  void initState() {
    super.initState();
    viewModel = CreateTaskViewModel()..loadEmployees();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    _employeeSearchController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? viewModel.startDate : viewModel.endDate;
    final value = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: start ? 'SELECT START DATE' : 'SELECT DUE DATE',
    );
    if (value == null) return;
    start ? viewModel.setStartDate(value) : viewModel.setEndDate(value);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final task = await viewModel.create(
      subject: _subjectController.text,
      description: _descriptionController.text,
      project: _projectController.text,
    );
    if (!mounted || task == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task created and assigned successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(true);
  }

  List<EmployeeModel> _visibleEmployees(List<EmployeeModel> employees) {
    final query = _employeeQuery.trim().toLowerCase();
    if (query.isEmpty) return employees;
    return employees.where((employee) {
      final text = [
        employee.employeeName,
        employee.userId,
        employee.designation,
        employee.department,
      ].whereType<String>().join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        final selected = viewModel.selectedUsers.length;
        return Scaffold(
          backgroundColor: _surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: _ink,
            titleSpacing: 4,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text('Plan work and assign employees', style: TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                children: [
                  _ProgressHeader(selectedEmployees: selected),
                  const SizedBox(height: 10),
                  _SectionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Task details',
                    subtitle: 'What needs to be completed?',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _subjectController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLength: 140,
                          style: const TextStyle(fontSize: 14, color: _ink, fontWeight: FontWeight.w600),
                          decoration: _inputDecoration(
                            label: 'Task subject *',
                            hint: 'e.g. Verify monthly attendance',
                            icon: Icons.task_alt_rounded,
                          ).copyWith(counterText: ''),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Enter the task subject.'
                              : null,
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _descriptionController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 5,
                          style: const TextStyle(fontSize: 14, color: _ink),
                          decoration: _inputDecoration(
                            label: 'Description',
                            hint: 'Add instructions or expected outcome',
                            icon: Icons.notes_rounded,
                          ).copyWith(alignLabelWithHint: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    icon: Icons.tune_rounded,
                    title: 'Planning',
                    subtitle: 'Set priority, schedule and project',
                    child: Column(
                      children: [
                        _PrioritySelector(
                          value: viewModel.priority,
                          onChanged: viewModel.setPriority,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label: 'Start date',
                                value: viewModel.startDate,
                                icon: Icons.play_circle_outline_rounded,
                                onTap: () => _pickDate(start: true),
                                onClear: viewModel.startDate == null
                                    ? null
                                    : () => viewModel.setStartDate(null),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DateField(
                                label: 'Due date',
                                value: viewModel.endDate,
                                icon: Icons.event_available_rounded,
                                onTap: () => _pickDate(start: false),
                                onClear: viewModel.endDate == null
                                    ? null
                                    : () => viewModel.setEndDate(null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _projectController,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(fontSize: 14, color: _ink),
                          decoration: _inputDecoration(
                            label: 'Project ID',
                            hint: 'Optional',
                            icon: Icons.work_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _EmployeeSection(
                    viewModel: viewModel,
                    searchController: _employeeSearchController,
                    employees: _visibleEmployees(viewModel.employees),
                    query: _employeeQuery,
                    onSearch: (value) => setState(() => _employeeQuery = value),
                    onClearSearch: () {
                      _employeeSearchController.clear();
                      setState(() => _employeeQuery = '');
                    },
                  ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    _ErrorBanner(message: viewModel.errorMessage!),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: _BottomAction(
            selectedEmployees: selected,
            submitting: viewModel.submitting,
            onPressed: viewModel.submitting ? null : _submit,
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.selectedEmployees});
  final int selectedEmployees;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blueDark, _blue]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _blue.withOpacity(.20), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New work assignment', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Add details, plan dates and choose the team.', style: TextStyle(color: Color(0xFFDCE7FF), fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Text('$selectedEmployees', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const Text('Selected', style: TextStyle(color: Color(0xFFDCE7FF), fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.subtitle, required this.child});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE7EBF2)),
        boxShadow: const [BoxShadow(color: Color(0x0A172033), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(color: const Color(0xFFEDF3FF), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: _blue, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink)),
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: _muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String?> onChanged;

  Color _color(String priority) {
    switch (priority) {
      case 'Urgent': return const Color(0xFFD92D20);
      case 'High': return const Color(0xFFF26B38);
      case 'Low': return const Color(0xFF248A5A);
      default: return _blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priority', style: TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: CreateTaskViewModel.priorities.map((priority) {
            final active = priority == value;
            final color = _color(priority);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: priority == CreateTaskViewModel.priorities.last ? 0 : 6),
                child: InkWell(
                  onTap: () => onChanged(priority),
                  borderRadius: BorderRadius.circular(9),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? color : const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: active ? color : const Color(0xFFE2E6ED)),
                    ),
                    child: Text(priority, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : _muted)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.icon, required this.onTap, this.onClear});
  final String label;
  final DateTime? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 53,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value == null ? const Color(0xFFE2E6ED) : const Color(0xFFB9CDF8)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: value == null ? _muted : _blue),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10.5, color: _muted)),
                  const SizedBox(height: 1),
                  Text(value == null ? 'Select' : _format(value!), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: value == null ? _muted : _ink)),
                ],
              ),
            ),
            if (onClear != null)
              InkWell(onTap: onClear, child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.close_rounded, size: 16, color: _muted))),
          ],
        ),
      ),
    );
  }
}

class _EmployeeSection extends StatelessWidget {
  const _EmployeeSection({
    required this.viewModel,
    required this.searchController,
    required this.employees,
    required this.query,
    required this.onSearch,
    required this.onClearSearch,
  });
  final CreateTaskViewModel viewModel;
  final TextEditingController searchController;
  final List<EmployeeModel> employees;
  final String query;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.selectedUsers.length;
    return _SectionCard(
      icon: Icons.groups_2_outlined,
      title: 'Assign employees *',
      subtitle: selected == 0 ? 'Select at least one employee' : '$selected employee${selected == 1 ? '' : 's'} selected',
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearch,
            style: const TextStyle(fontSize: 13.5, color: _ink),
            decoration: _inputDecoration(label: 'Search employees', hint: 'Name, department or email', icon: Icons.search_rounded).copyWith(
              suffixIcon: query.isEmpty ? null : IconButton(onPressed: onClearSearch, icon: const Icon(Icons.close_rounded, size: 18)),
            ),
          ),
          const SizedBox(height: 8),
          if (viewModel.loadingEmployees)
            const SizedBox(height: 116, child: Center(child: CircularProgressIndicator(strokeWidth: 2.2, color: _blue)))
          else if (viewModel.employees.isEmpty)
            _EmployeeEmpty(onRetry: viewModel.loadEmployees, message: 'No active employees found.')
          else if (employees.isEmpty)
              const _EmployeeEmpty(message: 'No employee matches this search.')
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 292),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFC),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFE7EAF0)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 54, endIndent: 8, color: Color(0xFFE9ECF2)),
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    final checked = viewModel.selectedUsers.contains(employee.userId);
                    return _EmployeeTile(
                      employee: employee,
                      selected: checked,
                      onTap: () => viewModel.toggleEmployee(employee.userId),
                    );
                  },
                ),
              ),
          if (selected > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF248A5A), size: 17),
                const SizedBox(width: 6),
                Expanded(child: Text('$selected selected for assignment', style: const TextStyle(fontSize: 12, color: Color(0xFF247A52), fontWeight: FontWeight.w600))),
                TextButton(
                  onPressed: () {
                    final users = viewModel.selectedUsers.toList();
                    for (final user in users) { viewModel.toggleEmployee(user); }
                  },
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: _muted),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee, required this.selected, required this.onTap});
  final EmployeeModel employee;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [employee.designation, employee.department]
        .whereType<String>().where((value) => value.trim().isNotEmpty).join(' • ');
    final initials = employee.employeeName.trim().isEmpty
        ? '?'
        : employee.employeeName.trim().split(RegExp(r'\s+')).take(2).map((word) => word[0]).join().toUpperCase();
    return Material(
      color: selected ? const Color(0xFFEEF4FF) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 8, 7, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: selected ? _blue : const Color(0xFFE8ECF3),
                child: Text(initials, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : _muted)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.employeeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink)),
                    const SizedBox(height: 1),
                    Text(details.isEmpty ? employee.userId : details, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: _muted)),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
                activeColor: _blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeEmpty extends StatelessWidget {
  const _EmployeeEmpty({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(Icons.person_search_outlined, color: Color(0xFF9AA3B2), size: 28),
          const SizedBox(height: 5),
          Text(message, style: const TextStyle(fontSize: 12.5, color: _muted)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again', style: TextStyle(fontSize: 12.5))),
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: const Color(0xFFFFF0EF), borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFF5C5C1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD92D20), size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12.5, color: Color(0xFF9C271F), height: 1.3))),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.selectedEmployees, required this.submitting, required this.onPressed});
  final int selectedEmployees;
  final bool submitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE6EAF0))), boxShadow: [BoxShadow(color: Color(0x12172033), blurRadius: 14, offset: Offset(0, -3))]),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ready to assign?', style: TextStyle(fontSize: 12, color: _muted)),
                Text(selectedEmployees == 0 ? 'Select employees to continue' : '$selectedEmployees employee${selectedEmployees == 1 ? '' : 's'} will receive this task', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: submitting
                  ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_task_rounded, size: 19),
              label: Text(submitting ? 'Creating...' : 'Create Task', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFAABCE4),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({required String label, required String hint, required IconData icon}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(fontSize: 12.5, color: _muted),
    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9AA3B2)),
    prefixIcon: Icon(icon, size: 19, color: _muted),
    filled: true,
    fillColor: const Color(0xFFF9FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E6ED))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _blue, width: 1.4)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD92D20))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.4)),
  );
}

String _format(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
