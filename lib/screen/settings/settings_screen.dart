import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import 'change_password/change_password_page.dart';


const kBluePrimary = Color(0xFF1B5FE0);
const kBgGrey = Color(0xFFF4F6FA);

class SettingsScreen extends StatefulWidget {
  final Future<void> Function() onLogout;

  const SettingsScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  bool _loggingOut = false;
  bool _notificationsEnabled = true;
  bool _attendanceRemindersEnabled = false;

  Future<void> _handleLogout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);

    try {
      await widget.onLogout();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBluePrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) await _handleLogout();
  }

  Future<void> _openChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          onChangePassword: _settingsService.changePassword,
        ),
      ),
    );
  }

  // Future<void> _openAttendanceReminders() async {
  //   await showDialog<void>(
  //     context: context,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setDialogState) => AlertDialog(
  //         title: const Text(
  //           'Attendance Reminders',
  //           style: TextStyle(fontWeight: FontWeight.w700),
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Text(
  //               'Reminder timing will be based on your assigned shift from the attendance system.',
  //               style: TextStyle(height: 1.45, color: Colors.black54),
  //             ),
  //             const SizedBox(height: 12),
  //             SwitchListTile.adaptive(
  //               contentPadding: EdgeInsets.zero,
  //               title: const Text('Enable reminders'),
  //               value: _attendanceRemindersEnabled,
  //               activeColor: kBluePrimary,
  //               onChanged: (value) {
  //                 setDialogState(() {
  //                   _attendanceRemindersEnabled = value;
  //                 });
  //                 setState(() {});
  //               },
  //             ),
  //             const SizedBox(height: 4),
  //             const Align(
  //               alignment: Alignment.centerLeft,
  //               child: Text(
  //                 'Scheduling will be connected with Android notifications later.',
  //                 style: TextStyle(fontSize: 12, color: Colors.grey),
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text('Close'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<void> _showAboutApp() async {
    await _showInformationDialog(
      title: 'About App',
      icon: Icons.info_outline_rounded,
      content:
      'Sanpra Employee App\n\nManage attendance, tasks, meetings, communication and other employee activities from one place.',
    );
  }

  Future<void> _showPrivacyPolicy() async {
    await _showInformationDialog(
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_outlined,
      content:
      'Your account information is used to provide employee application features. Location and other permissions are used only for features that require them, such as attendance and visit-related workflows.\n\nThe complete privacy policy can be connected here later.',
    );
  }

  Future<void> _showInformationDialog({
    required String title,
    required IconData icon,
    required String content,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Icon(icon, color: kBluePrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(height: 1.5, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _sectionTitle('Account'),
            const SizedBox(height: 10),
            _settingsCard(
              children: [
                _settingsTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: kBluePrimary,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: _openChangePassword,
                ),
              ],
            ),
            // const SizedBox(height: 24),
            // _sectionTitle('Preferences'),
            // const SizedBox(height: 10),
            _settingsCard(
              children: [
                // _settingsTile(
                //   icon: Icons.alarm_outlined,
                //   iconColor: Colors.deepOrange,
                //   title: 'Attendance Reminders',
                //   subtitle: _attendanceRemindersEnabled
                //       ? 'Reminders enabled'
                //       : 'Manage attendance reminder settings',
                //   onTap: _openAttendanceReminders,
                // ),
                // _divider(),
                // _settingsTile(
                //   icon: Icons.notifications_none_rounded,
                //   iconColor: Colors.purple,
                //   title: 'Notifications',
                //   subtitle: _notificationsEnabled
                //       ? 'Notifications are enabled'
                //       : 'Notifications are disabled',
                //   trailing: Switch.adaptive(
                //     value: _notificationsEnabled,
                //     activeColor: kBluePrimary,
                //     onChanged: (value) {
                //       setState(() => _notificationsEnabled = value);
                //     },
                //   ),
                //   onTap: () {
                //     setState(() {
                //       _notificationsEnabled = !_notificationsEnabled;
                //     });
                //   },
                // ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Information'),
            const SizedBox(height: 10),
            _settingsCard(
              children: [
                _settingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.teal,
                  title: 'About App',
                  subtitle: 'Application information',
                  onTap: _showAboutApp,
                ),
                _divider(),
                _settingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.indigo,
                  title: 'Privacy Policy',
                  subtitle: 'Read privacy and data usage information',
                  onTap: _showPrivacyPolicy,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Session'),
            const SizedBox(height: 10),
            _settingsCard(
              children: [
                _settingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: Colors.red,
                  title: 'Logout',
                  subtitle: 'Sign out from this account',
                  trailing: _loggingOut
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kBluePrimary,
                    ),
                  )
                      : Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                  onTap: _loggingOut ? null : _confirmLogout,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Sanpra Employee App',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.7,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
          ),
      onTap: onTap,
    );
  }
}
