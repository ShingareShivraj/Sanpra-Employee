import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../model/employee_profile_model.dart';
import 'employee_profile_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _page = Color(0xFFF4F7FC);
const _green = Color(0xFF159B65);

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final EmployeeProfileViewModel vm = EmployeeProfileViewModel();

  @override
  void initState() {
    super.initState();
    vm.addListener(_refresh);
    vm.loadProfile();
  }

  void _refresh() {
    if (mounted) setState(() {});
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
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Employee Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: vm.loading ? null : vm.loadProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _body(),
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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _ProfileHeader(profile: profile),
          if (vm.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InlineError(message: vm.errorMessage),
          ],
          const SizedBox(height: 12),
          _InformationCard(
            title: 'Personal Information',
            icon: Icons.person_outline_rounded,
            rows: [
              _Info('Email', profile.email, Icons.email_outlined),
              _Info('Mobile Number', profile.cellNumber, Icons.phone_outlined),
              _Info('Gender', profile.gender, Icons.wc_rounded),
              _Info(
                'Date of Birth',
                profile.dateOfBirth == null
                    ? ''
                    : DateFormat('dd MMM yyyy').format(profile.dateOfBirth!),
                Icons.cake_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InformationCard(
            title: 'Organization',
            icon: Icons.business_rounded,
            rows: [
              _Info('Company', profile.company, Icons.apartment_rounded),
              _Info('Department', profile.department, Icons.groups_outlined),
              _Info('Designation', profile.designation, Icons.badge_outlined),
              _Info('Reports To', profile.reportsToName,
                  Icons.account_tree_outlined,
                  subtitle: profile.reportsTo),
              _Info('Employment Type', profile.employmentType,
                  Icons.work_outline_rounded),
              _Info('Status', profile.status, Icons.verified_user_outlined,
                  status: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final EmployeeProfileModel profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blue, _darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x2B1B5FE0), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          _Avatar(profile: profile),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.employeeName.isEmpty ? 'Employee' : profile.employeeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 19,
                        fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 4),
                Text(profile.employeeId,
                    style: const TextStyle(color: Color(0xFFDDE8FF), fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    if (profile.designation.isNotEmpty)
                      _HeaderChip(icon: Icons.badge_outlined, text: profile.designation),
                    if (profile.company.isNotEmpty)
                      _HeaderChip(icon: Icons.apartment_rounded, text: profile.company),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final EmployeeProfileModel profile;
  const _Avatar({required this.profile});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: profile.image.isEmpty
            ? _initials()
            : Image.network(profile.image, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials()),
      ),
    );
  }
  Widget _initials() {
    final parts = profile.employeeName.trim().split(RegExp(r'\s+'));
    final initials = parts.where((e) => e.isNotEmpty).take(2)
        .map((e) => e[0].toUpperCase()).join();
    return Container(color: const Color(0xFFE8EFFF), alignment: Alignment.center,
      child: Text(initials.isEmpty ? 'E' : initials,
        style: const TextStyle(color: _blue, fontSize: 25, fontWeight: FontWeight.w800)));
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeaderChip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 190),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(9)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 5),
      Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _Info {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool status;
  const _Info(this.label, this.value, this.icon, {this.subtitle = '', this.status = false});
}

class _InformationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Info> rows;
  const _InformationCard({required this.title, required this.icon, required this.rows});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE5EAF2))),
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 13, 14, 10), child: Row(children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 17, color: _blue)),
        const SizedBox(width: 9),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
          color: Color(0xFF17233C))),
      ])),
      const Divider(height: 1, color: Color(0xFFEDF0F5)),
      ...List.generate(rows.length, (index) => _InfoRow(info: rows[index], last: index == rows.length - 1)),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final _Info info;
  final bool last;
  const _InfoRow({required this.info, required this.last});
  @override
  Widget build(BuildContext context) {
    final shown = info.value.isEmpty ? 'Not provided' : info.value;
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), child: Row(children: [
        Icon(info.icon, size: 18, color: const Color(0xFF64748B)), const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(info.label, style: const TextStyle(fontSize: 12, color: Color(0xFF7B879C),
            fontWeight: FontWeight.w600)), const SizedBox(height: 2),
          if (info.status && info.value.isNotEmpty)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE7F7F0), borderRadius: BorderRadius.circular(20)),
              child: Text(shown, style: const TextStyle(fontSize: 13, color: _green, fontWeight: FontWeight.w700)))
          else Text(shown, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: info.value.isEmpty ? const Color(0xFF9AA4B2) : const Color(0xFF24324A))),
          if (info.subtitle.isNotEmpty && info.subtitle != info.value)
            Padding(padding: const EdgeInsets.only(top: 2), child: Text(info.subtitle,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A94A6)))),
        ])),
      ])),
      if (!last) const Divider(height: 1, indent: 43, color: Color(0xFFF0F2F6)),
    ]);
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFFFFF0F1), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [const Icon(Icons.error_outline, color: Color(0xFFD43F50), size: 19),
      const SizedBox(width: 8), Expanded(child: Text(message, style: const TextStyle(fontSize: 13)))]));
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.person_off_outlined, size: 48, color: Color(0xFF8A94A6)),
      const SizedBox(height: 12), const Text('Profile unavailable',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 6),
      Text(message.isEmpty ? 'Unable to load your employee profile.' : message,
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: Color(0xFF667085))),
      const SizedBox(height: 16), FilledButton.icon(onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Try again'),
        style: FilledButton.styleFrom(backgroundColor: _blue)),
    ])));
}
