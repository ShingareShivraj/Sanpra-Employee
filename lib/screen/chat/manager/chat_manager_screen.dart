import 'package:flutter/material.dart';

import '../../../model/chat/chat_group_model.dart';
import 'chat_manager_viewmodel.dart';
import 'create_group_screen.dart';
import 'group_info_screen.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _text = Color(0xFF172033);
const _muted = Color(0xFF718096);

class ChatManagerScreen extends StatefulWidget {
  const ChatManagerScreen({super.key});

  @override
  State<ChatManagerScreen> createState() => _ChatManagerScreenState();
}

class _ChatManagerScreenState extends State<ChatManagerScreen> {
  late final ChatManagerViewModel _viewModel;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ChatManagerViewModel()..initialise();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    if (changed == true) await _viewModel.refresh();
  }

  Future<void> _openGroup(ChatGroupModel group) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GroupInfoScreen(groupName: group.name)),
    );
    if (changed == true) await _viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('Chat Management', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(onPressed: _viewModel.refreshing ? null : _viewModel.refresh, tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded)),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: _viewModel.hasAccess
            ? FloatingActionButton.extended(
                onPressed: _createGroup,
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create group', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              )
            : null,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5));
    }
    if (_viewModel.error != null && _viewModel.groups.isEmpty) {
      return _ErrorState(message: _viewModel.error!, onRetry: _viewModel.initialise);
    }
    if (!_viewModel.hasAccess) {
      return const _AccessDenied();
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearch()),
          if (_viewModel.error != null)
            SliverToBoxAdapter(child: _InlineError(message: _viewModel.error!, onClose: _viewModel.clearError)),
          if (_viewModel.visibleGroups.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: _EmptyGroups())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              sliver: SliverList.separated(
                itemCount: _viewModel.visibleGroups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (_, index) {
                  final group = _viewModel.visibleGroups[index];
                  return _ManagedGroupCard(group: group, onTap: () => _openGroup(group));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 7),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primary, _darkBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x321B5FE0), blurRadius: 16, offset: Offset(0, 7))],
      ),
      child: Row(children: [
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your chat groups', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 3),
            Text('Create groups and control member access.', style: TextStyle(color: Color(0xFFD7E3FF), fontSize: 10.5)),
          ]),
        ),
        _HeaderStat(value: '${_viewModel.groupCount}', label: 'Groups'),
        const SizedBox(width: 7),
        _HeaderStat(value: '${_viewModel.totalMembers}', label: 'Members'),
      ]),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 2),
      child: TextField(
        controller: _searchController,
        onChanged: _viewModel.search,
        style: const TextStyle(fontSize: 12.5, color: _text),
        decoration: InputDecoration(
          hintText: 'Search managed groups',
          hintStyle: const TextStyle(fontSize: 11.5, color: _muted),
          prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 19),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _viewModel.search('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, size: 17),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E7EF))),
        ),
      ),
    );
  }
}

class _ManagedGroupCard extends StatelessWidget {
  final ChatGroupModel group;
  final VoidCallback onTap;
  const _ManagedGroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E7EF)),
              boxShadow: const [BoxShadow(color: Color(0x09101828), blurRadius: 9, offset: Offset(0, 3))],
            ),
            child: Row(children: [
              Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFE7EEFF), borderRadius: BorderRadius.circular(14)),
                child: Text(
                  group.groupName.isEmpty ? 'G' : group.groupName[0].toUpperCase(),
                  style: const TextStyle(color: _primary, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(group.groupName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w800))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE9F8EF), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Active', style: TextStyle(color: Color(0xFF16834A), fontSize: 8.5, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(group.description ?? 'No description', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10.5)),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.people_alt_outlined, size: 13, color: _muted),
                    const SizedBox(width: 4),
                    Text('${group.memberCount} members', style: const TextStyle(color: _muted, fontSize: 9.5, fontWeight: FontWeight.w600)),
                    if (group.unreadCount > 0) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.mark_chat_unread_outlined, size: 12, color: _primary),
                      const SizedBox(width: 3),
                      Text('${group.unreadCount} unread', style: const TextStyle(color: _primary, fontSize: 9.5, fontWeight: FontWeight.w700)),
                    ],
                  ]),
                ]),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ]),
          ),
        ),
      );
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        width: 54,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: Color(0xFFD7E3FF), fontSize: 8.5)),
        ]),
      );
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.admin_panel_settings_outlined, size: 46, color: _muted),
            SizedBox(height: 10),
            Text('Chat Manager access required', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text('Your account does not have permission to manage chat groups.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 11.5)),
          ]),
        ),
      );
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.groups_outlined, size: 48, color: _muted),
            SizedBox(height: 10),
            Text('No managed groups', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('Create your first employee chat group.', style: TextStyle(color: _muted, fontSize: 11.5)),
          ]),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, color: _muted, size: 42),
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
        margin: const EdgeInsets.fromLTRB(12, 7, 12, 0),
        padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
        decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD92D20), size: 17),
          const SizedBox(width: 7),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB42318), fontSize: 10.5))),
          IconButton(onPressed: onClose, visualDensity: VisualDensity.compact, icon: const Icon(Icons.close_rounded, color: Color(0xFFB42318), size: 16)),
        ]),
      );
}
