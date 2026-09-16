import 'package:flutter/material.dart';

import '../../model/meeting/meeting_model.dart';
import 'meeting_form_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE5EAF1);

class MeetingFormScreen extends StatefulWidget {
  final MeetingModel? meeting;

  const MeetingFormScreen({super.key, this.meeting});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final MeetingFormViewModel _viewModel;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _agendaController;
  late final TextEditingController _urlController;
  late DateTime _meetingDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late MeetingPlatform _platform;

  @override
  void initState() {
    super.initState();
    final meeting = widget.meeting;
    _viewModel = MeetingFormViewModel(initialMeeting: meeting);
    _titleController = TextEditingController(text: meeting?.meetingTitle ?? '');
    _descriptionController = TextEditingController(text: meeting?.description ?? '');
    _agendaController = TextEditingController(text: meeting?.meetingAgenda ?? '');
    _urlController = TextEditingController(text: meeting?.meetingUrl ?? '');
    _meetingDate = meeting?.meetingDate ?? DateTime.now();
    _startTime = _parseTime(meeting?.startTime) ?? TimeOfDay.now();
    _endTime = _parseTime(meeting?.endTime) ??
        TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);
    _platform = meeting?.meetingPlatform ?? MeetingPlatform.googleMeet;
    _viewModel.initialise();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _agendaController.dispose();
    _urlController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _meetingDate = picked);
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final start = DateTime(
      _meetingDate.year,
      _meetingDate.month,
      _meetingDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _meetingDate.year,
      _meetingDate.month,
      _meetingDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    final success = await _viewModel.save(
      meetingTitle: _titleController.text,
      description: _descriptionController.text,
      meetingAgenda: _agendaController.text,
      meetingDate: _meetingDate,
      startTime: start,
      endTime: end,
      platform: _platform,
      meetingUrl: _urlController.text,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.meeting == null
              ? 'Meeting created successfully.'
              : 'Meeting updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else if (_viewModel.error != null) {
      _showError(_viewModel.error!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFD92D20),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showEmployeePicker() async {
    final searchController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => Container(
          height: MediaQuery.of(context).size.height * .78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(top: 9, bottom: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D5DD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Select Participants',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(
                          'Done (${_viewModel.selectedEmployeeIds.length})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: TextField(
                    controller: searchController,
                    onChanged: _viewModel.searchEmployees,
                    decoration: _inputDecoration(
                      'Search employee',
                      Icons.search_rounded,
                    ),
                  ),
                ),
                Expanded(
                  child: _viewModel.employeesLoading && _viewModel.employees.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _primary,
                            strokeWidth: 2,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: _viewModel.employees.length +
                              (_viewModel.hasMoreEmployees ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _viewModel.employees.length) {
                              return Center(
                                child: TextButton(
                                  onPressed: _viewModel.employeesLoading
                                      ? null
                                      : () => _viewModel.loadEmployees(reset: false),
                                  child: const Text('Load more'),
                                ),
                              );
                            }
                            final employee = _viewModel.employees[index];
                            final selected = _viewModel.selectedEmployeeIds
                                .contains(employee.name);
                            return CheckboxListTile(
                              value: selected,
                              activeColor: _primary,
                              onChanged: (_) =>
                                  _viewModel.toggleEmployee(employee.name),
                              controlAffinity: ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                              secondary: CircleAvatar(
                                backgroundColor: _primary.withOpacity(.08),
                                foregroundColor: _primary,
                                child: Text(_initials(employee.employeeName)),
                              ),
                              title: Text(
                                employee.employeeName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [employee.designation, employee.department]
                                    .where((value) => value?.isNotEmpty == true)
                                    .join(' · '),
                                style: const TextStyle(fontSize: 10.5),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    searchController.dispose();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: _ink,
          title: Text(
            widget.meeting == null ? 'Create Meeting' : 'Edit Meeting',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        body: _viewModel.initialLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primary, strokeWidth: 2),
              )
            : _viewModel.error != null && _viewModel.employees.isEmpty
                ? _FormError(message: _viewModel.error!, onRetry: _viewModel.initialise)
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                      children: [
                        const _FormSectionTitle(
                          icon: Icons.info_outline_rounded,
                          title: 'Meeting Information',
                        ),
                        const SizedBox(height: 9),
                        _FormCard(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: _inputDecoration(
                                'Meeting title *',
                                Icons.title_rounded,
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _descriptionController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: _inputDecoration(
                                'Description',
                                Icons.notes_rounded,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _agendaController,
                              minLines: 3,
                              maxLines: 6,
                              decoration: _inputDecoration(
                                'Meeting agenda',
                                Icons.format_list_bulleted_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _FormSectionTitle(
                          icon: Icons.schedule_rounded,
                          title: 'Schedule',
                        ),
                        const SizedBox(height: 9),
                        _FormCard(
                          children: [
                            _PickerTile(
                              icon: Icons.calendar_today_rounded,
                              label: 'Meeting date',
                              value: _formatDate(_meetingDate),
                              onTap: _pickDate,
                            ),
                            const Divider(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _PickerTile(
                                    icon: Icons.login_rounded,
                                    label: 'Starts',
                                    value: _startTime.format(context),
                                    onTap: () => _pickTime(true),
                                  ),
                                ),
                                Container(width: 1, height: 42, color: _border),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: _PickerTile(
                                      icon: Icons.logout_rounded,
                                      label: 'Ends',
                                      value: _endTime.format(context),
                                      onTap: () => _pickTime(false),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _FormSectionTitle(
                          icon: Icons.video_call_outlined,
                          title: 'Join Details',
                        ),
                        const SizedBox(height: 9),
                        _FormCard(
                          children: [
                            DropdownButtonFormField<MeetingPlatform>(
                              value: _platform,
                              decoration: _inputDecoration(
                                'Platform',
                                Icons.video_camera_front_outlined,
                              ),
                              items: MeetingPlatform.values
                                  .map(
                                    (platform) => DropdownMenuItem(
                                      value: platform,
                                      child: Text(platform.apiValue),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _platform = value);
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _urlController,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              decoration: _inputDecoration(
                                'Meeting URL *',
                                Icons.link_rounded,
                              ),
                              validator: _urlValidator,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FormSectionTitle(
                          icon: Icons.people_outline_rounded,
                          title:
                              'Participants (${_viewModel.selectedEmployeeIds.length})',
                          action: TextButton.icon(
                            onPressed: _showEmployeePicker,
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                            label: const Text('Select'),
                          ),
                        ),
                        const SizedBox(height: 9),
                        _ParticipantSummary(
                          employees: _viewModel.employees,
                          selectedIds: _viewModel.selectedEmployeeIds,
                          onRemove: _viewModel.removeEmployee,
                          onSelect: _showEmployeePicker,
                        ),
                      ],
                    ),
                  ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _viewModel.saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _viewModel.saving
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(widget.meeting == null
                    ? Icons.add_circle_outline_rounded
                    : Icons.save_outlined),
            label: Text(
              widget.meeting == null ? 'Create Meeting' : 'Save Changes',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(children: children),
      );
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({required this.icon, required this.title, this.action});
  final IconData icon;
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: _primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _primary, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12.5,
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

class _ParticipantSummary extends StatelessWidget {
  const _ParticipantSummary({
    required this.employees,
    required this.selectedIds,
    required this.onRemove,
    required this.onSelect,
  });
  final List<MeetingEmployeeModel> employees;
  final Set<String> selectedIds;
  final ValueChanged<String> onRemove;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = employees
        .where((employee) => selectedIds.contains(employee.name))
        .toList(growable: false);
    if (selectedIds.isEmpty) {
      return InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: const Column(
            children: [
              Icon(Icons.person_add_alt_rounded, color: _primary),
              SizedBox(height: 5),
              Text('Select invited employees', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final employee in selected)
            InputChip(
              avatar: CircleAvatar(
                backgroundColor: _primary.withOpacity(.1),
                child: Text(
                  _initials(employee.employeeName),
                  style: const TextStyle(fontSize: 9, color: _primary),
                ),
              ),
              label: Text(employee.employeeName, style: const TextStyle(fontSize: 11)),
              onDeleted: () => onRemove(employee.name),
              side: const BorderSide(color: _border),
              backgroundColor: const Color(0xFFF8FAFC),
            ),
          if (selected.length < selectedIds.length)
            Chip(
              label: Text(
                '+${selectedIds.length - selected.length} selected',
                style: const TextStyle(fontSize: 11),
              ),
              side: const BorderSide(color: _border),
            ),
        ],
      ),
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}

InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: _muted),
      prefixIcon: Icon(icon, color: _muted, size: 19),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.3),
      ),
    );

String? _requiredValidator(String? value) =>
    value?.trim().isEmpty != false ? 'This field is required.' : null;

String? _urlValidator(String? value) {
  if (value?.trim().isEmpty != false) return 'Meeting URL is required.';
  final uri = Uri.tryParse(value!.trim());
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty) {
    return 'Enter a valid HTTP or HTTPS URL.';
  }
  return null;
}

TimeOfDay? _parseTime(String? value) {
  final parts = value?.split(':') ?? const [];
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  return hour == null || minute == null ? null : TimeOfDay(hour: hour, minute: minute);
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}
