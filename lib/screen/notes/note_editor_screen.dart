import 'package:flutter/material.dart';

import '../../model/note_model.dart';
import 'notes_viewmodel.dart';

const kNotesPrimary = Color(0xFF1B5FE0);
const kNotesDarkBlue = Color(0xFF123FA0);
const kNotesInk = Color(0xFF172033);
const kNotesMuted = Color(0xFF667085);
const kNotesBorder = Color(0xFFE5EAF1);

/// Zero uses the app's neutral note color. Remaining values are intentionally
/// soft so long-form note text stays readable.
const List<int> noteColorPalette = [
  NoteModel.defaultColorValue,
  0xFFFFF3B0,
  0xFFFFE4E6,
  0xFFE0F2FE,
  0xFFDCFCE7,
  0xFFEDE9FE,
  0xFFFFEDD5,
  0xFFF1F5F9,
];

Color noteBackgroundColor(int colorValue) => colorValue == 0
    ? Colors.white
    : Color(colorValue);

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  final NotesViewModel viewModel;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.viewModel,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _contentFocus;
  late bool _isPinned;
  late int _colorValue;
  late String _previousContent;
  bool _dirty = false;
  bool _saving = false;
  bool _applyingListFormat = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _contentFocus = FocusNode();
    _isPinned = widget.note?.isPinned ?? false;
    _colorValue = widget.note?.colorValue ?? NoteModel.defaultColorValue;
    _previousContent = _contentController.text;
    _titleController.addListener(_markDirty);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_markDirty)
      ..dispose();
    _contentController
      ..removeListener(_onContentChanged)
      ..dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  void _onContentChanged() {
    if (_applyingListFormat) return;
    if (mounted) setState(() => _dirty = true);

    final current = _contentController.text;
    final selection = _contentController.selection;
    final offset = selection.baseOffset;
    final insertedSingleNewLine = selection.isCollapsed &&
        offset > 0 &&
        current.length == _previousContent.length + 1 &&
        current.substring(offset - 1, offset) == '\n';

    if (insertedSingleNewLine) {
      _continueList(current, offset);
    }
    _previousContent = _contentController.text;
  }

  void _continueList(String current, int offset) {
    final beforeNewLine = current.substring(0, offset - 1);
    final lineStart = beforeNewLine.lastIndexOf('\n') + 1;
    final previousLine = beforeNewLine.substring(lineStart);

    final numbered = RegExp(r'^(\s*)(\d+)([.)])\s+(.*)$')
        .firstMatch(previousLine);
    if (numbered != null) {
      final body = numbered.group(4)?.trim() ?? '';
      if (body.isEmpty) {
        _exitEmptyList(current, lineStart, offset);
      } else {
        final next = int.parse(numbered.group(2)!) + 1;
        _insertAfterNewLine(
          current,
          offset,
          '${numbered.group(1)}$next${numbered.group(3)} ',
        );
      }
      return;
    }

    final checklist = RegExp(r'^(\s*)- \[([ xX])\]\s+(.*)$')
        .firstMatch(previousLine);
    if (checklist != null) {
      final body = checklist.group(3)?.trim() ?? '';
      if (body.isEmpty) {
        _exitEmptyList(current, lineStart, offset);
      } else {
        _insertAfterNewLine(
          current,
          offset,
          '${checklist.group(1)}- [ ] ',
        );
      }
      return;
    }

    final bullet = RegExp(r'^(\s*)([-*•])\s+(.*)$').firstMatch(previousLine);
    if (bullet != null) {
      final body = bullet.group(3)?.trim() ?? '';
      if (body.isEmpty) {
        _exitEmptyList(current, lineStart, offset);
      } else {
        _insertAfterNewLine(
          current,
          offset,
          '${bullet.group(1)}${bullet.group(2)} ',
        );
      }
    }
  }

  void _insertAfterNewLine(String current, int offset, String prefix) {
    _setContentValue(
      current.replaceRange(offset, offset, prefix),
      offset + prefix.length,
    );
  }

  void _exitEmptyList(String current, int lineStart, int offset) {
    final markerLength = (offset - 1) - lineStart;
    _setContentValue(
      current.replaceRange(lineStart, offset - 1, ''),
      offset - markerLength,
    );
  }

  void _setContentValue(String text, int offset) {
    _applyingListFormat = true;
    _contentController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
    _previousContent = text;
    _applyingListFormat = false;
  }

  void _insertListPrefix(String prefix) {
    _contentFocus.requestFocus();
    final text = _contentController.text;
    final selection = _contentController.selection;
    final offset = selection.isValid ? selection.start : text.length;
    final lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0) + 1;
    final lineEndIndex = text.indexOf('\n', offset);
    final lineEnd = lineEndIndex < 0 ? text.length : lineEndIndex;
    final line = text.substring(lineStart, lineEnd);
    if (line.trimLeft().startsWith(prefix.trim())) return;
    _setContentValue(
      text.replaceRange(lineStart, lineStart, prefix),
      offset + prefix.length,
    );
    _markDirty();
  }

  Future<bool> _save({bool closeAfterSave = true}) async {
    if (_saving) return false;
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      _showMessage('Enter a title or some note content before saving.');
      return false;
    }
    setState(() => _saving = true);

    NoteModel? saved;
    if (_isEditing) {
      saved = await widget.viewModel.updateNote(
        widget.note!.copyWith(
          title: _titleController.text,
          content: _contentController.text,
          isPinned: _isPinned,
          colorValue: _colorValue,
        ),
      );
    } else {
      saved = await widget.viewModel.createNote(
        title: _titleController.text,
        content: _contentController.text,
        isPinned: _isPinned,
        colorValue: _colorValue,
      );
    }

    if (!mounted) return saved != null;
    setState(() => _saving = false);
    if (saved == null) {
      _showMessage(widget.viewModel.error ?? 'Unable to save this note.');
      return false;
    }
    _dirty = false;
    if (closeAfterSave) Navigator.pop(context, true);
    return true;
  }

  Future<void> _delete() async {
    final note = widget.note;
    if (note == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this note?'),
            content: const Text('This note will be permanently removed from this device.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD92D20),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final deleted = await widget.viewModel.deleteNote(note);
    if (deleted && mounted) Navigator.pop(context, true);
  }

  Future<bool> _handleBack() async {
    if (!_dirty || _saving) return true;
    final action = await showDialog<_BackAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save changes?'),
        content: const Text('You have changes that have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _BackAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _BackAction.discard),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD92D20)),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _BackAction.save),
            style: FilledButton.styleFrom(backgroundColor: kNotesPrimary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (action == _BackAction.discard) return true;
    if (action == _BackAction.save) {
      await _save();
    }
    return false;
  }

  Future<void> _selectColor() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ColorPickerSheet(selectedColor: _colorValue),
    );
    if (selected == null || selected == _colorValue) return;
    setState(() {
      _colorValue = selected;
      _dirty = true;
    });
  }

  void _showShortcuts() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ShortcutsSheet(),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final background = noteBackgroundColor(_colorValue);
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: background,
          surfaceTintColor: background,
          foregroundColor: kNotesInk,
          titleSpacing: 0,
          title: Text(
            _isEditing ? 'Edit Note' : 'New Note',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          actions: [
            if (_isEditing)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') _delete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Color(0xFFD92D20), size: 19),
                        SizedBox(width: 8),
                        Text('Delete note'),
                      ],
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _saving ? null : () => _save(),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kNotesPrimary,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        enabled: !_saving,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: kNotesInk,
                          fontSize: 23,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(color: Color(0xFF98A2B3)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: kNotesInk.withOpacity(.08), height: 1),
                      const SizedBox(height: 13),
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocus,
                        enabled: !_saving,
                        minLines: 14,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: kNotesInk,
                          fontSize: 15,
                          height: 1.55,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Start writing your note...',
                          hintStyle: TextStyle(color: Color(0xFF98A2B3)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _EditorToolbar(
                content: _contentController.text,
                isPinned: _isPinned,
                colorValue: _colorValue,
                onPin: () => setState(() {
                  _isPinned = !_isPinned;
                  _dirty = true;
                }),
                onColor: _selectColor,
                onNumberedList: () => _insertListPrefix('1. '),
                onBulletList: () => _insertListPrefix('• '),
                onChecklist: () => _insertListPrefix('- [ ] '),
                onHelp: _showShortcuts,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  final String content;
  final bool isPinned;
  final int colorValue;
  final VoidCallback onPin;
  final VoidCallback onColor;
  final VoidCallback onNumberedList;
  final VoidCallback onBulletList;
  final VoidCallback onChecklist;
  final VoidCallback onHelp;

  const _EditorToolbar({
    required this.content,
    required this.isPinned,
    required this.colorValue,
    required this.onPin,
    required this.onColor,
    required this.onNumberedList,
    required this.onBulletList,
    required this.onChecklist,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    final words = content.trim().isEmpty
        ? 0
        : content.trim().split(RegExp(r'\s+')).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.90),
        border: const Border(top: BorderSide(color: kNotesBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _ToolbarButton(
              tooltip: isPinned ? 'Unpin note' : 'Pin note',
              icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              active: isPinned,
              onTap: onPin,
            ),
            _ColorToolbarButton(colorValue: colorValue, onTap: onColor),
            Container(width: 1, height: 22, color: kNotesBorder, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _ToolbarButton(tooltip: 'Numbered list', icon: Icons.format_list_numbered_rounded, onTap: onNumberedList),
            _ToolbarButton(tooltip: 'Bullet list', icon: Icons.format_list_bulleted_rounded, onTap: onBulletList),
            _ToolbarButton(tooltip: 'Checklist', icon: Icons.checklist_rounded, onTap: onChecklist),
            const Spacer(),
            Text('$words words', style: const TextStyle(color: kNotesMuted, fontSize: 9.5)),
            _ToolbarButton(tooltip: 'Writing shortcuts', icon: Icons.help_outline_rounded, onTap: onHelp),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
  });
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          icon,
          size: 20,
          color: active ? kNotesPrimary : kNotesMuted,
        ),
      );
}

class _ColorToolbarButton extends StatelessWidget {
  final int colorValue;
  final VoidCallback onTap;
  const _ColorToolbarButton({required this.colorValue, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Note color',
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            color: colorValue == 0 ? Colors.white : Color(colorValue),
            shape: BoxShape.circle,
            border: Border.all(color: kNotesMuted, width: 1.3),
          ),
        ),
      );
}

class _ColorPickerSheet extends StatelessWidget {
  final int selectedColor;
  const _ColorPickerSheet({required this.selectedColor});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D5DD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note color',
                style: TextStyle(color: kNotesInk, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'Use a soft color to highlight important notes.',
                style: TextStyle(color: kNotesMuted, fontSize: 10.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 13,
                runSpacing: 13,
                children: noteColorPalette.map((value) {
                  final selected = value == selectedColor;
                  return InkWell(
                    onTap: () => Navigator.pop(context, value),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: noteBackgroundColor(value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? kNotesPrimary : kNotesBorder,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, color: kNotesPrimary, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
}

class _ShortcutsSheet extends StatelessWidget {
  const _ShortcutsSheet();
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: SizedBox(width: 38, child: Divider(thickness: 4, color: Color(0xFFD0D5DD))),),
              SizedBox(height: 13),
              Text('Smart writing', style: TextStyle(color: kNotesInk, fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              _ShortcutRow(code: '1. ', text: 'Numbered list continues automatically'),
              _ShortcutRow(code: '• ', text: 'Bullet list continues automatically'),
              _ShortcutRow(code: '- [ ] ', text: 'Simple checklist continues automatically'),
              SizedBox(height: 9),
              Text('Press Enter on an empty list item to finish the list.', style: TextStyle(color: kNotesMuted, fontSize: 10.5)),
            ],
          ),
        ),
      );
}

class _ShortcutRow extends StatelessWidget {
  final String code;
  final String text;
  const _ShortcutRow({required this.code, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(width: 54, padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(7)), child: Text(code, textAlign: TextAlign.center, style: const TextStyle(color: kNotesDarkBlue, fontSize: 10, fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: kNotesInk, fontSize: 11))),
        ]),
      );
}

enum _BackAction { cancel, discard, save }
