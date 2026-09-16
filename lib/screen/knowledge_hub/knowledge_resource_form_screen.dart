import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../model/knowledge_hub/knowledge_resource_member_model.dart';
import '../../model/knowledge_hub/knowledge_resource_model.dart';
import '../../model/knowledge_hub/knowledge_resource_type.dart';
import '../../services/knowledge_hub_service.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE5EAF1);

typedef KnowledgeEmployeeSearch =
    Future<List<KnowledgeResourceMemberModel>> Function(String search);

class KnowledgeResourceFormScreen extends StatefulWidget {
  final KnowledgeResourceModel? resource;
  final bool isKnowledgeManager;

  /// Optional company employee search supplied by the host app. When omitted,
  /// the member dialog accepts an Employee ID directly.
  final KnowledgeEmployeeSearch? employeeSearch;

  const KnowledgeResourceFormScreen({
    super.key,
    this.resource,
    this.isKnowledgeManager = false,
    this.employeeSearch,
  });

  @override
  State<KnowledgeResourceFormScreen> createState() =>
      _KnowledgeResourceFormScreenState();
}

class _KnowledgeResourceFormScreenState
    extends State<KnowledgeResourceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final KnowledgeHubService _service = KnowledgeHubService();

  late KnowledgeResourceType _type;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _urlController;
  late final TextEditingController _githubController;
  late final TextEditingController _documentationController;
  late final TextEditingController _tagsController;
  late final TextEditingController _technologiesController;
  late final TextEditingController _projectDescriptionController;
  late List<KnowledgeResourceMemberModel> _members;

  _SelectedFile? _attachment;
  _SelectedFile? _thumbnail;
  _SelectedFile? _projectBuild;
  _SelectedFile? _projectScreenshots;
  bool _saving = false;
  late bool _isManager;
  double? _uploadProgress;
  String? _error;

  bool get _isEditing => widget.resource != null;

  @override
  void initState() {
    super.initState();
    final resource = widget.resource;
    _isManager = widget.isKnowledgeManager;
    _type = resource?.resourceType ?? KnowledgeResourceType.usefulLink;
    _titleController = TextEditingController(text: resource?.resourceTitle ?? '');
    _descriptionController = TextEditingController(text: resource?.description ?? '');
    _urlController = TextEditingController(text: resource?.url ?? '');
    _githubController = TextEditingController(text: resource?.githubUrl ?? '');
    _documentationController =
        TextEditingController(text: resource?.documentationUrl ?? '');
    _tagsController = TextEditingController(text: resource?.tags ?? '');
    _technologiesController =
        TextEditingController(text: resource?.technologies ?? '');
    _projectDescriptionController =
        TextEditingController(text: _plainText(resource?.projectDescription));
    _members = List.of(resource?.teamMembers ?? const []);
    if (!_isManager) _loadAccess();
  }

  Future<void> _loadAccess() async {
    try {
      final access = await _service.getAccess();
      if (mounted && access.isKnowledgeManager) {
        setState(() => _isManager = true);
      }
    } catch (_) {
      // The backend remains authoritative. A failed optional role refresh must
      // not prevent an employee from completing the form.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _githubController.dispose();
    _documentationController.dispose();
    _tagsController.dispose();
    _technologiesController.dispose();
    _projectDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(_FileField field) async {
    final isImage = field == _FileField.thumbnail ||
        field == _FileField.projectScreenshots;
    final result = await FilePicker.platform.pickFiles(
      type: isImage ? FileType.image : FileType.any,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null || file.path!.isEmpty) {
      _showMessage('This file cannot be accessed on the device.');
      return;
    }
    final selected = _SelectedFile(path: file.path!, name: file.name);
    setState(() {
      switch (field) {
        case _FileField.attachment:
          _attachment = selected;
          break;
        case _FileField.thumbnail:
          _thumbnail = selected;
          break;
        case _FileField.projectBuild:
          _projectBuild = selected;
          break;
        case _FileField.projectScreenshots:
          _projectScreenshots = selected;
          break;
      }
    });
  }

  Future<String?> _upload(
    _SelectedFile? selected, {
    required String fieldName,
  }) async {
    if (selected == null) return null;
    return _service.uploadFile(
      filePath: selected.path,
      fileName: selected.name,
      resourceName: _isEditing ? widget.resource!.name : null,
      fieldName: _isEditing ? fieldName : null,
      isPrivate: true,
      onSendProgress: (sent, total) {
        if (!mounted || total <= 0) return;
        setState(() => _uploadProgress = sent / total);
      },
    );
  }

  Future<void> _save(_SaveMode mode) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_validateTypeFields()) return;
    if (_saving) return;
    setState(() {
      _saving = true;
      _uploadProgress = null;
      _error = null;
    });

    try {
      final attachment = _type.supportsAttachment
          ? await _upload(
                _attachment,
                fieldName: 'attachment',
              ) ??
              widget.resource?.attachment
          : '';
      final thumbnail = await _upload(
            _thumbnail,
            fieldName: 'thumbnail',
          ) ??
          widget.resource?.thumbnail;
      final projectBuild = _type.isProject
          ? await _upload(
                _projectBuild,
                fieldName: 'project_build',
              ) ??
              widget.resource?.projectBuild
          : '';
      final screenshots = _type.isProject
          ? await _upload(
                _projectScreenshots,
                fieldName: 'project_screenshots',
              ) ??
              widget.resource?.projectScreenshots
          : '';

      KnowledgeResourceModel saved;
      if (_isEditing) {
        saved = await _service.updateResource(
          resourceName: widget.resource!.name,
          resourceTitle: _titleController.text,
          resourceType: _type,
          description: _descriptionController.text,
          url: _type.supportsUrl ? _urlController.text : '',
          githubUrl: _type.isProject ? _githubController.text : '',
          documentationUrl:
              _type.isProject ? _documentationController.text : '',
          attachment: attachment,
          thumbnail: thumbnail,
          tags: _tagsController.text,
          technologies: _supportsTechnologies
              ? _technologiesController.text
              : '',
          projectDescription:
              _type.isProject ? _projectDescriptionController.text : '',
          projectBuild: projectBuild,
          projectScreenshots: screenshots,
          teamMembers: _type.isProject ? _members : const [],
          submitForReview: mode == _SaveMode.submit,
        );
        if (mode == _SaveMode.publish && !saved.isPublished) {
          saved = await _service.publishResource(saved.name);
        }
      } else {
        saved = await _service.createResource(
          resourceTitle: _titleController.text,
          resourceType: _type,
          description: _descriptionController.text,
          url: _type.supportsUrl ? _urlController.text : '',
          githubUrl: _type.isProject ? _githubController.text : '',
          documentationUrl:
              _type.isProject ? _documentationController.text : '',
          attachment: attachment,
          thumbnail: thumbnail,
          tags: _tagsController.text,
          technologies: _supportsTechnologies
              ? _technologiesController.text
              : '',
          projectDescription:
              _type.isProject ? _projectDescriptionController.text : '',
          projectBuild: projectBuild,
          projectScreenshots: screenshots,
          teamMembers: _type.isProject ? _members : const [],
          submitForReview: mode == _SaveMode.submit,
          publishNow: mode == _SaveMode.publish,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadProgress = null;
        });
      }
    }
  }

  bool _validateTypeFields() {
    String? message;
    if ((_type == KnowledgeResourceType.usefulLink ||
            _type == KnowledgeResourceType.courseLearning) &&
        _urlController.text.trim().isEmpty) {
      message = 'URL is required for this resource type.';
    } else if (_type == KnowledgeResourceType.document &&
        _attachment == null &&
        widget.resource?.attachment == null) {
      message = 'Please select a document attachment.';
    } else if (_type == KnowledgeResourceType.research &&
        _urlController.text.trim().isEmpty &&
        _attachment == null &&
        widget.resource?.attachment == null) {
      message = 'Research requires a URL or attachment.';
    } else if (_type == KnowledgeResourceType.companyResource &&
        _urlController.text.trim().isEmpty &&
        _attachment == null &&
        widget.resource?.attachment == null) {
      message = 'Add a URL or attachment for the company resource.';
    } else if (_type == KnowledgeResourceType.project &&
        _projectDescriptionController.text.trim().isEmpty &&
        _githubController.text.trim().isEmpty &&
        _documentationController.text.trim().isEmpty &&
        _projectBuild == null &&
        widget.resource?.projectBuild == null) {
      message = 'Add project details, a URL, or a project build.';
    }
    if (message == null) return true;
    setState(() => _error = message);
    return false;
  }

  Future<void> _addMember() async {
    final member = widget.employeeSearch == null
        ? await _manualMemberDialog()
        : await _searchMemberSheet();
    if (member == null || !mounted) return;
    if (_members.any((item) => item.employee == member.employee)) {
      _showMessage('This employee is already in the project team.');
      return;
    }
    setState(() => _members.add(member));
  }

  Future<KnowledgeResourceMemberModel?> _manualMemberDialog() async {
    final employee = TextEditingController();
    final role = TextEditingController();
    final result = await showDialog<KnowledgeResourceMemberModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add team member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: employee,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Employee ID',
                hintText: 'HR-EMP-00001',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: role,
              decoration: const InputDecoration(
                labelText: 'Project role',
                hintText: 'Developer',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (employee.text.trim().isEmpty) return;
              Navigator.pop(
                context,
                KnowledgeResourceMemberModel(
                  employee: employee.text.trim(),
                  employeeName: employee.text.trim(),
                  role: role.text.trim(),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    employee.dispose();
    role.dispose();
    return result;
  }

  Future<KnowledgeResourceMemberModel?> _searchMemberSheet() async {
    return showModalBottomSheet<KnowledgeResourceMemberModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EmployeeSearchSheet(search: widget.employeeSearch!),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        titleSpacing: 0,
        title: Text(
          _isEditing ? 'Edit Knowledge' : 'Add Knowledge',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            _FormIntro(isEditing: _isEditing),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Basic information',
              icon: Icons.article_outlined,
              children: [
                DropdownButtonFormField<KnowledgeResourceType>(
                  value: _type,
                  decoration: _decoration('Resource type'),
                  items: KnowledgeResourceType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.apiValue),
                          ))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _type = value);
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  enabled: !_saving,
                  maxLength: 140,
                  decoration: _decoration('Resource title', hint: 'Enter a clear title'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  minLines: 4,
                  maxLines: 7,
                  decoration: _decoration(
                    'Description',
                    hint: 'Explain why this resource is useful',
                  ),
                  validator: _requiredValidator,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._dynamicSections(),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Presentation',
              icon: Icons.auto_awesome_outlined,
              children: [
                _FilePickerTile(
                  title: 'Thumbnail',
                  subtitle: _thumbnail?.name ??
                      _fileName(widget.resource?.thumbnail) ??
                      'Optional cover image',
                  icon: Icons.image_outlined,
                  selected: _thumbnail != null || widget.resource?.thumbnail != null,
                  onTap: _saving ? null : () => _pickFile(_FileField.thumbnail),
                  onClear: _thumbnail == null
                      ? null
                      : () => setState(() => _thumbnail = null),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBox(message: _error!),
            ],
            if (_uploadProgress != null) ...[
              const SizedBox(height: 12),
              _UploadProgress(value: _uploadProgress!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _bottomActions(),
    );
  }

  List<Widget> _dynamicSections() {
    final sections = <Widget>[];
    if (_type.supportsUrl) {
      sections.add(_SectionCard(
        title: 'Resource link',
        icon: Icons.link_rounded,
        children: [
          TextFormField(
            controller: _urlController,
            enabled: !_saving,
            keyboardType: TextInputType.url,
            decoration: _decoration('URL', hint: 'https://example.com'),
            validator: (value) => _urlValidator(value, required: _type == KnowledgeResourceType.usefulLink || _type == KnowledgeResourceType.courseLearning),
          ),
        ],
      ));
      sections.add(const SizedBox(height: 12));
    }
    if (_type.supportsAttachment) {
      sections.add(_SectionCard(
        title: 'Attachment',
        icon: Icons.attach_file_rounded,
        children: [
          _FilePickerTile(
            title: _type == KnowledgeResourceType.document ? 'Select document' : 'Select attachment',
            subtitle: _attachment?.name ?? _fileName(widget.resource?.attachment) ?? 'Choose a file from this device',
            icon: Icons.upload_file_rounded,
            selected: _attachment != null || widget.resource?.attachment != null,
            onTap: _saving ? null : () => _pickFile(_FileField.attachment),
            onClear: _attachment == null ? null : () => setState(() => _attachment = null),
          ),
        ],
      ));
      sections.add(const SizedBox(height: 12));
    }
    if (_type == KnowledgeResourceType.project) {
      sections.add(_projectSection());
      sections.add(const SizedBox(height: 12));
    }
    sections.add(_SectionCard(
        title: 'Discoverability',
        icon: Icons.sell_outlined,
        children: [
          if (_supportsTechnologies) ...[
            TextFormField(
              controller: _technologiesController,
              enabled: !_saving,
              decoration: _decoration(
                'Technologies',
                hint: 'Flutter, Frappe, Python',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _tagsController,
            enabled: !_saving,
            decoration: _decoration('Tags', hint: 'training, mobile, process'),
          ),
          const SizedBox(height: 5),
          const Text('Separate values using commas.', style: TextStyle(color: _muted, fontSize: 9.5)),
        ],
      ));
    return sections;
  }

  bool get _supportsTechnologies =>
      _type == KnowledgeResourceType.courseLearning ||
      _type == KnowledgeResourceType.research ||
      _type == KnowledgeResourceType.importantNote ||
      _type == KnowledgeResourceType.project;

  Widget _projectSection() => _SectionCard(
        title: 'Project details',
        icon: Icons.rocket_launch_outlined,
        children: [
          TextFormField(
            controller: _projectDescriptionController,
            enabled: !_saving,
            minLines: 4,
            maxLines: 8,
            decoration: _decoration('Project description', hint: 'What was built and how it helps'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _githubController,
            enabled: !_saving,
            keyboardType: TextInputType.url,
            decoration: _decoration('GitHub URL', hint: 'https://github.com/...'),
            validator: (value) => _urlValidator(value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _documentationController,
            enabled: !_saving,
            keyboardType: TextInputType.url,
            decoration: _decoration('Documentation URL', hint: 'https://docs...'),
            validator: (value) => _urlValidator(value),
          ),
          const SizedBox(height: 12),
          _FilePickerTile(
            title: 'Project build',
            subtitle: _projectBuild?.name ?? _fileName(widget.resource?.projectBuild) ?? 'APK, ZIP or build package',
            icon: Icons.inventory_2_outlined,
            selected: _projectBuild != null || widget.resource?.projectBuild != null,
            onTap: _saving ? null : () => _pickFile(_FileField.projectBuild),
            onClear: _projectBuild == null ? null : () => setState(() => _projectBuild = null),
          ),
          const SizedBox(height: 9),
          _FilePickerTile(
            title: 'Project screenshots',
            subtitle: _projectScreenshots?.name ?? _fileName(widget.resource?.projectScreenshots) ?? 'Select screenshot image',
            icon: Icons.photo_library_outlined,
            selected: _projectScreenshots != null || widget.resource?.projectScreenshots != null,
            onTap: _saving ? null : () => _pickFile(_FileField.projectScreenshots),
            onClear: _projectScreenshots == null ? null : () => setState(() => _projectScreenshots = null),
          ),
          const SizedBox(height: 15),
          Row(children: [
            const Expanded(child: Text('Project team', style: TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w700))),
            TextButton.icon(onPressed: _saving ? null : _addMember, icon: const Icon(Icons.person_add_alt_1_rounded, size: 16), label: const Text('Add member')),
          ]),
          if (_members.isEmpty)
            const _TeamEmpty()
          else
            ..._members.asMap().entries.map((entry) => _MemberTile(
                  member: entry.value,
                  onRemove: _saving
                      ? null
                      : () => setState(() => _members.removeAt(entry.key)),
                )),
        ],
      );

  Widget _bottomActions() => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _save(_SaveMode.draft),
                  child: Text(_isEditing ? 'Save Changes' : 'Save Draft'),
                ),
              ),
              const SizedBox(width: 9),
              if (_isManager) ...[
                Expanded(
                  child: TextButton(
                    onPressed: _saving ? null : () => _save(_SaveMode.submit),
                    child: const Text('Submit Review'),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _save(_isManager
                          ? _SaveMode.publish
                          : _SaveMode.submit),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isManager
                              ? Icons.publish_rounded
                              : Icons.send_rounded,
                          size: 17,
                        ),
                  label: Text(_isManager ? 'Publish' : 'Submit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isManager
                        ? const Color(0xFF079455)
                        : _primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _urlValidator(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'URL is required.' : null;
    final uri = Uri.tryParse(text);
    return uri != null && uri.hasScheme &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty
        ? null
        : 'Enter a valid HTTP or HTTPS URL.';
  }
}

class _FormIntro extends StatelessWidget {
  final bool isEditing;
  const _FormIntro({required this.isEditing});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_darkBlue, _primary]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(11)), child: Icon(isEditing ? Icons.edit_note_rounded : Icons.lightbulb_outline_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEditing ? 'Improve this resource' : 'Share something useful', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(isEditing ? 'Keep company knowledge accurate and helpful.' : 'Your contribution will help the whole company grow.', style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ])),
        ]),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: _primary, size: 18), const SizedBox(width: 7), Text(title, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 14),
          ...children,
        ]),
      );
}

class _FilePickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  const _FilePickerTile({required this.title, required this.subtitle, required this.icon, required this.selected, this.onTap, this.onClear});
  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFFF0FDF4) : _background,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: selected ? const Color(0xFFD1FADF) : const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(9)), child: Icon(selected ? Icons.check_rounded : icon, color: selected ? const Color(0xFF079455) : _primary, size: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: _ink, fontSize: 11.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 9.5)),
              ])),
              if (onClear != null)
                IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded, size: 17), visualDensity: VisualDensity.compact)
              else
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3), size: 19),
            ]),
          ),
        ),
      );
}

class _MemberTile extends StatelessWidget {
  final KnowledgeResourceMemberModel member;
  final VoidCallback? onRemove;
  const _MemberTile({required this.member, this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 7),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(9)),
        child: Row(children: [
          CircleAvatar(radius: 15, backgroundColor: const Color(0xFFEAF1FF), child: Text(member.employeeName.isEmpty ? '?' : member.employeeName[0].toUpperCase(), style: const TextStyle(color: _darkBlue, fontSize: 10, fontWeight: FontWeight.w800))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(member.employeeName, style: const TextStyle(color: _ink, fontSize: 10.5, fontWeight: FontWeight.w700)), Text(member.role.isEmpty ? member.employee : member.role, style: const TextStyle(color: _muted, fontSize: 9))])),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Color(0xFFD92D20)), visualDensity: VisualDensity.compact),
        ]),
      );
}

class _TeamEmpty extends StatelessWidget {
  const _TeamEmpty();
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(9)), child: const Text('No team members added.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 9.5)));
}

class _UploadProgress extends StatelessWidget {
  final double value;
  const _UploadProgress({required this.value});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.cloud_upload_outlined, color: _primary, size: 16), const SizedBox(width: 7), const Expanded(child: Text('Uploading file...', style: TextStyle(color: _darkBlue, fontSize: 10.5, fontWeight: FontWeight.w700))), Text('${(value * 100).round()}%', style: const TextStyle(color: _darkBlue, fontSize: 10, fontWeight: FontWeight.w700))]),
    const SizedBox(height: 8),
    LinearProgressIndicator(value: value.clamp(0.0, 1.0).toDouble(), minHeight: 4, color: _primary, backgroundColor: Colors.white),
  ]));
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFECEC), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318), size: 17), const SizedBox(width: 7), Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB42318), fontSize: 10.5)))]));
}

class _EmployeeSearchSheet extends StatefulWidget {
  final KnowledgeEmployeeSearch search;
  const _EmployeeSearchSheet({required this.search});
  @override
  State<_EmployeeSearchSheet> createState() => _EmployeeSearchSheetState();
}

class _EmployeeSearchSheetState extends State<_EmployeeSearchSheet> {
  List<KnowledgeResourceMemberModel> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String value) async {
    if (value.trim().length < 2) return;
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await widget.search(value.trim());
      if (mounted) setState(() => _results = rows);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      height: MediaQuery.of(context).size.height * .62,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      child: Column(children: [
        Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFD0D5DD), borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 14),
        const Align(alignment: Alignment.centerLeft, child: Text('Select employee', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800))),
        const SizedBox(height: 10),
        TextField(autofocus: true, onChanged: _search, decoration: _decoration('Search employee', hint: 'Name or Employee ID').copyWith(prefixIcon: const Icon(Icons.search_rounded))),
        if (_loading) const LinearProgressIndicator(minHeight: 2, color: _primary),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFD92D20), fontSize: 10))),
        const SizedBox(height: 8),
        Expanded(child: _results.isEmpty
            ? const Center(child: Text('Type at least 2 characters to search.', style: TextStyle(color: _muted, fontSize: 11)))
            : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = _results[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(backgroundColor: const Color(0xFFEAF1FF), child: Text(member.employeeName.isEmpty ? '?' : member.employeeName[0], style: const TextStyle(color: _darkBlue, fontWeight: FontWeight.w700))),
                    title: Text(member.employeeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    subtitle: Text(member.employee, style: const TextStyle(fontSize: 10)),
                    onTap: () => _roleDialog(member),
                  );
                },
              )),
      ]),
    ),
  ));

  Future<void> _roleDialog(KnowledgeResourceMemberModel member) async {
    final role = TextEditingController(text: member.role);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.employeeName),
        content: TextField(controller: role, autofocus: true, decoration: const InputDecoration(labelText: 'Project role', hintText: 'Developer')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, role.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    role.dispose();
    if (result == null || !mounted) return;
    Navigator.pop(context, member.copyWith(role: result));
  }
}

InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 11.5),
      hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 10.5),
      filled: true,
      fillColor: const Color(0xFFFAFBFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.3)),
    );

String? _fileName(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.pathSegments.isEmpty) return value;
  return Uri.decodeComponent(uri.pathSegments.last);
}

String _plainText(String? value) => (value ?? '')
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .trim();

class _SelectedFile {
  final String path;
  final String name;
  const _SelectedFile({required this.path, required this.name});
}

enum _FileField { attachment, thumbnail, projectBuild, projectScreenshots }
enum _SaveMode { draft, submit, publish }
