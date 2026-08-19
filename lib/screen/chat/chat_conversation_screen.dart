import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../model/chat/chat_group_model.dart';
import '../../model/chat/chat_message_model.dart';
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
  final Future<void> Function(String group)? onOpenGroupInfo;
  final Future<void> Function(ChatMessageModel message)? onOpenAttachment;

  const ChatConversationScreen({
    super.key,
    required this.initialGroup,
    this.messageEvents,
    this.deletedMessageEvents,
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
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatConversationViewModel(
      groupName: widget.initialGroup.name,
      messageEvents: widget.messageEvents,
      deletedEvents: widget.deletedMessageEvents,
    );
    _viewModel.addListener(_onViewModelChanged);
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    _viewModel.initialise();
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
    super.dispose();
  }

  void _onTextChanged() {
    final value = _messageController.text.trim().isNotEmpty;
    if (value != _hasText && mounted) setState(() => _hasText = value);
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
      title: InkWell(
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
        if (widget.onOpenGroupInfo != null)
          IconButton(onPressed: _openGroupInfo, tooltip: 'Group info', icon: const Icon(Icons.info_outline_rounded, size: 21)),
        const SizedBox(width: 3),
      ],
    );
  }

  Widget _buildConversation() {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5));
    }
    if (_viewModel.error != null && _viewModel.messages.isEmpty) {
      return _ConversationError(message: _viewModel.error!, onRetry: _viewModel.initialise);
    }
    if (_viewModel.messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _viewModel.refresh,
        color: _primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height: 150), _ConversationEmpty()],
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
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 12),
            itemCount: _viewModel.messages.length + (_viewModel.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (_viewModel.hasMore && index == 0) {
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
              final actualIndex = index - (_viewModel.hasMore ? 1 : 0);
              final message = _viewModel.messages[actualIndex];
              final previous = actualIndex > 0 ? _viewModel.messages[actualIndex - 1] : null;
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
                    onLongPress: message.isMine && !message.isDeleted ? () => _deleteMessage(message) : null,
                  ),
                ],
              );
            },
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
        child: Row(
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
                  child: Text(message.senderName, style: const TextStyle(color: _primary, fontSize: 10.5, fontWeight: FontWeight.w800)),
                ),
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
                child: Text(_clock(message.sentAt), style: const TextStyle(color: _muted, fontSize: 8.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
