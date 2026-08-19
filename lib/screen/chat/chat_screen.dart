import 'package:flutter/material.dart';

import '../../model/chat/chat_group_model.dart';
import '../../model/chat/chat_message_model.dart';
import 'chat_conversation_screen.dart';
import 'chat_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _text = Color(0xFF172033);
const _muted = Color(0xFF718096);

class ChatScreen extends StatefulWidget {
  final Stream<Map<String, dynamic>>? messageEvents;
  final Stream<Map<String, dynamic>>? deletedMessageEvents;
  final Future<void> Function()? onOpenManager;
  final Future<void> Function(String group)? onOpenGroupInfo;
  final Future<void> Function(ChatMessageModel message)? onOpenAttachment;

  const ChatScreen({
    super.key,
    this.messageEvents,
    this.deletedMessageEvents,
    this.onOpenManager,
    this.onOpenGroupInfo,
    this.onOpenAttachment,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatViewModel _viewModel;
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel(messageEvents: widget.messageEvents)..initialise();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openConversation(ChatGroupModel group) async {
    _viewModel.markLocallyRead(group.name);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          initialGroup: group,
          messageEvents: widget.messageEvents,
          deletedMessageEvents: widget.deletedMessageEvents,
          onOpenGroupInfo: widget.onOpenGroupInfo,
          onOpenAttachment: widget.onOpenAttachment,
        ),
      ),
    );
    await _viewModel.refresh();
  }

  Future<void> _openManager() async {
    if (widget.onOpenManager == null) {
      _showSnack('Connect onOpenManager after adding the manager screens.');
      return;
    }
    await widget.onOpenManager!();
    await _viewModel.refresh();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _viewModel.clearSearch();
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _background,
          appBar: _buildAppBar(),
          floatingActionButton: _viewModel.isChatManager
              ? FloatingActionButton.extended(
                  onPressed: _openManager,
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  icon: const Icon(Icons.group_add_rounded, size: 20),
                  label: const Text(
                    'Manage groups',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                )
              : null,
          body: _buildBody(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      titleSpacing: 16,
      title: _searching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _viewModel.search,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Search conversations',
                hintStyle: TextStyle(color: Color(0xFFCFDDFF), fontSize: 13),
                border: InputBorder.none,
              ),
            )
          : Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.forum_rounded, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Chat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Stay connected at work', style: TextStyle(fontSize: 10.5, color: Color(0xFFD7E3FF))),
                  ],
                ),
              ],
            ),
      actions: [
        if (!_searching && _viewModel.totalUnread > 0)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_viewModel.totalUnread}',
                style: const TextStyle(color: _primary, fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        IconButton(
          tooltip: _searching ? 'Close search' : 'Search',
          onPressed: _toggleSearch,
          icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5));
    }
    if (_viewModel.error != null && _viewModel.groups.isEmpty) {
      return _ErrorState(message: _viewModel.error!, onRetry: _viewModel.initialise);
    }
    final groups = _viewModel.visibleGroups;
    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_viewModel.error != null)
            SliverToBoxAdapter(
              child: _InlineError(message: _viewModel.error!),
            ),
          if (groups.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(searching: _searchController.text.isNotEmpty),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, _viewModel.isChatManager ? 88 : 18),
              sliver: SliverList.separated(
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (_, index) => _GroupTile(
                  group: groups[index],
                  onTap: () => _openConversation(groups[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final ChatGroupModel group;
  final VoidCallback onTap;

  const _GroupTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = group.unreadCount > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: unread ? const Color(0xFFC9D9FF) : const Color(0xFFE7EAF0)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A101828), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              _GroupAvatar(name: group.groupName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.groupName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _text,
                              fontSize: 13.5,
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _friendlyTime(group.lastMessageAt),
                          style: TextStyle(
                            color: unread ? _primary : _muted,
                            fontSize: 9.5,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (!group.canSend)
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(Icons.visibility_rounded, size: 13, color: _muted),
                          ),
                        Expanded(
                          child: Text(
                            group.lastMessage ?? group.description ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread ? const Color(0xFF46536A) : _muted,
                              fontSize: 11.5,
                              fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                            child: Text(
                              group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final String name;
  const _GroupAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'G' : name.trim()[0].toUpperCase();
    return Container(
      width: 47,
      height: 47,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primary, _darkBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool searching;
  const _EmptyState({required this.searching});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: const Color(0xFFE8EFFF), borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.forum_outlined, color: _primary, size: 34),
              ),
              const SizedBox(height: 14),
              Text(searching ? 'No matching chats' : 'No chats yet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _text)),
              const SizedBox(height: 5),
              Text(
                searching ? 'Try a different group name.' : 'Your employee groups will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 42, color: _muted),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 14),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Try again')),
            ],
          ),
        ),
      );
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD92D20), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB42318), fontSize: 11.5))),
        ]),
      );
}

String _friendlyTime(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return _clock(local);
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  if (now.difference(local).inDays < 7) {
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][local.weekday - 1];
  }
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _clock(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
}
