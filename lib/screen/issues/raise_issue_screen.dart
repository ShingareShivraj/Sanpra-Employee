import 'package:flutter/material.dart';

import 'raise_issue_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _primaryDark = Color(0xFF123FA0);
const _canvas = Color(0xFFF4F7FC);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);

class RaiseIssueScreen extends StatefulWidget {
  const RaiseIssueScreen({super.key});

  @override
  State<RaiseIssueScreen> createState() => _RaiseIssueScreenState();
}

class _RaiseIssueScreenState extends State<RaiseIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  late final RaiseIssueViewModel _vm;
  String _priority = 'Medium';
  String? _issueType;

  @override
  void initState() {
    super.initState();
    _vm = RaiseIssueViewModel()..addListener(_onChanged);
    _vm.loadIssueTypes();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final issue = await _vm.submit(
      subject: _subject.text,
      description: _description.text,
      priority: _priority,
      issueType: _issueType,
    );
    if (!mounted || issue == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('${issue.name} raised successfully'),
      ),
    );
    Navigator.pop(context, issue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Raise Issue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Report a workplace concern',
                style: TextStyle(fontSize: 11.5, color: Color(0xFFDCE8FF))),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
            children: [
              _hero(),
              const SizedBox(height: 12),
              _section(
                number: '1',
                title: 'Describe the issue',
                subtitle: 'Give enough information for quick action.',
                children: [
                  TextFormField(
                    controller: _subject,
                    maxLength: 140,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _input(
                      label: 'Subject',
                      hint: 'Enter a short, clear summary',
                      icon: Icons.title_rounded,
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? 'Enter a clear subject'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 5,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _input(
                      label: 'Description',
                      hint: 'Explain what happened, where, and what is affected',
                      icon: Icons.notes_rounded,
                      alignLabel: true,
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 5
                        ? 'Please add more details'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _section(
                number: '2',
                title: 'Classify the issue',
                subtitle: 'Issue type is optional. Select the urgency.',
                children: [
                  DropdownButtonFormField<String?>(
                    value: _issueType,
                    isExpanded: true,
                    icon: _vm.loadingTypes
                        ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.keyboard_arrow_down_rounded),
                    decoration: _input(
                      label: 'Issue Type (optional)',
                      hint: 'No Issue Type',
                      icon: Icons.category_outlined,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No Issue Type'),
                      ),
                      ..._vm.issueTypes.map(
                            (type) => DropdownMenuItem<String?>(
                          value: type,
                          child: Text(type, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: _vm.loadingTypes
                        ? null
                        : (value) => setState(() => _issueType = value),
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _priorityOption('Low', Icons.arrow_downward_rounded,
                          const Color(0xFF0E9F6E)),
                      const SizedBox(width: 8),
                      _priorityOption('Medium', Icons.remove_rounded,
                          const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _priorityOption('High', Icons.priority_high_rounded,
                          const Color(0xFFE5484D)),
                    ],
                  ),
                ],
              ),
              if (_vm.errorMessage != null) ...[
                const SizedBox(height: 12),
                _errorBanner(_vm.errorMessage!),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomAction(),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_primary, _primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
            color: Color(0x241B5FE0), blurRadius: 16, offset: Offset(0, 7)),
      ],
    ),
    child: const Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Color(0x26FFFFFF),
          child: Icon(Icons.support_agent_rounded,
              color: Colors.white, size: 25),
        ),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How can we help?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text(
                'Share clear details so your issue reaches the right person quickly.',
                style: TextStyle(
                    color: Color(0xFFDCE8FF), fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _section({
    required String number,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E9F2)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A172033), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(number,
                      style: const TextStyle(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11.5, color: _muted, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );

  Widget _priorityOption(String value, IconData icon, Color color) {
    final selected = _priority == value;
    return Expanded(
      child: InkWell(
        onTap: _vm.submitting ? null : () => setState(() => _priority = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(.09) : const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : const Color(0xFFDDE4EE),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : _muted, size: 19),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? color : _ink)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _input({
    required String label,
    required String hint,
    required IconData icon,
    bool alignLabel = false,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: alignLabel,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: alignLabel ? 72 : 0),
          child: Icon(icon, size: 20, color: _primary),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        counterText: '',
        labelStyle: const TextStyle(fontSize: 13, color: _muted),
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF98A2B3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        border: _border(const Color(0xFFD8E0EB)),
        enabledBorder: _border(const Color(0xFFD8E0EB)),
        focusedBorder: _border(_primary, width: 1.5),
        errorBorder: _border(const Color(0xFFE5484D)),
        focusedErrorBorder: _border(const Color(0xFFE5484D), width: 1.5),
      );

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _errorBanner(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFD5D8)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFB42318), size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12.5, color: Color(0xFF8E2020), height: 1.35)),
        ),
      ],
    ),
  );

  Widget _bottomAction() => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE4E9F1))),
    ),
    child: SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 9, 14, 12),
      child: SizedBox(
        height: 51,
        child: FilledButton.icon(
          onPressed: _vm.submitting ? null : _submit,
          icon: _vm.submitting
              ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Icons.send_rounded, size: 20),
          label: Text(_vm.submitting ? 'Raising issue...' : 'Raise Issue',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: const Color(0xFFAFC3ED),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13)),
          ),
        ),
      ),
    ),
  );
}
