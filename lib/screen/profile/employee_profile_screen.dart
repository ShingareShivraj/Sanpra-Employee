import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../model/employee_profile_model.dart';
import 'employee_profile_viewmodel.dart';

const _page = Color(0xFFF5F8FC);
const _blue = Color(0xFF2563EB);
const _blueDark = Color(0xFF1D4ED8);
const _blueSoft = Color(0xFFEAF1FF);
const _textPrimary = Color(0xFF172033);
const _textSecondary = Color(0xFF7B8798);
const _border = Color(0xFFE7EBF0);

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final EmployeeProfileViewModel vm = EmployeeProfileViewModel();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    vm.addListener(_refresh);
    vm.loadProfile();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    vm.removeListener(_refresh);
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (vm.loading && !vm.hasProfile) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }

    if (!vm.hasProfile) {
      return _ErrorState(message: vm.errorMessage, onRetry: vm.loadProfile);
    }

    final profile = vm.profile!;

    return RefreshIndicator(
      color: _blue,
      onRefresh: vm.loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _ProfileHero(
            profile: profile,
            photoLoading: vm.photoLoading,
            onBack: () => Navigator.of(context).maybePop(),
            onChangePhoto: _showPhotoOptions,
          ),
          if (vm.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: _InlineError(message: vm.errorMessage),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const _SectionTitle(title: 'Personal information', icon: Icons.person_outline_rounded),
                const SizedBox(height: 10),
                _InformationCard(rows: [
                  _Info('Employee ID', profile.employeeId, Icons.badge_outlined),
                  _Info('Email', profile.email, Icons.email_outlined),
                  _Info('Mobile Number', profile.cellNumber, Icons.phone_outlined),
                  _Info('Gender', profile.gender, Icons.person_outline_rounded),
                  _Info('Date of Birth', profile.dateOfBirth == null ? '' : DateFormat('dd MMM yyyy').format(profile.dateOfBirth!), Icons.cake_outlined),
                ]),
                const SizedBox(height: 18),
                const _SectionTitle(title: 'Work information', icon: Icons.work_outline_rounded),
                const SizedBox(height: 10),
                _InformationCard(rows: [
                  _Info('Date of Joining', profile.dateOfJoining == null ? '' : DateFormat('dd MMM yyyy').format(profile.dateOfJoining!), Icons.calendar_month_outlined),
                  _Info('Company', profile.company, Icons.apartment_outlined),
                  _Info('Department', profile.department, Icons.groups_outlined),
                  _Info('Designation', profile.designation, Icons.work_outline_rounded),
                  _Info('Reports To', profile.reportsToName.isNotEmpty ? profile.reportsToName : profile.reportsTo, Icons.account_tree_outlined),
                  _Info('Employment Type', profile.employmentType, Icons.assignment_ind_outlined),
                  _Info('Status', profile.status, Icons.verified_user_outlined, status: true),
                ]),
                const SizedBox(height: 18),
                _EditProfileRow(onTap: vm.photoLoading ? null : _showPhotoOptions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhotoOptions() async {
    if (vm.photoLoading) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DEE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                _PhotoOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take Photo',
                  onTap: () => Navigator.pop(
                    context,
                    ImageSource.camera,
                  ),
                ),
                const SizedBox(height: 10),
                _PhotoOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  onTap: () => Navigator.pop(
                    context,
                    ImageSource.gallery,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (picked == null || !mounted) return;

      final success = await vm.updateProfilePhoto(
        File(picked.path),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (vm.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // IconButton(
          //   onPressed: onBack,
          //   padding: EdgeInsets.zero,
          //   icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: _textPrimary),
          // ),
          const Expanded(
            child: Text('My Profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final EmployeeProfileModel profile;
  final bool photoLoading;
  final VoidCallback onBack;
  final VoidCallback onChangePhoto;
  const _ProfileHero({required this.profile, required this.photoLoading, required this.onBack, required this.onChangePhoto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_blueDark, _blue]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
      child: Column(children: [
        SizedBox(height: 48, child: Row(children: [
          Material(color: Colors.white.withOpacity(.13), shape: const CircleBorder(), child: InkWell(onTap: onBack, customBorder: const CircleBorder(), child: const SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white)))),
          const Expanded(child: Text('My Profile', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
          const SizedBox(width: 44),
        ])),
        const SizedBox(height: 12),
        Stack(clipBehavior: Clip.none, children: [
          _Avatar(profile: profile, loading: photoLoading),
          Positioned(right: -3, bottom: -3, child: Material(color: Colors.white, shape: const CircleBorder(), elevation: 3, child: InkWell(onTap: photoLoading ? null : onChangePhoto, customBorder: const CircleBorder(), child: SizedBox(width: 34, height: 34, child: photoLoading ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: _blue)) : const Icon(Icons.camera_alt_rounded, size: 17, color: _blue))))),
        ]),
        const SizedBox(height: 13),
        Text(profile.employeeName.isEmpty ? 'Employee' : profile.employeeName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
        if (profile.designation.isNotEmpty) ...[const SizedBox(height: 4), Text(profile.designation, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w500))],
        if (profile.status.isNotEmpty) ...[const SizedBox(height: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(30)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 7), Text(profile.status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]))],
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: _blueSoft, borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: _blue, size: 17)), const SizedBox(width: 10), Text(title, style: const TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700))]);
}

class _Avatar extends StatelessWidget {
  final EmployeeProfileModel profile;
  final bool loading;
  const _Avatar({required this.profile, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading || profile.image.isEmpty ? null : () => _showFullImage(context),
      child: Container(width: 128, height: 128, padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: ClipOval(child: loading ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue)) : profile.image.isEmpty ? _initials() : Image.network(profile.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials()))),
    );
  }

  void _showFullImage(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Profile photo',
      barrierDismissible: true,
      barrierColor: const Color(0xEE08111F),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      profile.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 52,
                        );
                      },
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 16,
                  child: Material(
                    color: Colors.white.withOpacity(0.12),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Pinch to zoom',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  Widget _initials() {
    final parts = profile.employeeName.trim().split(RegExp(r'\s+'));
    final initials = parts.where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join();
    return Container(color: _blueSoft, alignment: Alignment.center, child: Text(initials.isEmpty ? 'E' : initials, style: const TextStyle(color: _blue, fontSize: 32, fontWeight: FontWeight.w700)));
  }
}

class _InformationCard extends StatelessWidget {
  final List<_Info> rows;

  const _InformationCard({
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [BoxShadow(color: Color(0x080F172A), blurRadius: 18, offset: Offset(0, 5))],
      ),
      child: Column(
        children: List.generate(
          rows.length,
              (index) => _InfoRow(
            info: rows[index],
            last: index == rows.length - 1,
          ),
        ),
      ),
    );
  }
}

class _Info {
  final String label;
  final String value;
  final IconData icon;
  final bool status;

  const _Info(
      this.label,
      this.value,
      this.icon, {
        this.status = false,
      });
}

class _InfoRow extends StatelessWidget {
  final _Info info;
  final bool last;

  const _InfoRow({
    required this.info,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final shown = info.value.isEmpty ? 'Not provided' : info.value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _blueSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  info.icon,
                  size: 18,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (info.status && info.value.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F7F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          shown,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                      )
                    else
                      Text(
                        shown,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: info.value.isEmpty
                              ? const Color(0xFF9AA4B2)
                              : _textPrimary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(
            height: 1,
            indent: 64,
            color: Color(0xFFF0F2F5),
          ),
      ],
    );
  }
}

class _EditProfileRow extends StatelessWidget {
  final VoidCallback? onTap;

  const _EditProfileRow({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PhotoOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FB),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: _blue,
                size: 21,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFD43F50),
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 48,
              color: Color(0xFF8A94A6),
            ),
            const SizedBox(height: 12),
            const Text(
              'Profile unavailable',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.isEmpty
                  ? 'Unable to load your employee profile.'
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
