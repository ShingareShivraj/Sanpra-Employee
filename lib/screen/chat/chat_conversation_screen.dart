import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../model/chat/chat_group_model.dart';
import '../../model/chat/chat_message_model.dart';
import '../../services/api_endpoints.dart';
import 'chat_conversation_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF0F3F8);
const _text = Color(0xFF172033);
const _muted = Color(0xFF718096);

class ChatConversationScreen extends StatefulWidget {
  final ChatGroupModel initialGroup;
  final Stream<Map<String, dynamic>>? messageEvents;
  final Stream<Map<String, dynamic>>? deletedMessageEvents;
  final Stream<Map<String, dynamic>>? updatedMessageEvents;
  final Stream<Map<String, dynamic>>? reactionEvents;
  final Stream<Map<String, dynamic>>? typingEvents;
  final Stream<Map<String, dynamic>>? presenceEvents;
  final Future<void> Function(String group)? onOpenGroupInfo;
  final Future<void> Function(ChatMessageModel message)? onOpenAttachment;

  const ChatConversationScreen({
    super.key,
    required this.initialGroup,
    this.messageEvents,
    this.deletedMessageEvents,
    this.updatedMessageEvents,
    this.reactionEvents,
    this.typingEvents,
    this.presenceEvents,
    this.onOpenGroupInfo,
    this.onOpenAttachment,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  late final ChatConversationViewModel _viewModel;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _searching = false;
  final _searchController = TextEditingController();
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatConversationViewModel(
      groupName: widget.initialGroup.name,
      messageEvents: widget.messageEvents,
      deletedEvents: widget.deletedMessageEvents,
      updatedEvents: widget.updatedMessageEvents,
      reactionEvents: widget.reactionEvents,
      typingEvents: widget.typingEvents,
      presenceEvents: widget.presenceEvents,
    );
    _viewModel.addListener(_onViewModelChanged);
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    _viewModel.initialise();
    if (_viewModel.draft.isNotEmpty) {
      _messageController.text = _viewModel.draft;
      _messageController.selection =
          TextSelection.collapsed(offset: _messageController.text.length);
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _messageController
      ..removeListener(_onTextChanged)
      ..dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _messageController.text;
    _viewModel.saveDraft(text);
    final value = text.trim().isNotEmpty;
    if (value != _hasText && mounted) setState(() => _hasText = value);
    _viewModel.publishTyping(value);
    final selection = _messageController.selection;
    if (!selection.isValid || selection.start < 0) return;
    final beforeCursor = text.substring(0, selection.start);
    final match = RegExp(r'(?:^|\s)@([^\s@]*)$').firstMatch(beforeCursor);
    if (match == null) {
      _viewModel.clearMentionResults();
    } else {
      _viewModel.searchMentions(match.group(1) ?? '');
    }
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final count = _viewModel.messages.length;
    if (count > _previousMessageCount && !_viewModel.loadingOlder) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    _previousMessageCount = count;
  }

  Future<void> _onScroll() async {
    if (!_scrollController.hasClients || _scrollController.offset > 90) return;
    if (!_viewModel.hasMore || _viewModel.loadingOlder) return;
    final oldExtent = _scrollController.position.maxScrollExtent;
    await _viewModel.loadOlder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final difference = _scrollController.position.maxScrollExtent - oldExtent;
      final target = (_scrollController.offset + difference)
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();
      _scrollController.jumpTo(target);
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _sendText() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    final sent = await _viewModel.sendText(text);
    if (!mounted) return;
    if (sent) {
      _messageController.clear();
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else if (_viewModel.error != null) {
      _showSnack(_viewModel.error!, error: true);
    }
  }

  Future<void> _pickAttachment(ChatMessageType type) async {
    Navigator.pop(context);
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: type == ChatMessageType.image ? FileType.image : FileType.any,
        allowMultiple: false,
        withData: false,
      );
    } catch (_) {
      if (mounted) _showSnack('Unable to open the file picker.', error: true);
      return;
    }
    if (result == null || result.files.isEmpty || result.files.single.path == null) return;
    final file = result.files.single;
    final sent = await _viewModel.sendAttachment(
      filePath: file.path!,
      fileName: file.name,
      type: type,
    );
    if (!mounted) return;
    if (!sent && _viewModel.error != null) _showSnack(_viewModel.error!, error: true);
  }

  void _showAttachmentSheet() {
    if (!_viewModel.canSend || _viewModel.busy) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFD8DEE8), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Share with the group', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _text)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AttachmentOption(
                      icon: Icons.image_rounded,
                      label: 'Image',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _pickAttachment(ChatMessageType.image),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AttachmentOption(
                      icon: Icons.insert_drive_file_rounded,
                      label: 'Document',
                      color: _primary,
                      onTap: () => _pickAttachment(ChatMessageType.file),
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

  Future<void> _deleteMessage(ChatMessageModel message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete message?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text('This message will be removed for everyone in this group.', style: TextStyle(fontSize: 12.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD92D20)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _viewModel.deleteMessage(message);
    if (!mounted) return;
    if (!deleted && _viewModel.error != null) _showSnack(_viewModel.error!, error: true);
  }

  Future<void> _showMessageActions(ChatMessageModel message) async {
    if (message.isDeleted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['👍', '❤️', '😂', '😮', '😢', '🙏']
                .map((reaction) => InkWell(
              onTap: () {
                Navigator.pop(sheetContext);
                _viewModel.react(message, reaction);
              },
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(reaction, style: const TextStyle(fontSize: 23)),
              ),
            ))
                .toList(),
          ),
          const Divider(height: 1),
          _MessageAction(
            icon: Icons.reply_rounded,
            label: 'Reply',
            onTap: () {
              Navigator.pop(sheetContext);
              _viewModel.startReply(message);
              _focusNode.requestFocus();
            },
          ),
          if (message.messageType == ChatMessageType.text && message.message != null)
            _MessageAction(
              icon: Icons.copy_rounded,
              label: 'Copy',
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.message!));
                Navigator.pop(sheetContext);
                _showSnack('Message copied.');
              },
            ),
          _MessageAction(
            icon: Icons.forward_rounded,
            label: 'Forward',
            onTap: () {
              Navigator.pop(sheetContext);
              _forwardMessage(message);
            },
          ),
          _MessageAction(
            icon: message.isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
            label: message.isBookmarked ? 'Remove saved message' : 'Save message',
            onTap: () {
              Navigator.pop(sheetContext);
              _viewModel.toggleBookmark(message);
            },
          ),
          if (_viewModel.canManage)
            _MessageAction(
              icon: Icons.push_pin_outlined,
              label: _viewModel.pinnedMessages.any((item) => item.name == message.name)
                  ? 'Unpin message'
                  : 'Pin message',
              onTap: () {
                Navigator.pop(sheetContext);
                _viewModel.togglePin(message);
              },
            ),
          if (message.isMine && message.messageType == ChatMessageType.text)
            _MessageAction(
              icon: Icons.edit_rounded,
              label: 'Edit',
              onTap: () {
                Navigator.pop(sheetContext);
                _viewModel.startEdit(message);
                _messageController.text = message.message ?? '';
                _messageController.selection =
                    TextSelection.collapsed(offset: _messageController.text.length);
                _focusNode.requestFocus();
              },
            ),
          if (message.isMine)
            _MessageAction(
              icon: Icons.done_all_rounded,
              label: 'Message info',
              onTap: () {
                Navigator.pop(sheetContext);
                _showReadStatus(message);
              },
            ),
          if (message.isMine)
            _MessageAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: const Color(0xFFD92D20),
              onTap: () {
                Navigator.pop(sheetContext);
                _deleteMessage(message);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _forwardMessage(ChatMessageModel message) async {
    try {
      final groups = await _viewModel.loadForwardGroups();
      if (!mounted) return;
      final selected = <String>{};
      final destinations = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .65,
              child: Column(children: [
                const Text('Forward to', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (_, index) {
                      final group = groups[index];
                      return CheckboxListTile(
                        value: selected.contains(group.name),
                        activeColor: _primary,
                        title: Text(group.groupName),
                        subtitle: Text(group.description ?? '${group.memberCount} members'),
                        onChanged: (_) => setSheetState(() {
                          selected.contains(group.name)
                              ? selected.remove(group.name)
                              : selected.add(group.name);
                        }),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: selected.isEmpty
                          ? null
                          : () => Navigator.pop(sheetContext, selected.toList()),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text('Forward to ${selected.length} chat${selected.length == 1 ? '' : 's'}'),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
      if (destinations == null) return;
      final sent = await _viewModel.forwardMessage(message, destinations);
      if (!mounted) return;
      _showSnack(sent ? 'Message forwarded.' : (_viewModel.error ?? 'Unable to forward.'), error: !sent);
    } catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _showReadStatus(ChatMessageModel message) async {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => FutureBuilder<List<ChatMessageReadStatusModel>>(
        future: _viewModel.loadReadStatus(message),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
          }
          final rows = snapshot.data ?? const <ChatMessageReadStatusModel>[];
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 14),
              children: [
                const ListTile(title: Text('Message info', style: TextStyle(fontWeight: FontWeight.w800))),
                ...rows.map((row) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE7EEFF),
                    child: Text(row.employeeName.isEmpty ? 'E' : row.employeeName[0].toUpperCase()),
                  ),
                  title: Text(row.employeeName),
                  subtitle: Text(row.status),
                  trailing: Icon(row.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      color: row.isRead ? _primary : _muted),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectMention(ChatMentionModel member) {
    final text = _messageController.text;
    final cursor = _messageController.selection.start.clamp(0, text.length).toInt();
    final before = text.substring(0, cursor);
    final match = RegExp(r'(?:^|\s)@[^\s@]*$').firstMatch(before);
    if (match == null) return;
    final prefix = before.substring(0, match.start) + (match.start == 0 ? '' : ' ');
    final inserted = '@${member.employeeName} ';
    final updated = '$prefix$inserted${text.substring(cursor)}';
    _messageController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: (prefix + inserted).length),
    );
    _viewModel.selectMention(member);
    _focusNode.requestFocus();
  }

  Future<void> _openGroupInfo() async {
    if (widget.onOpenGroupInfo == null) return;
    await widget.onOpenGroupInfo!(widget.initialGroup.name);
    await _viewModel.refresh();
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFD92D20) : const Color(0xFF25324A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }


  Future<void> _downloadAttachment(ChatMessageModel message) async {
    if (message.attachment == null ||
        message.attachment!.trim().isEmpty) {
      return;
    }

    final filePath = await _viewModel.downloadAttachment(message);

    if (!mounted) return;

    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to download attachment'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await OpenFilex.open(filePath);

    if (!mounted) return;

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty
                ? 'Unable to open attachment'
                : result.message,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildConversation()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final group = _viewModel.group ?? widget.initialGroup;
    return AppBar(
      elevation: 0,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: _searching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: _viewModel.searchMessages,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.white,
        decoration: const InputDecoration(
          hintText: 'Search messages',
          hintStyle: TextStyle(color: Color(0xFFD7E3FF), fontSize: 12.5),
          border: InputBorder.none,
        ),
      )
          : InkWell(
        onTap: widget.onOpenGroupInfo == null ? null : _openGroupInfo,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(12)),
              child: Text(
                group.groupName.trim().isEmpty ? 'G' : group.groupName.trim()[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.groupName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text(
                    _viewModel.typingText ??
                        '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}${!group.isActive ? ' • Inactive' : ''}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFD7E3FF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: _searching ? 'Close search' : 'Search messages',
          onPressed: () {
            setState(() => _searching = !_searching);
            if (!_searching) {
              _searchController.clear();
              _viewModel.clearSearch();
            }
          },
          icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
        ),
        // if (widget.onOpenGroupInfo != null)
        //   IconButton(onPressed: _openGroupInfo, tooltip: 'Group info', icon: const Icon(Icons.info_outline_rounded, size: 21)),
        // const SizedBox(width: 3),
      ],
    );
  }

  Widget _buildConversation() {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5));
    }
    final displayMessages =
    _viewModel.searchMode ? _viewModel.searchResults : _viewModel.messages;
    if (_viewModel.error != null && displayMessages.isEmpty && !_viewModel.searchMode) {
      return _ConversationError(message: _viewModel.error!, onRetry: _viewModel.initialise);
    }
    if (displayMessages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _viewModel.refresh,
        color: _primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 150),
            _viewModel.searchMode
                ? const Center(child: Text('No matching messages', style: TextStyle(color: _muted, fontSize: 12)))
                : const _ConversationEmpty(),
          ],
        ),
      );
    }
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _viewModel.refresh,
          color: _primary,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              10,
              _viewModel.pinnedMessages.isNotEmpty && !_viewModel.searchMode ? 48 : 9,
              10,
              12,
            ),
            itemCount: displayMessages.length +
                (_viewModel.hasMore && !_viewModel.searchMode ? 1 : 0),
            itemBuilder: (context, index) {
              if (_viewModel.hasMore && !_viewModel.searchMode && index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: _viewModel.loadingOlder
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _primary, strokeWidth: 2))
                        : TextButton.icon(
                      onPressed: _viewModel.loadOlder,
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('Load earlier messages', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                );
              }
              final actualIndex = index -
                  (_viewModel.hasMore && !_viewModel.searchMode ? 1 : 0);
              final message = displayMessages[actualIndex];
              final previous =
              actualIndex > 0 ? displayMessages[actualIndex - 1] : null;
              final showDay = previous == null || !_sameDay(previous.sentAt, message.sentAt);
              final showSender = !message.isMine &&
                  (previous == null || previous.sender != message.sender || showDay);
              return Column(
                children: [
                  if (showDay) _DayDivider(date: message.sentAt),
                  _MessageBubble(
                    message: message,
                    showSender: showSender,
                    onAttachmentTap: message.attachment == null
                        ? null
                        : () => _downloadAttachment(message),
                    onLongPress: message.isDeleted
                        ? null
                        : () => _showMessageActions(message),
                  ),
                ],
              );
            },
          ),
        ),
        if (_viewModel.pinnedMessages.isNotEmpty && !_viewModel.searchMode)
          Positioned(
            top: 6,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFFF),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFC9D8FF)),
              ),
              child: Row(children: [
                const Icon(Icons.push_pin_rounded, color: _primary, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _viewModel.pinnedMessages.first.message ?? 'Pinned attachment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ),
        if (_viewModel.error != null)
          Positioned(
            top: 8,
            left: 14,
            right: 14,
            child: _ConversationBanner(message: _viewModel.error!, onClose: _viewModel.clearError),
          ),
      ],
    );
  }

  Widget _buildComposer() {
    if (_viewModel.searchMode) return const SizedBox.shrink();
    if (_viewModel.loading) return const SizedBox.shrink();
    if (!_viewModel.canSend) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE3E7EE)))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.visibility_rounded, size: 17, color: _muted),
            const SizedBox(width: 7),
            Text(
              _viewModel.group?.isActive == false ? 'This group is inactive.' : 'You can view messages in this group.',
              style: const TextStyle(fontSize: 11.5, color: _muted, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE3E7EE))),
          boxShadow: [BoxShadow(color: Color(0x0C101828), blurRadius: 10, offset: Offset(0, -3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_viewModel.replyingTo != null ||
                _viewModel.editingMessage != null)
              _ComposerContext(
                title: _viewModel.editingMessage != null
                    ? 'Editing message'
                    : 'Replying to ${_viewModel.replyingTo!.senderName}',
                message: (_viewModel.editingMessage ?? _viewModel.replyingTo)
                    ?.message ??
                    'Attachment',
                onClose: () {
                  final editing = _viewModel.editingMessage != null;
                  _viewModel.cancelReply();
                  _viewModel.cancelEdit();
                  if (editing) _messageController.clear();
                },
              ),
            if (_viewModel.mentionLoading ||
                _viewModel.mentionResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E6EF)),
                ),
                child: _viewModel.mentionLoading
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
                    : ListView(
                  shrinkWrap: true,
                  children: _viewModel.mentionResults
                      .map((member) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFFE7EEFF),
                      child: Text(
                        member.employeeName.isEmpty
                            ? 'E'
                            : member.employeeName[0].toUpperCase(),
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      member.employeeName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      member.designation ??
                          member.department ??
                          member.user,
                      style: const TextStyle(fontSize: 9.5),
                    ),
                    onTap: () => _selectMention(member),
                  ))
                      .toList(),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _viewModel.busy ? null : _showAttachmentSheet,
                  tooltip: 'Attach',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline_rounded, color: _primary, size: 25),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 42, maxHeight: 112),
                    decoration: BoxDecoration(color: const Color(0xFFF3F5F9), borderRadius: BorderRadius.circular(21)),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      enabled: !_viewModel.busy,
                      style: const TextStyle(fontSize: 13, color: _text, height: 1.35),
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: TextStyle(fontSize: 12.5, color: _muted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Material(
                    color: _hasText && !_viewModel.busy ? _primary : const Color(0xFFD7DEEA),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _hasText && !_viewModel.busy ? _sendText : null,
                      child: Center(
                        child: _viewModel.busy
                            ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool showSender;
  final VoidCallback? onLongPress;
  final VoidCallback? onAttachmentTap;
  const _MessageBubble({
    required this.message,
    required this.showSender,
    this.onLongPress,
    this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
          margin: EdgeInsets.only(left: mine ? 48 : 2, right: mine ? 2 : 48, bottom: 3),
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 5),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFFDCE8FF) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(mine ? 14 : 4),
              topRight: Radius.circular(mine ? 4 : 14),
              bottomLeft: const Radius.circular(14),
              bottomRight: const Radius.circular(14),
            ),
            border: Border.all(color: mine ? const Color(0xFFC6D9FF) : const Color(0xFFE1E5EC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSender)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: const Color(0xFFE7EEFF),
                      backgroundImage: _absoluteUrl(message.senderImage) == null
                          ? null
                          : NetworkImage(_absoluteUrl(message.senderImage)!),
                      child: _absoluteUrl(message.senderImage) == null
                          ? Text(
                        message.senderName.isEmpty
                            ? 'E'
                            : message.senderName[0].toUpperCase(),
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 5),
                    Text(message.senderName, style: const TextStyle(color: _primary, fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ]),
                ),
              if (message.isForwarded)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.forward_rounded, size: 13, color: _muted),
                    SizedBox(width: 3),
                    Text('Forwarded', style: TextStyle(color: _muted, fontSize: 9, fontStyle: FontStyle.italic)),
                  ]),
                ),
              if (message.replyTo != null)
                _ReplyPreview(reply: message.replyTo!),
              if (message.isDeleted)
                const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.block_rounded, size: 13, color: _muted),
                  SizedBox(width: 5),
                  Text('This message was deleted', style: TextStyle(color: _muted, fontSize: 11.5, fontStyle: FontStyle.italic)),
                ])
              else ...[
                if (message.messageType != ChatMessageType.text)
                  _AttachmentCard(message: message, onTap: onAttachmentTap),
                if (message.message?.isNotEmpty == true)
                  Padding(
                    padding: EdgeInsets.only(top: message.messageType == ChatMessageType.text ? 0 : 5),
                    child: Text(message.message!, style: const TextStyle(color: _text, fontSize: 12.5, height: 1.32)),
                  ),
              ],
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerRight,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (message.isEdited)
                    const Text('edited  ', style: TextStyle(color: _muted, fontSize: 8.5, fontStyle: FontStyle.italic)),
                  Text(_clock(message.sentAt), style: const TextStyle(color: _muted, fontSize: 8.5)),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all_rounded, size: 13, color: _primary),
                  ],
                ]),
              ),
              if (message.reactions.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: message.reactions
                      .map((reaction) => Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: reaction.reactedByMe
                          ? const Color(0xFFCFE0FF)
                          : const Color(0xFFF3F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${reaction.reaction} ${reaction.count}', style: const TextStyle(fontSize: 9.5)),
                  ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MessageAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _text,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(icon, color: color, size: 20),
    title: Text(
      label,
      style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600),
    ),
    onTap: onTap,
  );
}

class _ComposerContext extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const _ComposerContext({
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.fromLTRB(9, 5, 2, 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5FF),
      borderRadius: BorderRadius.circular(10),
      border: const Border(left: BorderSide(color: _primary, width: 3)),
    ),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.w700)),
          Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10)),
        ]),
      ),
      IconButton(
        onPressed: onClose,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.close_rounded, size: 17, color: _muted),
      ),
    ]),
  );
}

class _ReplyPreview extends StatelessWidget {
  final ChatReplyPreviewModel reply;
  const _ReplyPreview({required this.reply});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 5),
    padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
    decoration: BoxDecoration(
      color: const Color(0x151B5FE0),
      borderRadius: BorderRadius.circular(7),
      border: const Border(left: BorderSide(color: _primary, width: 3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(reply.senderName, style: const TextStyle(color: _primary, fontSize: 9.5, fontWeight: FontWeight.w700)),
      Text(
        reply.isDeleted
            ? 'This message was deleted'
            : reply.message ?? '${reply.messageType.name} attachment',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _muted, fontSize: 10),
      ),
    ]),
  );
}

class _AttachmentCard extends StatelessWidget {
  final ChatMessageModel message;
  final VoidCallback? onTap;
  const _AttachmentCard({required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = message.messageType == ChatMessageType.image;
    final fileName = Uri.tryParse(message.attachment ?? '')?.pathSegments.lastOrNull ??
        (image ? 'Image' : 'Document');
    return Material(
      color: Colors.white.withOpacity(.72),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 170),
          padding: const EdgeInsets.all(9),
          child: Row(children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: image ? const Color(0xFFF0E8FF) : const Color(0xFFE8EFFF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                image ? Icons.image_rounded : Icons.description_rounded,
                color: image ? const Color(0xFF7C3AED) : _primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  Text(
                    image ? 'Image attachment' : 'File attachment',
                    style: const TextStyle(fontSize: 9, color: _muted),
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.open_in_new_rounded, color: _muted, size: 14),
          ]),
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  final DateTime? date;
  const _DayDivider({required this.date});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFDCE3EE), borderRadius: BorderRadius.circular(12)),
        child: Text(_dayLabel(date), style: const TextStyle(fontSize: 9.5, color: Color(0xFF536179), fontWeight: FontWeight.w700)),
      ),
    ),
  );
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachmentOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: color.withOpacity(.08),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}

class _ConversationEmpty extends StatelessWidget {
  const _ConversationEmpty();
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(color: const Color(0xFFE1E9FA), borderRadius: BorderRadius.circular(21)),
      child: const Icon(Icons.waving_hand_rounded, color: _primary, size: 30),
    ),
    const SizedBox(height: 12),
    const Text('Start the conversation', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w800)),
    const SizedBox(height: 4),
    const Text('Messages shared here are visible to group members.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 11)),
  ]);
}

class _ConversationError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ConversationError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 40, color: _muted),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 17), label: const Text('Try again')),
      ]),
    ),
  );
}

class _ConversationBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _ConversationBanner({required this.message, required this.onClose});
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF0F0),
    borderRadius: BorderRadius.circular(12),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 5, 7),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFD92D20), size: 17),
        const SizedBox(width: 7),
        Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB42318), fontSize: 10.5))),
        IconButton(onPressed: onClose, visualDensity: VisualDensity.compact, icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFB42318))),
      ]),
    ),
  );
}

bool _sameDay(DateTime? first, DateTime? second) {
  if (first == null || second == null) return first == second;
  final a = first.toLocal();
  final b = second.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _dayLabel(DateTime? value) {
  if (value == null) return '';
  final date = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _clock(DateTime? value) {
  if (value == null) return '';
  final date = value.toLocal();
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
}

String? _absoluteUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri?.hasScheme == true) return text;
  return Uri.parse(ApiEndpoints.baseUrl).resolve(text).toString();
}

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
