import 'package:flutter/material.dart';

import 'submit_resolution_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _primaryDark = Color(0xFF123FA0);
const _canvas = Color(0xFFF4F7FC);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _success = Color(0xFF0E9F6E);
const _warning = Color(0xFFF59E0B);

class SubmitResolutionScreen extends StatefulWidget {
  const SubmitResolutionScreen({super.key, required this.issueName});

  final String issueName;

  @override
  State<SubmitResolutionScreen> createState() =>
      _SubmitResolutionScreenState();
}

class _SubmitResolutionScreenState extends State<SubmitResolutionScreen> {
  late final SubmitResolutionViewModel _vm;
  final _remarks = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _resolved = true;

  @override
  void initState() {
    super.initState();
    _vm = SubmitResolutionViewModel(widget.issueName)..addListener(_refresh);
    _remarks.addListener(_refresh);
    _vm.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _remarks.removeListener(_refresh);
    _remarks.dispose();
    _vm.removeListener(_refresh);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
          Text('Submit Resolution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Update the issue outcome',
              style: TextStyle(fontSize: 11.5, color: Color(0xFFDCE8FF))),
        ],
      ),
    ),
    body: _body(),
    bottomNavigationBar: _bottomAction(),
  );

  Widget _body() {
    if (_vm.loading && _vm.details == null) {
      return const _LoadingState();
    }
    if (_vm.details == null) {
      return _state(
        Icons.cloud_off_rounded,
        'Could not load issue',
        _vm.errorMessage ?? 'Please check your connection and try again.',
        _vm.load,
      );
    }

    final issue = _vm.details!.issue;
    return RefreshIndicator(
      color: _primary,
      onRefresh: _vm.load,
      child: Form(
        key: _formKey,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 112),
          children: [
            _issueHero(issue.name, issue.subject, issue.status),
            const SizedBox(height: 12),
            _section(
              icon: Icons.rule_rounded,
              title: 'Choose the outcome',
              subtitle: 'Select the result that accurately reflects your work.',
              child: Row(
                children: [
                  Expanded(
                    child: _choice(
                      resolved: true,
                      icon: Icons.task_alt_rounded,
                      title: 'Resolved',
                      subtitle: 'Issue is fixed',
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _choice(
                      resolved: false,
                      icon: Icons.report_problem_outlined,
                      title: 'Not Resolved',
                      subtitle: 'Need support',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _remarksSection(key: ValueKey(_resolved)),
            ),
            if (!_vm.canSubmit) ...[
              const SizedBox(height: 12),
              _notice(
                icon: Icons.lock_outline_rounded,
                color: _muted,
                background: const Color(0xFFF0F2F5),
                text: 'This issue is read-only or is not assigned to you.',
              ),
            ],
            if (_vm.errorMessage != null) ...[
              const SizedBox(height: 12),
              _notice(
                icon: Icons.error_outline_rounded,
                color: const Color(0xFFB42318),
                background: const Color(0xFFFFF1F2),
                text: _vm.errorMessage!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _issueHero(String name, String subject, String status) => Container(
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFFDCE8FF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700)),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(subject,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Color(0xFFDCE8FF), size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text('Submit a clear and accurate work update.',
                  style: TextStyle(
                      color: Color(0xFFDCE8FF), fontSize: 11.5)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: _primary, size: 18),
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
            child,
          ],
        ),
      );

  Widget _choice({
    required bool resolved,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _resolved == resolved;
    final color = resolved ? _success : _warning;
    return InkWell(
      onTap: _vm.submitting ? null : () => setState(() => _resolved = resolved),
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(.09) : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: selected ? color : const Color(0xFFDDE4EE),
              width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(.13) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: selected ? color : _muted, size: 20),
            ),
            const SizedBox(height: 7),
            Text(title,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? color : _ink)),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, color: _muted)),
          ],
        ),
      ),
    );
  }

  Widget _remarksSection({Key? key}) => Container(
    key: key,
    padding: const EdgeInsets.all(14),
    decoration: _box(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: (_resolved ? _success : _warning).withOpacity(.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                _resolved
                    ? Icons.fact_check_outlined
                    : Icons.handyman_outlined,
                color: _resolved ? _success : _warning,
                size: 18,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _resolved
                        ? 'Resolution details'
                        : 'Blocker and support required',
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _resolved
                        ? 'Explain what you did and confirm the result.'
                        : 'Explain why it is blocked and what help is needed.',
                    style: const TextStyle(
                        fontSize: 11.5, color: _muted, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        TextFormField(
          controller: _remarks,
          minLines: 5,
          maxLines: 9,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: _resolved
                ? 'Describe the action taken and final result...'
                : 'Describe the blocker and required support...',
            alignLabelWithHint: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFD),
            hintStyle:
            const TextStyle(fontSize: 12.5, color: Color(0xFF98A2B3)),
            contentPadding: const EdgeInsets.all(13),
            border: _fieldBorder(const Color(0xFFD8E0EB)),
            enabledBorder: _fieldBorder(const Color(0xFFD8E0EB)),
            focusedBorder: _fieldBorder(
                _resolved ? _success : _primary,
                width: 1.5),
            errorBorder: _fieldBorder(const Color(0xFFE5484D)),
            focusedErrorBorder:
            _fieldBorder(const Color(0xFFE5484D), width: 1.5),
          ),
          validator: (value) => value?.trim().isEmpty == true
              ? 'A clear remark is required'
              : null,
        ),
      ],
    ),
  );

  Widget? _bottomAction() {
    if (_vm.details == null) return null;
    final enabled = _vm.canSubmit &&
        !_vm.submitting &&
        _remarks.text.trim().isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E9F1))),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 9, 14, 12),
        child: SizedBox(
          height: 51,
          child: FilledButton.icon(
            onPressed: enabled ? _confirmAndSubmit : null,
            style: FilledButton.styleFrom(
              backgroundColor: _resolved ? _success : _primary,
              disabledBackgroundColor: const Color(0xFFB8C4D8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
            icon: _vm.submitting
                ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : Icon(_resolved
                ? Icons.check_circle_outline_rounded
                : Icons.send_rounded),
            label: Text(
              _vm.submitting
                  ? 'Submitting...'
                  : _resolved
                  ? 'Mark Issue Resolved'
                  : 'Submit Unable Remark',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndSubmit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;
    if (_resolved) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.task_alt_rounded, color: _success, size: 32),
          title: const Text('Mark issue as resolved?'),
          content: const Text(
            'Confirm that the work is complete and the resolution details are accurate.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _success),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    final ok = _resolved
        ? await _vm.resolve(_remarks.text)
        : await _vm.unableToResolve(_remarks.text);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(_resolved
            ? 'Issue marked as resolved'
            : 'Unable-to-resolve remark submitted'),
      ),
    );
    Navigator.pop(context, true);
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE3E9F2)),
    boxShadow: const [
      BoxShadow(
          color: Color(0x0A172033), blurRadius: 10, offset: Offset(0, 3)),
    ],
  );

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _notice({
    required IconData icon,
    required Color color,
    required Color background,
    required String text,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12.5, color: color, height: 1.35)),
            ),
          ],
        ),
      );

  Widget _state(IconData icon, String title, String message,
      Future<void> Function() retry) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                    color: Color(0xFFEAF1FF), shape: BoxShape.circle),
                child: Icon(icon, size: 32, color: _primary),
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5, color: _muted, height: 1.4)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _primary),
        SizedBox(height: 13),
        Text('Loading issue...',
            style: TextStyle(fontSize: 12.5, color: _muted)),
      ],
    ),
  );
}
