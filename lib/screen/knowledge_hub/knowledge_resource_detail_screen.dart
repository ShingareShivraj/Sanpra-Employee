import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';

import '../../model/knowledge_hub/knowledge_resource_model.dart';
import '../../model/knowledge_hub/knowledge_resource_type.dart';
import '../../services/api_endpoints.dart';
import 'knowledge_hub_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE5EAF1);

typedef KnowledgeDetailFormLauncher = Future<bool?> Function(
  BuildContext context,
  KnowledgeResourceModel? resource,
);

class KnowledgeResourceDetailScreen extends StatefulWidget {
  final String resourceName;
  final KnowledgeResourceModel? initialResource;
  final KnowledgeDetailFormLauncher? onOpenForm;

  const KnowledgeResourceDetailScreen({
    super.key,
    required this.resourceName,
    this.initialResource,
    this.onOpenForm,
  });

  @override
  State<KnowledgeResourceDetailScreen> createState() =>
      _KnowledgeResourceDetailScreenState();
}

class _KnowledgeResourceDetailScreenState
    extends State<KnowledgeResourceDetailScreen> {
  late final KnowledgeHubViewModel _viewModel;
  final ApiService _apiService = ApiService();
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _viewModel = KnowledgeHubViewModel.detail(
      resourceName: widget.resourceName,
    )..initialiseDetail();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String? value) async {
    if (value == null || value.trim().isEmpty) return;
    final uri = Uri.tryParse(_absoluteUrl(value));
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this resource.')),
      );
    }
  }

  Future<void> _downloadFile(String? value) async {
    if (value == null || value.trim().isEmpty) return;

    try {
      final fileName = _fileName(value);

      final directory = await getApplicationDocumentsDirectory();

      final savePath = '${directory.path}/$fileName';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $fileName...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _apiService.download(
        url: value.trim(),
        savePath: savePath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded $fileName'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _edit(KnowledgeResourceModel resource) async {
    if (widget.onOpenForm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect KnowledgeResourceFormScreen here.')),
      );
      return;
    }
    final updated = await widget.onOpenForm!(context, resource);
    if (updated == true) {
      _changed = true;
      await _viewModel.refresh();
    }
  }

  Future<void> _publish() async {
    final accepted = await _confirm(
      title: 'Publish resource?',
      message: 'Everyone in the company will be able to view this resource.',
      actionLabel: 'Publish',
      icon: Icons.publish_rounded,
      actionColor: const Color(0xFF079455),
    );
    if (!accepted) return;
    final success = await _viewModel.publishDetail();
    if (success) {
      _changed = true;
      _showMessage('Resource published successfully.');
    }
  }

  Future<void> _reject() async {
    final accepted = await _confirm(
      title: 'Reject submission?',
      message: 'The creator can edit the resource and submit it again.',
      actionLabel: 'Reject',
      icon: Icons.cancel_outlined,
      actionColor: const Color(0xFFD92D20),
    );
    if (!accepted) return;
    final success = await _viewModel.rejectDetail();
    if (success) {
      _changed = true;
      _showMessage('Resource rejected.');
    }
  }

  Future<void> _submitForReview() async {
    final success = await _viewModel.submitDetailForReview();
    if (success) {
      _changed = true;
      _showMessage('Resource submitted for review.');
    }
  }

  Future<void> _delete() async {
    final accepted = await _confirm(
      title: 'Delete resource?',
      message: 'This action permanently removes the resource from the company hub.',
      actionLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      actionColor: const Color(0xFFD92D20),
    );
    if (!accepted) return;
    final success = await _viewModel.deleteDetail();
    if (success && mounted) Navigator.pop(context, true);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
    required IconData icon,
    required Color actionColor,
  }) async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(.09),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: actionColor, size: 25),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, fontSize: 11.5),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(backgroundColor: actionColor),
                          child: Text(actionLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final resource = _viewModel.detail ?? widget.initialResource;
        return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, _changed);
            return false;
          },
          child: Scaffold(
            backgroundColor: _background,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              foregroundColor: _ink,
              titleSpacing: 0,
              title: const Text(
                'Resource details',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              actions: [
                if (resource?.canEdit == true)
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: _viewModel.actionLoading
                        ? null
                        : () => _edit(resource!),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                if (resource?.canDelete == true)
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
                            SizedBox(width: 9),
                            Text('Delete resource'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: _body(resource),
            bottomNavigationBar: resource == null ? null : _actions(resource),
          ),
        );
      },
    );
  }

  Widget _body(KnowledgeResourceModel? resource) {
    if (resource == null && _viewModel.detailLoading) {
      return const _DetailSkeleton();
    }
    if (resource == null) {
      return _DetailError(
        message: _viewModel.error ?? 'Unable to load this resource.',
        onRetry: _viewModel.initialiseDetail,
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _ResourceHero(resource: resource),
          if (_viewModel.detailLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2, color: _primary),
          ],
          if (_viewModel.error != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: _viewModel.error!),
          ],
          const SizedBox(height: 12),
          _DescriptionCard(resource: resource),
          if (_hasPrimaryLinks(resource)) ...[
            const SizedBox(height: 12),
            const _SectionHeading('Open resource'),
            const SizedBox(height: 8),
            _ResourceLinks(
              resource: resource,
              onOpen: _openUrl,
              onDownload: _downloadFile,
            ),
          ],
          if (resource.isProject) ...[
            const SizedBox(height: 12),
            _ProjectSection(resource: resource, onOpen: _openUrl),
          ],
          if (resource.tagList.isNotEmpty || resource.technologyList.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TagsSection(resource: resource),
          ],
          if (resource.teamMembers.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionHeading('Project team'),
            const SizedBox(height: 8),
            _TeamCard(resource: resource),
          ],
          const SizedBox(height: 12),
          _MetadataCard(resource: resource),
          if (_viewModel.actionLoading) ...[
            const SizedBox(height: 14),
            const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _actions(KnowledgeResourceModel resource) {
    final canSubmit = resource.isOwner &&
        (resource.status == KnowledgeResourceStatus.draft ||
            resource.status == KnowledgeResourceStatus.rejected);
    if (!resource.canPublish && !resource.canReject && !canSubmit) return null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            if (resource.canReject) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _viewModel.actionLoading ? null : _reject,
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD92D20),
                    side: const BorderSide(color: Color(0xFFFDA29B)),
                  ),
                ),
              ),
              const SizedBox(width: 9),
            ],
            if (resource.canPublish)
              Expanded(
                flex: resource.canReject ? 1 : 2,
                child: FilledButton.icon(
                  onPressed: _viewModel.actionLoading ? null : _publish,
                  icon: const Icon(Icons.publish_rounded, size: 17),
                  label: const Text('Publish'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF079455),
                  ),
                ),
              ),
            if (canSubmit)
              Expanded(
                child: FilledButton.icon(
                  onPressed: _viewModel.actionLoading ? null : _submitForReview,
                  icon: const Icon(Icons.send_rounded, size: 17),
                  label: const Text('Submit for Review'),
                  style: FilledButton.styleFrom(backgroundColor: _primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasPrimaryLinks(KnowledgeResourceModel resource) =>
      resource.hasUrl ||
      resource.hasAttachment ||
      resource.githubUrl?.isNotEmpty == true ||
      resource.documentationUrl?.isNotEmpty == true;
}

class _ResourceHero extends StatelessWidget {
  final KnowledgeResourceModel resource;
  const _ResourceHero({required this.resource});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(resource.resourceType);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(.96), color.withOpacity(.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: color.withOpacity(.22), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_typeIcon(resource.resourceType), color: Colors.white, size: 22),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  resource.resourceType.apiValue,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              _HeroStatus(status: resource.status),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            resource.resourceTitle,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.business_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(resource.company, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
              ),
              if (resource.isOwner)
                const Text('Your contribution', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatus extends StatelessWidget {
  final KnowledgeResourceStatus status;
  const _HeroStatus({required this.status});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(20)),
        child: Text(status.apiValue.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: .3)),
      );
}

class _DescriptionCard extends StatelessWidget {
  final KnowledgeResourceModel resource;
  const _DescriptionCard({required this.resource});
  @override
  Widget build(BuildContext context) => _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionHeading('About this resource'),
          const SizedBox(height: 8),
          Text(resource.description, style: const TextStyle(color: _ink, fontSize: 12, height: 1.55)),
        ]),
      );
}

class _ResourceLinks extends StatelessWidget {
  final KnowledgeResourceModel resource;
  final ValueChanged<String?> onOpen;
  final ValueChanged<String?> onDownload;

  const _ResourceLinks({
    required this.resource,
    required this.onOpen,
    required this.onDownload,
  });
  @override
  Widget build(BuildContext context) => _Card(
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          if (resource.hasUrl) _LinkRow(icon: Icons.open_in_new_rounded, title: 'Open resource', subtitle: resource.url!, onTap: () => onOpen(resource.url)),
          if (resource.hasAttachment)
            _LinkRow(
              icon: Icons.download_rounded,
              title: 'Download attachment',
              subtitle: _fileName(resource.attachment!),
              onTap: () => onDownload(resource.attachment),
            ),
          if (resource.githubUrl?.isNotEmpty == true) _LinkRow(icon: Icons.code_rounded, title: 'View source code', subtitle: 'GitHub repository', onTap: () => onOpen(resource.githubUrl)),
          if (resource.documentationUrl?.isNotEmpty == true) _LinkRow(icon: Icons.menu_book_rounded, title: 'Documentation', subtitle: 'Open project documentation', onTap: () => onOpen(resource.documentationUrl)),
        ]),
      );
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkRow({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: _primary, size: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: _ink, fontSize: 11.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 9.5)),
              ])),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3), size: 19),
            ]),
          ),
        ),
      );
}

class _ProjectSection extends StatelessWidget {
  final KnowledgeResourceModel resource;
  final ValueChanged<String?> onOpen;
  const _ProjectSection({required this.resource, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final description = _plainText(resource.projectDescription);
    if (description.isEmpty && !resource.hasProjectBuild && !resource.hasProjectScreenshots) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionHeading('Project overview'),
      const SizedBox(height: 8),
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (description.isNotEmpty) Text(description, style: const TextStyle(color: _ink, fontSize: 12, height: 1.5)),
        if (description.isNotEmpty && (resource.hasProjectBuild || resource.hasProjectScreenshots)) const SizedBox(height: 11),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (resource.hasProjectBuild) _ProjectButton(icon: Icons.inventory_2_outlined, label: 'Project Build', onTap: () => onOpen(resource.projectBuild)),
          if (resource.hasProjectScreenshots) _ProjectButton(icon: Icons.photo_library_outlined, label: 'Screenshots', onTap: () => onOpen(resource.projectScreenshots)),
        ]),
      ])),
    ]);
  }
}

class _ProjectButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProjectButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 16), label: Text(label), style: OutlinedButton.styleFrom(foregroundColor: _darkBlue, textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)));
}

class _TagsSection extends StatelessWidget {
  final KnowledgeResourceModel resource;
  const _TagsSection({required this.resource});
  @override
  Widget build(BuildContext context) => _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (resource.technologyList.isNotEmpty) ...[
      const _SectionHeading('Technologies'),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: resource.technologyList.map((value) => _Pill(label: value, color: _primary)).toList()),
    ],
    if (resource.technologyList.isNotEmpty && resource.tagList.isNotEmpty) const SizedBox(height: 13),
    if (resource.tagList.isNotEmpty) ...[
      const _SectionHeading('Tags'),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: resource.tagList.map((value) => _Pill(label: '#$value', color: _muted)).toList()),
    ],
  ]));
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(7)), child: Text(label, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w600)));
}

class _TeamCard extends StatelessWidget {
  final KnowledgeResourceModel resource;
  const _TeamCard({required this.resource});
  @override
  Widget build(BuildContext context) => _Card(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        child: Column(
          children: resource.teamMembers.map((member) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              CircleAvatar(radius: 17, backgroundColor: const Color(0xFFEAF1FF), child: Text(member.employeeName.isEmpty ? '?' : member.employeeName[0].toUpperCase(), style: const TextStyle(color: _darkBlue, fontSize: 11, fontWeight: FontWeight.w800))),
              const SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(member.employeeName, style: const TextStyle(color: _ink, fontSize: 11.5, fontWeight: FontWeight.w700)),
                if (member.role.isNotEmpty) Text(member.role, style: const TextStyle(color: _muted, fontSize: 9.5)),
              ])),
            ]),
          )).toList(),
        ),
      );
}

class _MetadataCard extends StatelessWidget {
  final KnowledgeResourceModel resource;
  const _MetadataCard({required this.resource});
  @override
  Widget build(BuildContext context) => _Card(child: Column(children: [
    _MetaRow(label: 'Resource ID', value: resource.name),
    _MetaRow(label: 'Created by', value: resource.createdBy),
    if (resource.creation != null) _MetaRow(label: 'Created on', value: _formatDate(resource.creation!)),
    if (resource.publishedBy != null) _MetaRow(label: 'Published by', value: resource.publishedBy!),
    if (resource.publishedOn != null) _MetaRow(label: 'Published on', value: _formatDate(resource.publishedOn!)),
  ]));
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(color: _muted, fontSize: 10))),
      Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: _ink, fontSize: 10.5, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w800));
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(14)});
  @override
  Widget build(BuildContext context) => Container(padding: padding, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)), child: child);
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFECEC), borderRadius: BorderRadius.circular(10)), child: Text(message, style: const TextStyle(color: Color(0xFFB42318), fontSize: 10.5)));
}

class _DetailError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _DetailError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off_rounded, color: _muted, size: 44),
    const SizedBox(height: 12),
    Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 12)),
    const SizedBox(height: 14),
    FilledButton(onPressed: onRetry, style: FilledButton.styleFrom(backgroundColor: _primary), child: const Text('Try again')),
  ])));
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(height: 155, decoration: BoxDecoration(color: const Color(0xFFE5EAF1), borderRadius: BorderRadius.circular(18))),
    const SizedBox(height: 12),
    Container(height: 120, decoration: BoxDecoration(color: const Color(0xFFE5EAF1), borderRadius: BorderRadius.circular(14))),
    const SizedBox(height: 12),
    Container(height: 150, decoration: BoxDecoration(color: const Color(0xFFE5EAF1), borderRadius: BorderRadius.circular(14))),
  ]);
}

IconData _typeIcon(KnowledgeResourceType type) {
  switch (type) {
    case KnowledgeResourceType.usefulLink: return Icons.link_rounded;
    case KnowledgeResourceType.courseLearning: return Icons.school_rounded;
    case KnowledgeResourceType.document: return Icons.description_rounded;
    case KnowledgeResourceType.research: return Icons.science_rounded;
    case KnowledgeResourceType.importantNote: return Icons.lightbulb_rounded;
    case KnowledgeResourceType.project: return Icons.rocket_launch_rounded;
    case KnowledgeResourceType.companyResource: return Icons.business_center_rounded;
  }
}

Color _typeColor(KnowledgeResourceType type) {
  switch (type) {
    case KnowledgeResourceType.usefulLink: return const Color(0xFF175CD3);
    case KnowledgeResourceType.courseLearning: return const Color(0xFF7A5AF8);
    case KnowledgeResourceType.document: return const Color(0xFF344054);
    case KnowledgeResourceType.research: return const Color(0xFF0086C9);
    case KnowledgeResourceType.importantNote: return const Color(0xFFF79009);
    case KnowledgeResourceType.project: return const Color(0xFF079455);
    case KnowledgeResourceType.companyResource: return const Color(0xFF6941C6);
  }
}

String _absoluteUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) return value;
  return Uri.parse(ApiEndpoints.baseUrl).resolve(value).toString();
}

String _fileName(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.pathSegments.isEmpty) return 'Attachment';
  return Uri.decodeComponent(uri.pathSegments.last);
}

String _plainText(String? value) => (value ?? '')
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .trim();

String _formatDate(DateTime value) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final local = value.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
