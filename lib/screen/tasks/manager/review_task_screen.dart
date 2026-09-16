import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../model/task_model.dart';
import 'review_task_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _accent = Color(0xFF4E8CFF);
const _dark = Color(0xFF123FA0);
const _page = Color(0xFFF4F7FC);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF68758C);
const _success = Color(0xFF139A68);
const _danger = Color(0xFFE1495B);

class ReviewTaskScreen extends StatefulWidget {
  const ReviewTaskScreen({super.key, required this.task});

  final TaskModel task;

  @override
  State<ReviewTaskScreen> createState() => _ReviewTaskScreenState();
}

class _ReviewTaskScreenState extends State<ReviewTaskScreen> {
  late final ReviewTaskViewModel viewModel;
  final TextEditingController remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    viewModel = ReviewTaskViewModel(task: widget.task)..load();
  }

  @override
  void dispose() {
    remarksController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final confirmed = await _confirmApproval();
    if (!confirmed) return;

    final success = await viewModel.approve();
    if (!mounted) return;
    if (success) {
      _message('Task approved and completed.', success: true);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _reject() async {
    remarksController.clear();
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _RejectSheet(controller: remarksController),
      ),
    );
    if (reason == null) return;

    final success = await viewModel.reject(remarks: reason);
    if (!mounted) return;
    if (success) {
      _message('Task returned to the employee.', success: true);
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _confirmApproval() async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFE7F8F1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.task_alt_rounded, color: _success),
        ),
        title: const Text(
          'Approve completion?',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'The task will be marked Completed and all open assignments will be closed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 13.5, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _success),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Approve'),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _message(String text, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? _success : _ink,
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.info_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        final showActions = !viewModel.loading && viewModel.canReview;
        return Scaffold(
          backgroundColor: _page,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: _ink,
            titleSpacing: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Task',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Verify the employee submission',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: viewModel.loading ? null : viewModel.load,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: _body(),
          bottomNavigationBar: showActions ? _reviewBar() : null,
        );
      },
    );
  }

  Widget _body() {
    if (viewModel.loading) return const _LoadingView();

    final task = viewModel.task;
    return RefreshIndicator(
      color: _primary,
      onRefresh: viewModel.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
        children: [
          _TaskHero(task: task),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.assignment_outlined,
            title: 'Task information',
            child: Column(
              children: [
                if (_hasText(task.description))
                  _TextBlock(
                    label: 'Description',
                    value: task.description!,
                  ),
                _InfoGrid(
                  items: [
                    _InfoItem(Icons.flag_outlined, 'Priority', task.priority),
                    _InfoItem(
                      Icons.folder_open_outlined,
                      'Project',
                      task.project,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            icon: Icons.person_outline_rounded,
            title: 'Employee submission',
            accent: _success,
            badge: 'READY TO REVIEW',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EmployeeRow(name: _employeeName(task)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE7ECF4)),
                ),
                if (_hasText(task.completionRemarks))
                  _TextBlock(
                    label: 'Completion remarks',
                    value: task.completionRemarks!,
                    highlighted: true,
                  )
                else
                  const _MissingEvidence(
                    icon: Icons.notes_rounded,
                    text: 'No completion remarks submitted',
                  ),
                if (task.completionTime != null) ...[
                  const SizedBox(height: 10),
                  _MetaLine(
                    icon: Icons.schedule_rounded,
                    label: 'Submitted',
                    value: _dateTime(task.completionTime)!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _evidenceCard(task),
          if (_hasText(viewModel.errorMessage)) ...[
            const SizedBox(height: 10),
            _ErrorCard(message: viewModel.errorMessage!),
          ],
          if (!viewModel.canReview && !_hasText(viewModel.errorMessage)) ...[
            const SizedBox(height: 10),
            const _ReadOnlyCard(),
          ],
        ],
      ),
    );
  }

  Widget _evidenceCard(TaskModel task) {
    final photoUrl = task.completionPhotoUrl ?? task.completionPhoto;
    final hasLocation = task.completionLatitude != null &&
        task.completionLongitude != null;

    return _SectionCard(
      icon: Icons.verified_outlined,
      title: 'Completion evidence',
      child: Column(
        children: [
          if (_hasText(photoUrl))
            _CompletionProof(
              url: photoUrl!,
              opening: viewModel.openingProof,
              onOpen: () async {
                final success = await viewModel.openProof(photoUrl);

                if (!mounted || success) return;

                _message(
                  viewModel.errorMessage ?? 'Unable to open proof.',
                );
              },
            )
          else
            const _MissingEvidence(
              icon: Icons.image_not_supported_outlined,
              text: 'No proof photo attached',
            ),
          const SizedBox(height: 10),
          if (hasLocation)
            _LocationTile(
              latitude: task.completionLatitude!,
              longitude: task.completionLongitude!,
              onCopied: () => _message('Location copied.'),
            )
          else
            const _MissingEvidence(
              icon: Icons.location_off_outlined,
              text: 'No completion location captured',
            ),
        ],
      ),
    );
  }

  Widget _reviewBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x160F244D),
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _danger,
                  side: const BorderSide(color: Color(0xFFF0A8B1)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: viewModel.submitting ? null : _reject,
                icon: const Icon(Icons.undo_rounded, size: 19),
                label: const Text(
                  'Return',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _success,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: viewModel.submitting ? null : _approve,
                icon: viewModel.submitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  viewModel.submitting ? 'Processing...' : 'Approve Completion',
                  style: const TextStyle(
                    fontSize: 14,
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
}

class _TaskHero extends StatelessWidget {
  const _TaskHero({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final title = task.subject.isEmpty ? task.name : task.subject;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_dark, _primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x351B5FE0),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fact_check_outlined, color: Colors.white),
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.17),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PENDING REVIEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  task.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.accent = _primary,
    this.badge,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B18345D),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F8F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: _success,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
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

class _InfoItem {
  const _InfoItem(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String? value;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.where((item) => _hasText(item.value)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visible
          .map(
            (item) => Container(
          width: (MediaQuery.sizeOf(context).width - 72) / 2,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FD),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 17, color: _primary),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(color: _muted, fontSize: 10.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: highlighted ? const EdgeInsets.all(11) : EdgeInsets.zero,
      decoration: highlighted
          ? BoxDecoration(
        color: const Color(0xFFF0F8F5),
        borderRadius: BorderRadius.circular(11),
        border: const Border(
          left: BorderSide(color: _success, width: 3),
        ),
      )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: highlighted ? _success : _muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: _ink, fontSize: 13.5, height: 1.42),
          ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_primary, _accent]),
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Task assignee',
                style: TextStyle(color: _muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const Icon(Icons.verified_rounded, color: _success, size: 19),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _muted),
        const SizedBox(width: 7),
        Text('$label: ', style: const TextStyle(color: _muted, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionProof extends StatelessWidget {
  const _CompletionProof({
    required this.url,
    required this.opening,
    required this.onOpen,
  });

  final String url;
  final bool opening;
  final VoidCallback onOpen;

  bool get isImage {
    final cleanUrl = Uri.tryParse(url)?.path.toLowerCase() ??
        url.toLowerCase();

    return cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.webp');
  }

  String get fileName {
    final uri = Uri.tryParse(url);

    if (uri != null && uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }

    return 'Completion proof';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE3E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                url,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;

                  return Container(
                    height: 180,
                    color: const Color(0xFFF0F3F8),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 90,
                  color: const Color(0xFFF2F4F7),
                  alignment: Alignment.center,
                  child: const Text(
                    'Use Open proof to view this private image',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          if (isImage) const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: opening ? null : onOpen,
              icon: opening
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : Icon(
                isImage
                    ? Icons.open_in_full_rounded
                    : Icons.open_in_new_rounded,
                size: 18,
              ),
              label: Text(
                opening
                    ? 'Opening...'
                    : isImage
                    ? 'Open full image'
                    : 'Open proof file',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.latitude,
    required this.longitude,
    required this.onCopied,
  });

  final double latitude;
  final double longitude;
  final VoidCallback onCopied;

  @override
  Widget build(BuildContext context) {
    final coordinates = '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFDDE8FA)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _primary.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined, color: _primary, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completion location',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  coordinates,
                  style: const TextStyle(color: _muted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Copy location',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: coordinates));
              onCopied();
            },
            icon: const Icon(Icons.copy_rounded, color: _primary, size: 18),
          ),
        ],
      ),
    );
  }
}

class _MissingEvidence extends StatelessWidget {
  const _MissingEvidence({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: _muted, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.controller});

  final TextEditingController controller;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  String? error;

  void _submit() {
    final value = widget.controller.text.trim();
    if (value.isEmpty) {
      setState(() => error = 'Please explain what the employee must correct.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DFE9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFFFFECEF),
                    child: Icon(Icons.undo_rounded, color: _danger, size: 20),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Return task for correction',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'The task will return to Working status.',
                          style: TextStyle(color: _muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: widget.controller,
                autofocus: true,
                minLines: 4,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (error != null) setState(() => error = null);
                },
                decoration: InputDecoration(
                  labelText: 'Correction required *',
                  hintText: 'Clearly explain what needs to be corrected...',
                  errorText: error,
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: const Color(0xFFF8F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: _danger, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _danger,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        'Return to Employee',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          CircularProgressIndicator(strokeWidth: 2.5, color: _primary),
          SizedBox(height: 11),
          Text(
            'Loading task submission...',
            style: TextStyle(color: _muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD2D8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _danger, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyCard extends StatelessWidget {
  const _ReadOnlyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5E1A9)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF9B7417), size: 19),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This task is no longer available for review.',
              style: TextStyle(color: Color(0xFF7D631F), fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _employeeName(TaskModel task) {
  if (_hasText(task.assignedTo)) return task.assignedTo!;
  if (task.assignees.isEmpty) return 'Employee not available';
  return task.assignees
      .map((item) => _hasText(item.fullName) ? item.fullName! : item.user)
      .join(', ');
}

String? _dateTime(DateTime? value) {
  if (value == null) return null;
  final date = value.toLocal();
  const months = [
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
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $period';
}
