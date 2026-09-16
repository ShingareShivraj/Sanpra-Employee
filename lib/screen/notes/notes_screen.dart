import 'package:flutter/material.dart';

import '../../model/note_model.dart';
import 'note_editor_screen.dart';
import 'notes_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE5EAF1);

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesViewModel _viewModel = NotesViewModel();
  final TextEditingController _searchController = TextEditingController();
  bool _gridView = false;

  @override
  void initState() {
    super.initState();
    _viewModel.initialise();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openEditor([NoteModel? note]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          note: note,
          viewModel: _viewModel,
        ),
      ),
    );
    if (changed == true) await _viewModel.refresh();
  }

  Future<void> _togglePin(NoteModel note) async {
    final saved = await _viewModel.togglePin(note);
    if (saved == null) _showError();
  }

  Future<void> _chooseColor(NoteModel note) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _NoteColorSheet(selectedColor: note.colorValue),
    );
    if (selected == null || selected == note.colorValue) return;
    final saved = await _viewModel.setNoteColor(note, selected);
    if (saved == null) _showError();
  }

  Future<void> _deleteNote(NoteModel note) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this note?'),
            content: Text(
              '“${note.displayTitle}” will be permanently removed from this device.',
            ),
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
    final deleted = await _viewModel.deleteNote(note);
    if (!deleted) _showError();
  }

  void _showError() {
    final message = _viewModel.error ?? 'Unable to complete this action.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: _ink,
          title: const Text(
            'My Notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: _gridView ? 'List view' : 'Grid view',
              onPressed: () => setState(() => _gridView = !_gridView),
              icon: Icon(
                _gridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _viewModel.refreshing ? null : _viewModel.refresh,
              icon: _viewModel.refreshing
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _viewModel.actionLoading ? null : () => _openEditor(),
          elevation: 4,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'New Note',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_viewModel.initialLoading) return const _NotesSkeleton();

    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _NotesHeader(total: _viewModel.totalNotes),
                const SizedBox(height: 12),
                _SearchField(
                  controller: _searchController,
                  onChanged: _viewModel.searchNotes,
                  onClear: () {
                    _searchController.clear();
                    _viewModel.clearSearch();
                  },
                ),
                if (_viewModel.error != null) ...[
                  const SizedBox(height: 9),
                  _InlineError(message: _viewModel.error!),
                ],
              ]),
            ),
          ),
          if (!_viewModel.hasNotes)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyNotes(
                searching: _viewModel.isSearching,
                onAdd: () => _openEditor(),
                onClear: () {
                  _searchController.clear();
                  _viewModel.clearSearch();
                },
              ),
            )
          else ...[
            if (_viewModel.pinnedNotes.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    icon: Icons.push_pin_rounded,
                    title: 'Pinned',
                    count: _viewModel.pinnedNotes.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 172,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _viewModel.pinnedNotes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final note = _viewModel.pinnedNotes[index];
                      return SizedBox(
                        width: 245,
                        child: _NoteCard(
                          note: note,
                          compact: true,
                          onTap: () => _openEditor(note),
                          onPin: () => _togglePin(note),
                          onColor: () => _chooseColor(note),
                          onDelete: () => _deleteNote(note),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            if (_viewModel.regularNotes.isNotEmpty) ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  _viewModel.pinnedNotes.isEmpty ? 8 : 17,
                  16,
                  8,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    icon: Icons.notes_rounded,
                    title: _viewModel.isSearching ? 'Search results' : 'All notes',
                    count: _viewModel.regularNotes.length,
                  ),
                ),
              ),
              if (_gridView)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: .88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = _viewModel.regularNotes[index];
                        return _NoteCard(
                          note: note,
                          compact: true,
                          onTap: () => _openEditor(note),
                          onPin: () => _togglePin(note),
                          onColor: () => _chooseColor(note),
                          onDelete: () => _deleteNote(note),
                        );
                      },
                      childCount: _viewModel.regularNotes.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = _viewModel.regularNotes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NoteCard(
                            note: note,
                            onTap: () => _openEditor(note),
                            onPin: () => _togglePin(note),
                            onColor: () => _chooseColor(note),
                            onDelete: () => _deleteNote(note),
                          ),
                        );
                      },
                      childCount: _viewModel.regularNotes.length,
                    ),
                  ),
                ),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ],
      ),
    );
  }
}

class _NotesHeader extends StatelessWidget {
  final int total;
  const _NotesHeader({required this.total});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_darkBlue, _primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30123FA0),
              blurRadius: 17,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.note_alt_outlined,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture every idea',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Private notes stored only on this device',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: _ink, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search title or note content...',
            hintStyle: const TextStyle(color: _muted, fontSize: 11),
            prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 20),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _primary, width: 1.3),
            ),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  const _SectionTitle({required this.icon, required this.title, required this.count});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: _primary, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: _darkBlue, fontSize: 8.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onColor;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onColor,
    required this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = noteBackgroundColor(note.colorValue);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 11, 8, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: note.hasCustomColor
                  ? _ink.withOpacity(.08)
                  : _border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.isPinned) ...[
                    const Icon(Icons.push_pin_rounded, color: _primary, size: 15),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Text(
                      note.displayTitle,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<_NoteAction>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    tooltip: 'Note actions',
                    onSelected: (action) {
                      switch (action) {
                        case _NoteAction.pin:
                          onPin();
                          break;
                        case _NoteAction.color:
                          onColor();
                          break;
                        case _NoteAction.delete:
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _NoteAction.pin,
                        child: Row(children: [
                          Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(note.isPinned ? 'Unpin note' : 'Pin note'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: _NoteAction.color,
                        child: Row(children: [
                          Icon(Icons.palette_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Change color'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: _NoteAction.delete,
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFD92D20)),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Color(0xFFD92D20))),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 7),
              if (compact)
                Expanded(child: _NotePreview(note: note, compact: true))
              else
                _NotePreview(note: note, compact: false),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, color: _muted.withOpacity(.75), size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _friendlyDate(note.updatedAt),
                      style: const TextStyle(color: _muted, fontSize: 8.8),
                    ),
                  ),
                  if (note.hasCustomColor)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(note.colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: _ink.withOpacity(.15)),
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
}

class _NotePreview extends StatelessWidget {
  final NoteModel note;
  final bool compact;
  const _NotePreview({required this.note, required this.compact});
  @override
  Widget build(BuildContext context) => Text(
        note.preview.isEmpty ? 'No additional content' : note.preview,
        maxLines: compact ? 5 : 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: note.preview.isEmpty ? _muted.withOpacity(.70) : _muted,
          fontSize: compact ? 10.5 : 11,
          height: 1.4,
          fontStyle: note.preview.isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      );
}

class _NoteColorSheet extends StatelessWidget {
  final int selectedColor;
  const _NoteColorSheet({required this.selectedColor});
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
                'Highlight note',
                style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a soft background color.',
                style: TextStyle(color: _muted, fontSize: 10.5),
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
                          color: selected ? _primary : _border,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, color: _primary, size: 20)
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

class _EmptyNotes extends StatelessWidget {
  final bool searching;
  final VoidCallback onAdd;
  final VoidCallback onClear;
  const _EmptyNotes({required this.searching, required this.onAdd, required this.onClear});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 105),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF1FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  searching ? Icons.search_off_rounded : Icons.note_add_outlined,
                  color: _primary,
                  size: 35,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                searching ? 'No notes found' : 'No notes yet',
                style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                searching
                    ? 'Try a different word or clear the search.'
                    : 'Create your first private note for an idea, meeting or reminder.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 10.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: searching ? onClear : onAdd,
                icon: Icon(searching ? Icons.close_rounded : Icons.add_rounded, size: 17),
                label: Text(searching ? 'Clear search' : 'Add Note'),
              ),
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
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFFB42318), fontSize: 10),
        ),
      );
}

class _NotesSkeleton extends StatelessWidget {
  const _NotesSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _skeleton(78, 17),
          const SizedBox(height: 12),
          _skeleton(46, 13),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _skeleton(160, 14)),
            const SizedBox(width: 10),
            Expanded(child: _skeleton(160, 14)),
          ]),
          const SizedBox(height: 18),
          _skeleton(135, 14),
          const SizedBox(height: 10),
          _skeleton(135, 14),
        ],
      );
}

Widget _skeleton(double height, double radius) => Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5EAF1),
        borderRadius: BorderRadius.circular(radius),
      ),
    );

String _friendlyDate(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final difference = today.difference(date).inDays;
  final time = '${_two(local.hour)}:${_two(local.minute)}';
  if (difference == 0) return 'Today, $time';
  if (difference == 1) return 'Yesterday, $time';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _two(int value) => value.toString().padLeft(2, '0');

enum _NoteAction { pin, color, delete }
