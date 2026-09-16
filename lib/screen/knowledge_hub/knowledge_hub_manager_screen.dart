import 'package:flutter/material.dart';

import '../../model/knowledge_hub/knowledge_resource_model.dart';
import '../../model/knowledge_hub/knowledge_resource_type.dart';
import 'knowledge_hub_viewmodel.dart';
import 'knowledge_resource_detail_screen.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE5EAF1);

typedef KnowledgeManagerFormLauncher = Future<bool?> Function(
  BuildContext context,
  KnowledgeResourceModel? resource,
);

class KnowledgeHubManagerScreen extends StatefulWidget {
  final KnowledgeManagerFormLauncher? onOpenForm;

  const KnowledgeHubManagerScreen({super.key, this.onOpenForm});

  @override
  State<KnowledgeHubManagerScreen> createState() =>
      _KnowledgeHubManagerScreenState();
}

class _KnowledgeHubManagerScreenState extends State<KnowledgeHubManagerScreen> {
  final KnowledgeHubViewModel _viewModel = KnowledgeHubViewModel();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initialise();
  }

  Future<void> _initialise() async {
    await _viewModel.initialise();
    if (_viewModel.isKnowledgeManager) {
      await _viewModel.setStatus(KnowledgeResourceStatus.pendingReview);
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      _viewModel.loadResources(reset: false);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openResource(KnowledgeResourceModel resource) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => KnowledgeResourceDetailScreen(
          resourceName: resource.name,
          initialResource: resource,
          onOpenForm: widget.onOpenForm,
        ),
      ),
    );
    if (changed == true) await _viewModel.refresh();
  }

  Future<void> _openForm([KnowledgeResourceModel? resource]) async {
    if (widget.onOpenForm == null) {
      _message('Connect KnowledgeResourceFormScreen here.');
      return;
    }
    final changed = await widget.onOpenForm!(context, resource);
    if (changed == true) await _viewModel.refresh();
  }

  Future<void> _quickPublish(KnowledgeResourceModel resource) async {
    if (!await _confirm(
      title: 'Publish this resource?',
      message: 'It will become visible to every employee in the company.',
      action: 'Publish',
      color: const Color(0xFF079455),
    )) return;
    final actionModel = KnowledgeHubViewModel.detail(resourceName: resource.name);
    final success = await actionModel.publishDetail();
    final error = actionModel.error;
    actionModel.dispose();
    if (success) {
      _message('Resource published successfully.');
      await _viewModel.refresh();
    } else {
      _message(error ?? 'Unable to publish resource.');
    }
  }

  Future<void> _quickReject(KnowledgeResourceModel resource) async {
    if (!await _confirm(
      title: 'Reject this submission?',
      message: 'The employee can improve it and submit it again.',
      action: 'Reject',
      color: const Color(0xFFD92D20),
    )) return;
    final actionModel = KnowledgeHubViewModel.detail(resourceName: resource.name);
    final success = await actionModel.rejectDetail();
    final error = actionModel.error;
    actionModel.dispose();
    if (success) {
      _message('Resource rejected.');
      await _viewModel.refresh();
    } else {
      _message(error ?? 'Unable to reject resource.');
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    required Color color,
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
                  const SizedBox(height: 17),
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
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(backgroundColor: color),
                          child: Text(action),
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

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
          titleSpacing: 0,
          title: const Text(
            'Manage Knowledge',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Add Knowledge',
              onPressed: _viewModel.initialLoading ? null : _openForm,
              icon: const Icon(Icons.add_rounded),
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
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_viewModel.initialLoading) return const _ManagerSkeleton();
    if (_viewModel.access == null) {
      return _ManagerError(
        message: _viewModel.error ?? 'Unable to load manager resources.',
        onRetry: _initialise,
      );
    }
    if (!_viewModel.isKnowledgeManager) {
      return const _AccessDenied();
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ManagerBanner(company: _viewModel.access!.company),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _viewModel.searchResources,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: _ink, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search submissions...',
                    hintStyle: const TextStyle(color: _muted, fontSize: 11),
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _viewModel.searchResources('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded, size: 17),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _StatusTabs(viewModel: _viewModel),
                if (_viewModel.error != null) ...[
                  const SizedBox(height: 9),
                  _ManagerInlineError(message: _viewModel.error!),
                ],
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _titleForStatus(_viewModel.selectedStatus),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_viewModel.total} items',
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ]),
            ),
          ),
          if (_viewModel.contentLoading)
            const SliverFillRemaining(child: _ManagerListSkeleton())
          else if (_viewModel.resources.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _ManagerEmpty(status: _viewModel.selectedStatus),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final resource = _viewModel.resources[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewCard(
                        resource: resource,
                        onOpen: () => _openResource(resource),
                        onEdit: resource.canEdit ? () => _openForm(resource) : null,
                        onPublish: resource.canPublish
                            ? () => _quickPublish(resource)
                            : null,
                        onReject: resource.canReject
                            ? () => _quickReject(resource)
                            : null,
                      ),
                    );
                  },
                  childCount: _viewModel.resources.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 30),
              child: _viewModel.loadingMore
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      ),
                    )
                  : _viewModel.hasMore
                      ? Center(
                          child: TextButton(
                            onPressed: () =>
                                _viewModel.loadResources(reset: false),
                            child: const Text('Load more'),
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerBanner extends StatelessWidget {
  final String company;
  const _ManagerBanner({required this.company});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_darkBlue, _primary]),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review & publish',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Keep $company knowledge useful and accurate.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatusTabs extends StatelessWidget {
  final KnowledgeHubViewModel viewModel;
  const _StatusTabs({required this.viewModel});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 35,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _StatusTab(
              label: 'All',
              selected: viewModel.selectedStatus == null,
              color: _primary,
              onTap: () => viewModel.setStatus(null),
            ),
            for (final status in [
              KnowledgeResourceStatus.pendingReview,
              KnowledgeResourceStatus.published,
              KnowledgeResourceStatus.draft,
              KnowledgeResourceStatus.rejected,
            ])
              _StatusTab(
                label: status.apiValue,
                selected: viewModel.selectedStatus == status,
                color: _statusColor(status),
                onTap: () => viewModel.setStatus(status),
              ),
          ],
        ),
      );
}

class _StatusTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: Material(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: selected ? color : _border),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
}

class _ReviewCard extends StatelessWidget {
  final KnowledgeResourceModel resource;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onReject;
  const _ReviewCard({
    required this.resource,
    required this.onOpen,
    this.onEdit,
    this.onPublish,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(resource.status);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: _typeColor(resource.resourceType).withOpacity(.09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    _typeIcon(resource.resourceType),
                    color: _typeColor(resource.resourceType),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.resourceTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        resource.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.09),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    resource.status.apiValue,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(_typeIcon(resource.resourceType), size: 13, color: _muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${resource.resourceType.apiValue} • ${resource.createdBy}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 9.5),
                  ),
                ),
              if (onReject != null)
                TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD92D20),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 9.5),
                  ),
                  child: const Text('Reject'),
                ),
              if (onPublish != null)
                FilledButton(
                  onPressed: onPublish,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF079455),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Publish'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_outlined, color: _muted, size: 46),
              SizedBox(height: 12),
              Text(
                'Manager access required',
                style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 5),
              Text(
                'Only users with the Mobile Knowledge Manager role can open this screen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      );
}

class _ManagerEmpty extends StatelessWidget {
  final KnowledgeResourceStatus? status;
  const _ManagerEmpty({required this.status});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 70),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF1FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inbox_outlined, color: _primary, size: 34),
              ),
              const SizedBox(height: 12),
              Text(
                status == KnowledgeResourceStatus.pendingReview
                    ? 'All caught up'
                    : 'No resources found',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status == KnowledgeResourceStatus.pendingReview
                    ? 'There are no resources waiting for review.'
                    : 'Nothing matches the selected status and search.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 10.5),
              ),
            ],
          ),
        ),
      );
}

class _ManagerInlineError extends StatelessWidget {
  final String message;
  const _ManagerInlineError({required this.message});
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

class _ManagerError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ManagerError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: _muted, size: 44),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 11.5),
              ),
              const SizedBox(height: 13),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: _primary),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

class _ManagerSkeleton extends StatelessWidget {
  const _ManagerSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _skeleton(82),
          const SizedBox(height: 12),
          _skeleton(44),
          const SizedBox(height: 10),
          _skeleton(35),
          const SizedBox(height: 18),
          _skeleton(132),
          const SizedBox(height: 10),
          _skeleton(132),
        ],
      );
}

class _ManagerListSkeleton extends StatelessWidget {
  const _ManagerListSkeleton();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _skeleton(132),
            const SizedBox(height: 10),
            _skeleton(132),
          ],
        ),
      );
}

Widget _skeleton(double height) => Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5EAF1),
        borderRadius: BorderRadius.circular(14),
      ),
    );

String _titleForStatus(KnowledgeResourceStatus? status) {
  if (status == null) return 'All company resources';
  if (status == KnowledgeResourceStatus.pendingReview) return 'Waiting for review';
  return status.apiValue;
}

Color _statusColor(KnowledgeResourceStatus status) {
  switch (status) {
    case KnowledgeResourceStatus.draft:
      return const Color(0xFF667085);
    case KnowledgeResourceStatus.pendingReview:
      return const Color(0xFFF79009);
    case KnowledgeResourceStatus.published:
      return const Color(0xFF079455);
    case KnowledgeResourceStatus.rejected:
      return const Color(0xFFD92D20);
  }
}

IconData _typeIcon(KnowledgeResourceType type) {
  switch (type) {
    case KnowledgeResourceType.usefulLink:
      return Icons.link_rounded;
    case KnowledgeResourceType.courseLearning:
      return Icons.school_rounded;
    case KnowledgeResourceType.document:
      return Icons.description_rounded;
    case KnowledgeResourceType.research:
      return Icons.science_rounded;
    case KnowledgeResourceType.importantNote:
      return Icons.lightbulb_rounded;
    case KnowledgeResourceType.project:
      return Icons.rocket_launch_rounded;
    case KnowledgeResourceType.companyResource:
      return Icons.business_center_rounded;
  }
}

Color _typeColor(KnowledgeResourceType type) {
  switch (type) {
    case KnowledgeResourceType.usefulLink:
      return const Color(0xFF175CD3);
    case KnowledgeResourceType.courseLearning:
      return const Color(0xFF7A5AF8);
    case KnowledgeResourceType.document:
      return const Color(0xFF344054);
    case KnowledgeResourceType.research:
      return const Color(0xFF0086C9);
    case KnowledgeResourceType.importantNote:
      return const Color(0xFFF79009);
    case KnowledgeResourceType.project:
      return const Color(0xFF079455);
    case KnowledgeResourceType.companyResource:
      return const Color(0xFF6941C6);
  }
}
