import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../model/chat/chat_member_model.dart';
import 'create_group_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _background = Color(0xFFF4F6FA);
const _text = Color(0xFF172033);
const _muted = Color(0xFF718096);

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  late final CreateGroupViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = CreateGroupViewModel()..initialise();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await _viewModel.create(
      groupName: _nameController.text,
      description: _descriptionController.text,
      groupImage: _viewModel.groupImage,
    );
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat group created successfully.'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context, true);
    }
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
          title: const Text('Create Chat Group', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        body: _buildBody(),
        bottomNavigationBar: _viewModel.loading ? null : _buildBottomAction(),
      ),
    );
  }

  Future<void> _pickGroupImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      _viewModel.setGroupImage(File(image.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select group image: ${_cleanImageError(e)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeGroupImage() {
    _viewModel.clearGroupImage();
  }

  String _cleanImageError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Please try again.' : message;
  }

  Widget _buildBody() {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5));
    }
    if (_viewModel.error != null && _viewModel.employees.isEmpty) {
      return _CreateError(message: _viewModel.error!, onRetry: _viewModel.initialise);
    }
    return Form(
      key: _formKey,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            sliver: SliverToBoxAdapter(child: _groupDetailsCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            sliver: SliverToBoxAdapter(child: _memberHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverToBoxAdapter(child: _employeeSearch()),
          ),
          if (_viewModel.error != null)
            SliverToBoxAdapter(child: _InlineError(message: _viewModel.error!, onClose: _viewModel.clearError)),
          if (_viewModel.employees.isEmpty)
            const SliverToBoxAdapter(child: _NoEmployees())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 110),
              sliver: SliverList.separated(
                itemCount: _viewModel.employees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, index) {
                  final employee = _viewModel.employees[index];
                  return _EmployeeSelectionTile(employee: employee, viewModel: _viewModel);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _groupDetailsCard() {
    final groupImage = _viewModel.groupImage;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.forum_rounded, color: _primary, size: 19),
              SizedBox(width: 7),
              Text(
                'Group details',
                style: TextStyle(
                  color: _text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 31,
                    backgroundColor: const Color(0xFFE7EEFF),
                    backgroundImage:
                    groupImage != null ? FileImage(groupImage) : null,
                    child: groupImage == null
                        ? const Icon(
                      Icons.groups_rounded,
                      color: _primary,
                      size: 29,
                    )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: _primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _pickGroupImage,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Group image',
                      style: TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      groupImage == null
                          ? 'Add an image for this chat group (optional).'
                          : 'Image selected. You can change or remove it.',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickGroupImage,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(color: Color(0xFFBDD0FF)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          icon: const Icon(Icons.image_rounded, size: 15),
                          label: Text(
                            groupImage == null ? 'Choose image' : 'Change',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (groupImage != null)
                          TextButton(
                            onPressed: _removeGroupImage,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFD92D20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameController,
            maxLength: 140,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 12.5, color: _text),
            validator: (value) =>
            value?.trim().isEmpty ?? true ? 'Enter a group name' : null,
            decoration: _inputDecoration(
              'Group name',
              Icons.groups_rounded,
              counter: false,
            ),
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: _descriptionController,
            maxLength: 1000,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 12.5, color: _text),
            decoration: _inputDecoration(
              'Description (optional)',
              Icons.notes_rounded,
              counter: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberHeader() {
    return Row(children: [
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add employees', style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w800)),
          Text('Choose who can join and send messages.', style: TextStyle(color: _muted, fontSize: 10)),
        ]),
      ),
      if (_viewModel.selectedCount > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFE7EEFF), borderRadius: BorderRadius.circular(10)),
          child: Text('${_viewModel.selectedCount} selected', style: const TextStyle(color: _primary, fontSize: 9.5, fontWeight: FontWeight.w800)),
        ),
      PopupMenuButton<String>(
        tooltip: 'Selection options',
        onSelected: (value) => value == 'all' ? _viewModel.selectAllVisible() : _viewModel.clearSelection(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'all', child: Text('Select visible employees')),
          PopupMenuItem(value: 'clear', child: Text('Clear selection')),
        ],
        icon: const Icon(Icons.more_vert_rounded, color: _muted, size: 20),
      ),
    ]);
  }

  Widget _employeeSearch() {
    return TextField(
      controller: _searchController,
      onChanged: _viewModel.searchEmployees,
      style: const TextStyle(fontSize: 12, color: _text),
      decoration: InputDecoration(
        hintText: 'Search employee, department or email',
        hintStyle: const TextStyle(fontSize: 11, color: _muted),
        prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 18),
        suffixIcon: _viewModel.searching
            ? const Padding(
          padding: EdgeInsets.all(13),
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _primary, strokeWidth: 2)),
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE2E7EF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE2E7EF))),
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E7EF)))),
        child: SizedBox(
          height: 45,
          child: FilledButton.icon(
            onPressed: _viewModel.creating ? null : _create,
            style: FilledButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
            icon: _viewModel.creating
                ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.group_add_rounded, size: 19),
            label: Text(
              _viewModel.creating ? 'Creating group…' : 'Create group (${_viewModel.selectedCount})',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeSelectionTile extends StatelessWidget {
  final ChatEmployeeModel employee;
  final CreateGroupViewModel viewModel;
  const _EmployeeSelectionTile({required this.employee, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.isSelected(employee.employee);
    return Material(
      color: selected ? const Color(0xFFF5F8FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => viewModel.toggleEmployee(employee),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 8, 7, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? const Color(0xFFBDD0FF) : const Color(0xFFE2E7EF)),
          ),
          child: Row(children: [
            Checkbox(
              value: selected,
              onChanged: (_) => viewModel.toggleEmployee(employee),
              activeColor: _primary,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE7EEFF),
              child: Text(employee.employeeName.isEmpty ? 'E' : employee.employeeName[0].toUpperCase(), style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(employee.employeeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [employee.designation, employee.department].whereType<String>().where((value) => value.isNotEmpty).join(' • ').isEmpty
                      ? employee.user
                      : [employee.designation, employee.department].whereType<String>().where((value) => value.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 9.5),
                ),
              ]),
            ),
            if (selected)
              Column(children: [
                const Text('Can send', style: TextStyle(color: _muted, fontSize: 8.5)),
                SizedBox(
                  height: 28,
                  child: Switch.adaptive(
                    value: viewModel.canSend(employee.employee),
                    onChanged: (value) => viewModel.setCanSend(employee.employee, value),
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

InputDecoration _inputDecoration(String label, IconData icon, {bool counter = true}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 11.5, color: _muted),
    prefixIcon: Icon(icon, color: _primary, size: 18),
    counterText: counter ? null : '',
    filled: true,
    fillColor: const Color(0xFFF8FAFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE2E7EF))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE2E7EF))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _primary, width: 1.4)),
  );
}

class _CreateError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _CreateError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, color: _muted, size: 42),
        const SizedBox(height: 9),
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
    margin: const EdgeInsets.fromLTRB(12, 5, 12, 0),
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

class _NoEmployees extends StatelessWidget {
  const _NoEmployees();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(30),
    child: Column(children: [
      Icon(Icons.person_search_rounded, color: _muted, size: 38),
      SizedBox(height: 8),
      Text('No employees found', style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}
