import 'package:flutter/material.dart';

import 'submit_task_viewmodel.dart';

typedef TaskPhotoPicker = Future<String?> Function();

const _primary = Color(0xFF1B5FE0);
const _primaryDark = Color(0xFF123FA0);
const _accent = Color(0xFF4E8CFF);
const _ink = Color(0xFF17213A);
const _muted = Color(0xFF667085);
const _surface = Color(0xFFF4F7FC);
const _success = Color(0xFF168765);

class SubmitTaskScreen extends StatefulWidget {
  const SubmitTaskScreen({
    super.key,
    required this.taskName,
    this.photoPicker,
    this.photoUploader,
    this.locationProvider,
  });

  final String taskName;
  final TaskPhotoPicker? photoPicker;
  final TaskPhotoUploader? photoUploader;
  final TaskLocationProvider? locationProvider;

  @override
  State<SubmitTaskScreen> createState() => _SubmitTaskScreenState();
}

class _SubmitTaskScreenState extends State<SubmitTaskScreen> {
  final remarksController = TextEditingController();
  late final SubmitTaskViewModel viewModel;

  @override
  void initState() {
    super.initState();
    remarksController.addListener(_refreshRemarksState);
    viewModel = SubmitTaskViewModel(
      taskName: widget.taskName,
      photoUploader: widget.photoUploader,
      locationProvider: widget.locationProvider,
    );
  }

  void _refreshRemarksState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    remarksController
      ..removeListener(_refreshRemarksState)
      ..dispose();
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (widget.photoPicker == null || viewModel.submitting) return;
    final path = await widget.photoPicker!();
    if (path != null && mounted) viewModel.setPhoto(path);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (await viewModel.submit(remarksController.text) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task submitted for manager review.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _success,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          titleSpacing: 4,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit Task',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'Share your work for review',
                style: TextStyle(fontSize: 12, color: Color(0xFFCAD9FF)),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
            children: [
              _TaskHeader(taskName: widget.taskName),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.edit_note_rounded,
                title: 'Completion remarks',
                subtitle: 'Required',
                child: TextField(
                  controller: remarksController,
                  enabled: !viewModel.submitting,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 1000,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: _ink,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText:
                    'Briefly explain what was completed and the result...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF98A2B3),
                      fontWeight: FontWeight.w400,
                    ),
                    counterStyle: const TextStyle(fontSize: 11, color: _muted),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    contentPadding: const EdgeInsets.all(13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDDE4EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDDE4EF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primary, width: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (widget.photoPicker != null)
                _EvidenceTile(
                  icon: Icons.add_a_photo_outlined,
                  iconColor: const Color(0xFF7A52CC),
                  iconBackground: const Color(0xFFF0EAFE),
                  title: 'Proof photo',
                  subtitle: viewModel.selectedPhotoPath == null
                      ? 'Optional · Add a clear work photo'
                      : _fileName(viewModel.selectedPhotoPath!),
                  completed: viewModel.selectedPhotoPath != null,
                  busy: false,
                  actionLabel: viewModel.selectedPhotoPath == null
                      ? 'Add photo'
                      : 'Change',
                  onTap: viewModel.submitting ? null : _pickPhoto,
                  onRemove: viewModel.selectedPhotoPath == null ||
                      viewModel.submitting
                      ? null
                      : viewModel.removePhoto,
                ),
              if (widget.photoPicker != null &&
                  widget.locationProvider != null)
                const SizedBox(height: 9),
              if (widget.locationProvider != null)
                _EvidenceTile(
                  icon: Icons.my_location_rounded,
                  iconColor: const Color(0xFF0A7E8C),
                  iconBackground: const Color(0xFFE4F6F8),
                  title: 'Current location',
                  subtitle: viewModel.obtainingLocation
                      ? 'Getting your current position...'
                      : viewModel.location == null
                      ? 'Optional · Attach completion location'
                      : '${viewModel.location!.latitude.toStringAsFixed(6)}, '
                      '${viewModel.location!.longitude.toStringAsFixed(6)}',
                  completed: viewModel.location != null,
                  busy: viewModel.obtainingLocation,
                  actionLabel:
                  viewModel.location == null ? 'Add location' : 'Update',
                  onTap: viewModel.obtainingLocation || viewModel.submitting
                      ? null
                      : viewModel.captureLocation,
                  onRemove:
                  viewModel.location == null || viewModel.submitting
                      ? null
                      : viewModel.removeLocation,
                ),
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: 10),
                _ErrorBanner(message: viewModel.errorMessage!),
              ],
              const SizedBox(height: 12),
              const _ReviewNote(),
            ],
          ),
        ),
        bottomNavigationBar: _SubmitBar(
          submitting: viewModel.submitting,
          canSubmit: remarksController.text.trim().isNotEmpty,
          onSubmit: _submit,
        ),
      ),
    );
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.taskName});

  final String taskName;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_primaryDark, _primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _primary.withOpacity(.18),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.task_alt_rounded,
              color: Colors.white, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TASK READY FOR SUBMISSION',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: .7,
                  color: Color(0xFFCAD9FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                taskName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Working',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE4EAF3)),
    ),
    child: Column(
      children: [
        Row(
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
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB54708),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        child,
      ],
    ),
  );
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.busy,
    required this.actionLabel,
    required this.onTap,
    required this.onRemove,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool completed;
  final bool busy;
  final String actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: completed
            ? _success.withOpacity(.32)
            : const Color(0xFFE4EAF3),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(11),
          ),
          child: busy
              ? Padding(
            padding: const EdgeInsets.all(11),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: iconColor,
            ),
          )
              : Icon(completed ? Icons.check_rounded : icon,
              color: completed ? _success : iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: completed ? _success : _muted,
                  fontWeight:
                  completed ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
          ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: _primary,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          ),
          child: Text(
            actionLabel,
            style:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDEC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFAC5C2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFD92D20), size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReviewNote extends StatelessWidget {
  const _ReviewNote();

  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline_rounded, size: 17, color: _muted),
      SizedBox(width: 7),
      Expanded(
        child: Text(
          'After submission, this task moves to Pending Review. Your manager can approve it or return it with remarks.',
          style: TextStyle(fontSize: 12, height: 1.4, color: _muted),
        ),
      ),
    ],
  );
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.submitting,
    required this.canSubmit,
    required this.onSubmit,
  });

  final bool submitting;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      14,
      10,
      14,
      10 + MediaQuery.paddingOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE4EAF3))),
    ),
    child: SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: submitting || !canSubmit ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primary,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: submitting
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.send_rounded, size: 19),
        label: Text(
          submitting ? 'Submitting...' : 'Submit for Manager Review',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
