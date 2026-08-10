import 'package:flutter/material.dart';

import '../../../model/leaves/leave_type_model.dart';
import 'apply_leave_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _accent = Color(0xFF4E8CFF);
const _ink = Color(0xFF14213D);
const _muted = Color(0xFF68758A);
const _background = Color(0xFFF5F7FB);
const _success = Color(0xFF12805C);

class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({super.key});

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  late final ApplyLeaveViewModel vm;
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    vm = ApplyLeaveViewModel()..initialize();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    vm.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: DateTimeRange(start: vm.fromDate, end: vm.toDate),
      helpText: 'SELECT LEAVE DATES',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (range != null) vm.setDateRange(range.start, range.end);
  }

  Future<void> _selectHalfDayDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: vm.fromDate,
      lastDate: vm.toDate,
      initialDate: vm.halfDayDate ?? vm.fromDate,
      helpText: 'SELECT HALF-DAY DATE',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (date != null) vm.setHalfDayDate(date);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final result = await vm.submit(_reasonController.text);
    if (!mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave application submitted successfully.'),
        backgroundColor: _success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply Leave',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'Send a request for approval',
                style: TextStyle(fontSize: 11.5, color: Color(0xD9FFFFFF)),
              ),
            ],
          ),
        ),
        bottomNavigationBar: vm.isLoading ? null : _bottomAction(),
        body: vm.isLoading ? _loading() : _content(),
      ),
    );
  }

  Widget _loading() => const Center(
    child: CircularProgressIndicator(color: _blue),
  );

  Widget _content() {
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _hero(),
          const SizedBox(height: 14),
          _leaveInformation(),
          const SizedBox(height: 14),
          _halfDaySection(),
          const SizedBox(height: 14),
          _reasonSection(),
          if (vm.error != null) ...[
            const SizedBox(height: 12),
            _errorMessage(vm.error!),
          ],
        ],
      ),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_blue, _accent]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x261B5FE0),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: const Row(
      children: [
        _HeroIcon(),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan your time away',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Choose your leave type and dates. Your approver will be notified automatically.',
                style: TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _leaveInformation() => _section(
    title: 'Leave information',
    subtitle: 'Select the leave category and duration',
    icon: Icons.event_available_rounded,
    child: Column(
      children: [
        DropdownButtonFormField<LeaveTypeModel>(
          value: vm.selectedLeaveType,
          isExpanded: true,
          decoration: _inputDecoration(
            label: 'Leave type',
            icon: Icons.category_outlined,
          ),
          items: vm.leaveTypes
              .map(
                (type) => DropdownMenuItem(
              value: type,
              child: Text(
                '${type.leaveType}  •  ${_number(type.balance)} available',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
              .toList(),
          onChanged: vm.isSubmitting ? null : vm.selectLeaveType,
          validator: (value) =>
          value == null ? 'Please select a leave type' : null,
        ),
        if (vm.leaveTypes.isEmpty) ...[
          const SizedBox(height: 10),
          const _InformationNote(
            icon: Icons.info_outline_rounded,
            text: 'No leave type or active allocation is available.',
          ),
        ],
        const SizedBox(height: 14),
        InkWell(
          onTap: vm.isSubmitting ? null : _selectDateRange,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: _inputDecoration(
              label: 'Leave dates',
              icon: Icons.date_range_rounded,
            ),
            child: Row(
              children: [
                Expanded(child: _dateValue('FROM', vm.fromDate)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: _blue,
                    size: 20,
                  ),
                ),
                Expanded(child: _dateValue('TO', vm.toDate)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _durationSummary(),
      ],
    ),
  );

  Widget _durationSummary() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF1FF),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Icon(Icons.timelapse_rounded, color: _blue, size: 21),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'Requested duration',
            style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
          ),
        ),
        Text(
          '${_number(vm.requestedDays)} ${vm.requestedDays == 1 ? 'day' : 'days'}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: _blue,
          ),
        ),
      ],
    ),
  );

  Widget _halfDaySection() => _section(
    title: 'Half-day option',
    subtitle: 'Use only when one selected date is a half day',
    icon: Icons.schedule_rounded,
    child: Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: vm.isHalfDay,
          activeColor: _blue,
          onChanged: vm.isSubmitting ? null : vm.setHalfDay,
          title: const Text(
            'Include a half-day',
            style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
          ),
          subtitle: const Text(
            'The selected date counts as 0.5 day.',
            style: TextStyle(fontSize: 12, color: _muted),
          ),
        ),
        if (vm.isHalfDay) ...[
          const SizedBox(height: 5),
          InkWell(
            onTap: vm.isSubmitting ? null : _selectHalfDayDate,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: _inputDecoration(
                label: 'Half-day date',
                icon: Icons.today_rounded,
              ),
              child: Text(
                _date(vm.halfDayDate),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _reasonSection() => _section(
    title: 'Reason',
    subtitle: 'Add a clear note for your approver',
    icon: Icons.notes_rounded,
    child: TextFormField(
      controller: _reasonController,
      enabled: !vm.isSubmitting,
      minLines: 4,
      maxLines: 6,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      decoration: _inputDecoration(
        label: 'Reason for leave',
        icon: Icons.edit_note_rounded,
      ).copyWith(
        hintText: 'Briefly explain why you need leave...',
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter the reason for leave';
        }
        if (value.trim().length < 3) {
          return 'Please enter a clear reason';
        }
        return null;
      },
    ),
  );

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _blue, size: 19),
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
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _dateValue(String label, DateTime date) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8691A4),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _date(date),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: _ink,
          fontSize: 12.5,
        ),
      ),
    ],
  );

  Widget _errorMessage(String message) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFECEE),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFFFD4D8)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFB72C37),
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFB72C37),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _bottomAction() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: vm.isSubmitting || vm.leaveTypes.isEmpty ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
          disabledBackgroundColor: const Color(0xFFB8C7E4),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: vm.isSubmitting
            ? const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.send_rounded),
        label: Text(
          vm.isSubmitting ? 'Submitting...' : 'Submit Application',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ),
  );

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _blue, size: 21),
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: border(const Color(0xFFDDE3ED)),
      enabledBorder: border(const Color(0xFFDDE3ED)),
      focusedBorder: border(_blue, 1.5),
      errorBorder: border(const Color(0xFFCF3F4C)),
      focusedErrorBorder: border(const Color(0xFFCF3F4C), 1.5),
    );
  }

  String _date(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')} '
        '${_months[date.month - 1]} ${date.year}';
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  static const _months = [
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
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: const Color(0x26FFFFFF),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Icon(
      Icons.flight_takeoff_rounded,
      color: Colors.white,
      size: 26,
    ),
  );
}

class _InformationNote extends StatelessWidget {
  const _InformationNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: _muted),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 11.5, color: _muted),
        ),
      ),
    ],
  );
}
