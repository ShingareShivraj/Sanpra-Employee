import 'package:flutter/material.dart';

import '../../../model/chat/chat_member_model.dart';
import 'group_info_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _text = Color(0xFF172033);
const _muted = Color(0xFF718096);
const _danger = Color(0xFFD92D20);

class GroupInfoScreen extends StatefulWidget {
  final String groupName;
  const GroupInfoScreen({super.key, required this.groupName});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late final GroupInfoViewModel _viewModel;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _viewModel = GroupInfoViewModel(groupName: widget.groupName)..initialise();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<bool> _onBack() async {
    Navigator.pop(context, _changed);
    return false;
  }

  Future<void> _editGroup() async {
    final group = _viewModel.group;
    if (group == null || !_viewModel.canManage) return;
    final nameController = TextEditingController(text: group.groupName);
    final descriptionController = TextEditingController(text: group.description ?? '');
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit group', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameController,
                maxLength: 140,
                style: const TextStyle(fontSize: 12.5),
                validator: (value) => (value?.trim().isEmpty ?? true) ? 'Enter a group name' : null,
                decoration: _dialogInput('Group name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                maxLength: 1000,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(fontSize: 12.5),
                decoration: _dialogInput('Description', counter: false),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(dialogContext, true);
            },
            style: FilledButton.styleFrom(backgroundColor: _primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save == true) {
      final updated = await _viewModel.updateDetails(
        name: nameController.text,
        description: descriptionController.text,
      );
      if (updated) {
        _changed = true;
        _showSnack('Group details updated.');
      } else if (_viewModel.error != null) {
        _showSnack(_viewModel.error!, error: true);
      }
    }
    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _toggleActive() async {
    final activating = !_viewModel.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(activating ? 'Activate group?' : 'Deactivate group?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text(
          activating
              ? 'Members will be able to use the group again according to their send permission.'
              : 'Members will no longer be able to send messages. Chat history will remain safe.',
          style: const TextStyle(fontSize: 12.5, color: _muted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: activating ? _primary : _danger),
            child: Text(activating ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = await _viewModel.setActive(activating);
    if (updated) {
      _changed = true;
      _showSnack(activating ? 'Group activated.' : 'Group deactivated.');
    } else if (_viewModel.error != null) {
      _showSnack(_viewModel.error!, error: true);
    }
  }

  Future<void> _showAddMembers() async {
    if (!_viewModel.isActive) {
      _showSnack('Activate the group before adding members.', error: true);
      return;
    }
    await _viewModel.loadAvailableEmployees();
    if (!mounted) return;
    final searchController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => Container(
          height: MediaQuery.sizeOf(context).height * .78,
          decoration: const BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(children: [
              const SizedBox(height: 9),
              Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFD3DAE5), borderRadius: BorderRadius.circular(4))),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                child: Row(children: [
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Add group members', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w800)),
                      Text('Select employees and choose send access.', style: TextStyle(color: _muted, fontSize: 10)),
                    ]),
                  ),
                  if (_viewModel.selectedNewCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE7EEFF), borderRadius: BorderRadius.circular(9)),
                      child: Text('${_viewModel.selectedNewCount} selected', style: const TextStyle(color: _primary, fontSize: 9.5, fontWeight: FontWeight.w800)),
                    ),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close_rounded)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 7),
                child: TextField(
                  controller: searchController,
                  onChanged: _viewModel.searchAvailableEmployees,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search employees',
                    hintStyle: const TextStyle(fontSize: 11, color: _muted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _muted),
                    suffixIcon: _viewModel.loadingEmployees
                        ? const Padding(padding: EdgeInsets.all(13), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _primary, strokeWidth: 2)))
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE2E7EF))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE2E7EF))),
                  ),
                ),
              ),
              Expanded(
                child: _viewModel.availableEmployees.isEmpty
                    ? const Center(child: Text('No employees available to add.', style: TextStyle(color: _muted, fontSize: 11.5)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                        itemCount: _viewModel.availableEmployees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, index) => _AvailableEmployeeTile(
                          employee: _viewModel.availableEmployees[index],
                          viewModel: _viewModel,
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E7EF)))),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: _viewModel.saving || _viewModel.selectedNewCount == 0
                        ? null
                        : () async {
                            final added = await _viewModel.addSelectedMembers();
                            if (!mounted) return;
                            if (added) {
                              _changed = true;
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                              _showSnack('Members added successfully.');
                            }
                          },
                    style: FilledButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                    icon: _viewModel.saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text('Add ${_viewModel.selectedNewCount} members', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    searchController.dispose();
  }

  Future<void> _removeMember(ChatMemberModel member) async {
    if (member.isCurrentUser) {
      _showSnack('You cannot remove your own membership here.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove member?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('${member.employeeName} will lose access to this group. Existing message history will remain safe.', style: const TextStyle(fontSize: 12.5, color: _muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), style: TextButton.styleFrom(foregroundColor: _danger), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await _viewModel.removeMember(member);
    if (removed) {
      _changed = true;
      _showSnack('Member removed.');
    } else if (_viewModel.error != null) {
      _showSnack(_viewModel.error!, error: true);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? _danger : const Color(0xFF25324A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack,
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            title: const Text('Group Information', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            actions: [
              if (_viewModel.canManage)
                IconButton(onPressed: _viewModel.saving ? null : _editGroup, tooltip: 'Edit group', icon: const Icon(Icons.edit_rounded, size: 20)),
              const SizedBox(width: 4),
            ],
          ),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5));
    }
    if (_viewModel.details == null) {
      return _InfoError(message: _viewModel.error ?? 'Unable to load this group.', onRetry: _viewModel.initialise);
    }
    final group = _viewModel.group!;
    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _groupHeader(),
          if (_viewModel.error != null) _InlineError(message: _viewModel.error!, onClose: _viewModel.clearError),
          const SizedBox(height: 8),
          _descriptionCard(group.description),
          const SizedBox(height: 8),
          if (_viewModel.canManage) _managementActions(),
          if (_viewModel.canManage) const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text('Members (${_viewModel.members.length})', style: const TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w800))),
            if (_viewModel.canManage)
              TextButton.icon(
                onPressed: _viewModel.isActive && !_viewModel.saving ? _showAddMembers : null,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 4),
          ..._viewModel.members.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _MemberTile(
                  member: member,
                  canManage: _viewModel.canManage && _viewModel.isActive,
                  busy: _viewModel.busyEmployee == member.employee,
                  onPermissionChanged: (value) async {
                    final changed = await _viewModel.updatePermission(member, value);
                    if (changed) _changed = true;
                  },
                  onRemove: () => _removeMember(member),
                ),
              )),
        ],
      ),
    );
  }

  Widget _groupHeader() {
    final group = _viewModel.group!;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primary, _darkBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [BoxShadow(color: Color(0x2F1B5FE0), blurRadius: 15, offset: Offset(0, 7))],
      ),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(17)),
          child: Text(group.groupName.isEmpty ? 'G' : group.groupName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(group.groupName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${_viewModel.members.length} members', style: const TextStyle(color: Color(0xFFD7E3FF), fontSize: 10.5)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: group.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E2), borderRadius: BorderRadius.circular(9)),
              child: Text(group.isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(color: group.isActive ? const Color(0xFF15803D) : _danger, fontSize: 8.5, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _descriptionCard(String? description) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE2E7EF))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Description', style: TextStyle(color: _muted, fontSize: 9.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(description?.trim().isNotEmpty == true ? description! : 'No description provided.', style: const TextStyle(color: _text, fontSize: 11.5, height: 1.35)),
        ]),
      );

  Widget _managementActions() => Row(children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.edit_rounded,
            label: 'Edit details',
            color: _primary,
            onTap: _viewModel.saving ? null : _editGroup,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _ActionCard(
            icon: _viewModel.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
            label: _viewModel.isActive ? 'Deactivate' : 'Activate',
            color: _viewModel.isActive ? _danger : const Color(0xFF16834A),
            onTap: _viewModel.saving ? null : _toggleActive,
          ),
        ),
      ]);
}

class _MemberTile extends StatelessWidget {
  final ChatMemberModel member;
  final bool canManage;
  final bool busy;
  final ValueChanged<bool> onPermissionChanged;
  final VoidCallback onRemove;
  const _MemberTile({
    required this.member,
    required this.canManage,
    required this.busy,
    required this.onPermissionChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 5, 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E7EF))),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE7EEFF),
            child: Text(member.employeeName.isEmpty ? 'E' : member.employeeName[0].toUpperCase(), style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(member.employeeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w700))),
                if (member.isCurrentUser) ...[
                  const SizedBox(width: 5),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE7EEFF), borderRadius: BorderRadius.circular(6)), child: const Text('YOU', style: TextStyle(color: _primary, fontSize: 7.5, fontWeight: FontWeight.w800))),
                ],
              ]),
              const SizedBox(height: 2),
              Text(member.canSend ? 'Can send messages' : 'Read only', style: TextStyle(color: member.canSend ? const Color(0xFF16834A) : _muted, fontSize: 9.5, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (busy)
            const Padding(padding: EdgeInsets.all(11), child: SizedBox(width: 17, height: 17, child: CircularProgressIndicator(color: _primary, strokeWidth: 2)))
          else if (canManage) ...[
            SizedBox(
              height: 28,
              child: Switch.adaptive(
                value: member.canSend,
                onChanged: onPermissionChanged,
                activeColor: _primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Member actions',
              onSelected: (value) {
                if (value == 'remove') onRemove();
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'remove',
                  enabled: !member.isCurrentUser,
                  child: const Row(children: [Icon(Icons.person_remove_outlined, color: _danger, size: 18), SizedBox(width: 8), Text('Remove member')]),
                ),
              ],
              icon: const Icon(Icons.more_vert_rounded, color: _muted, size: 19),
            ),
          ],
        ]),
      );
}

class _AvailableEmployeeTile extends StatelessWidget {
  final ChatEmployeeModel employee;
  final GroupInfoViewModel viewModel;
  const _AvailableEmployeeTile({required this.employee, required this.viewModel});
  @override
  Widget build(BuildContext context) {
    final selected = viewModel.isNewMemberSelected(employee.employee);
    return Material(
      color: selected ? const Color(0xFFF5F8FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => viewModel.toggleNewMember(employee),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 7, 7),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? const Color(0xFFBDD0FF) : const Color(0xFFE2E7EF))),
          child: Row(children: [
            Checkbox(value: selected, onChanged: (_) => viewModel.toggleNewMember(employee), activeColor: _primary, visualDensity: VisualDensity.compact),
            CircleAvatar(radius: 17, backgroundColor: const Color(0xFFE7EEFF), child: Text(employee.employeeName.isEmpty ? 'E' : employee.employeeName[0].toUpperCase(), style: const TextStyle(color: _primary, fontSize: 11.5, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(employee.employeeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 11.5, fontWeight: FontWeight.w700)),
                Text(employee.designation ?? employee.department ?? employee.user, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 9)),
              ]),
            ),
            if (selected)
              Column(children: [
                const Text('Can send', style: TextStyle(color: _muted, fontSize: 8)),
                SizedBox(
                  height: 27,
                  child: Switch.adaptive(
                    value: viewModel.newMemberCanSend(employee.employee),
                    onChanged: (value) => viewModel.setNewMemberCanSend(employee.employee, value),
                    activeColor: _primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ]),
          ]),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

InputDecoration _dialogInput(String label, {bool counter = true}) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 11.5, color: _muted),
      counterText: counter ? null : '',
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E7EF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E7EF))),
    );

class _InfoError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _InfoError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: _muted),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 11.5)),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 17), label: const Text('Try again')),
          ]),
        ),
      );
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _InlineError({required this.message, required this.onClose});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
        decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: _danger, size: 17),
          const SizedBox(width: 7),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB42318), fontSize: 10.5))),
          IconButton(onPressed: onClose, visualDensity: VisualDensity.compact, icon: const Icon(Icons.close_rounded, color: _danger, size: 16)),
        ]),
      );
}
