import 'package:flutter/material.dart';

import '../../model/knowledge_hub/knowledge_resource_model.dart';
import '../../model/knowledge_hub/knowledge_resource_type.dart';
import '../../services/api_endpoints.dart';
import 'knowledge_hub_viewmodel.dart';
import 'knowledge_resource_detail_screen.dart';
import 'knowledge_resource_form_screen.dart';

const _primary = Color(0xFF1B5FE0);
const _darkBlue = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE5EAF1);

typedef KnowledgeFormLauncher = Future<bool?> Function(
  BuildContext context,
  KnowledgeResourceModel? resource,
);

class KnowledgeHubScreen extends StatefulWidget {
  /// Connect this callback to KnowledgeResourceFormScreen when that screen is
  /// added. Return true after a successful create/update to refresh this page.
  final KnowledgeFormLauncher? onOpenForm;

  const KnowledgeHubScreen({super.key, this.onOpenForm});

  @override
  State<KnowledgeHubScreen> createState() => _KnowledgeHubScreenState();
}

class _KnowledgeHubScreenState extends State<KnowledgeHubScreen> {
  final KnowledgeHubViewModel _viewModel = KnowledgeHubViewModel();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _viewModel.initialise();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 320) {
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

  Future<void> _openForm([KnowledgeResourceModel? resource]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => KnowledgeResourceFormScreen(
          resource: resource,
        ),
      ),
    );

    if (changed == true) {
      await _viewModel.refresh();
    }
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
            'Knowledge Hub',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _viewModel.refreshing ? null : _viewModel.refresh,
              icon: _viewModel.refreshing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: _viewModel.access == null
            ? null
            : FloatingActionButton.extended(
                onPressed: _viewModel.actionLoading ? null : _openForm,
                elevation: 4,
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded, size: 21),
                label: const Text(
                  'Add Knowledge',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_viewModel.initialLoading) {
      return const _KnowledgeSkeleton();
    }
    if (_viewModel.access == null) {
      return _ErrorState(
        message: _viewModel.error ?? 'Unable to load the Knowledge Hub.',
        onRetry: _viewModel.initialise,
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _HubBanner(
                  company: _viewModel.access!.company,
                  isManager: _viewModel.isKnowledgeManager,
                ),
                const SizedBox(height: 12),
                _SearchBox(
                  controller: _searchController,
                  onChanged: _viewModel.searchResources,
                  onClear: () {
                    _searchController.clear();
                    _viewModel.searchResources('');
                  },
                ),
                const SizedBox(height: 10),
                _TypeFilters(viewModel: _viewModel),
                const SizedBox(height: 10),
                _QuickFilters(viewModel: _viewModel),
                if (_viewModel.error != null) ...[
                  const SizedBox(height: 10),
                  _InlineError(message: _viewModel.error!),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _sectionTitle(),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_viewModel.total} resources',
                      style: const TextStyle(color: _muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ]),
            ),
          ),
          if (_viewModel.contentLoading)
            const SliverFillRemaining(child: _ResourceListSkeleton())
          else if (_viewModel.resources.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                filtered: _hasFilters,
                onClear: _viewModel.clearFilters,
                onAdd: _openForm,
              ),
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
                      child: _ResourceCard(
                        resource: resource,
                        onTap: () => _openResource(resource),
                      ),
                    );
                  },
                  childCount: _viewModel.resources.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 92),
              child: _viewModel.loadingMore
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 22,
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

  bool get _hasFilters =>
      _viewModel.selectedType != null ||
      _viewModel.selectedStatus != null ||
      _viewModel.mineOnly ||
      _searchController.text.trim().isNotEmpty;

  String _sectionTitle() {
    if (_viewModel.mineOnly) return 'My contributions';
    if (_viewModel.selectedStatus == KnowledgeResourceStatus.pendingReview) {
      return 'Pending review';
    }
    return _viewModel.selectedType?.shortLabel ?? 'Company knowledge';
  }
}

class _HubBanner extends StatelessWidget {
  final String company;
  final bool isManager;
  const _HubBanner({required this.company, required this.isManager});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_darkBlue, _primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30123FA0),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learn. Share. Grow.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$company knowledge library',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isManager)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MANAGER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
              ),
          ],
        ),
      );
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBox({
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
          style: const TextStyle(color: _ink, fontSize: 12.5),
          decoration: InputDecoration(
            hintText: 'Search knowledge, tags, technologies...',
            hintStyle: const TextStyle(color: _muted, fontSize: 11.5),
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

class _TypeFilters extends StatelessWidget {
  final KnowledgeHubViewModel viewModel;
  const _TypeFilters({required this.viewModel});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _FilterChip(
              label: 'All',
              icon: Icons.grid_view_rounded,
              selected: viewModel.selectedType == null,
              onTap: () => viewModel.setType(null),
            ),
            for (final type in KnowledgeResourceType.values)
              _FilterChip(
                label: type.shortLabel,
                icon: knowledgeTypeIcon(type),
                selected: viewModel.selectedType == type,
                onTap: () => viewModel.setType(type),
              ),
          ],
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: Material(
          color: selected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? _primary : _border),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: selected ? Colors.white : _muted),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : _ink,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _QuickFilters extends StatelessWidget {
  final KnowledgeHubViewModel viewModel;
  const _QuickFilters({required this.viewModel});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _SmallToggle(
            label: 'My Resources',
            icon: Icons.person_outline_rounded,
            active: viewModel.mineOnly,
            onTap: () => viewModel.setMineOnly(!viewModel.mineOnly),
          ),
          if (viewModel.isKnowledgeManager) ...[
            const SizedBox(width: 7),
            _SmallToggle(
              label: 'Pending Review',
              icon: Icons.pending_actions_rounded,
              active: viewModel.selectedStatus ==
                  KnowledgeResourceStatus.pendingReview,
              onTap: () => viewModel.setStatus(
                viewModel.selectedStatus == KnowledgeResourceStatus.pendingReview
                    ? null
                    : KnowledgeResourceStatus.pendingReview,
              ),
            ),
            const Spacer(),
            PopupMenuButton<KnowledgeResourceStatus?>(
              tooltip: 'Filter by status',
              onSelected: viewModel.setStatus,
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('All statuses')),
                for (final status in KnowledgeResourceStatus.values)
                  PopupMenuItem(
                    value: status,
                    child: Text(status.apiValue),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: viewModel.selectedStatus == null
                      ? Colors.white
                      : const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _border),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 17,
                  color: viewModel.selectedStatus == null ? _muted : _primary,
                ),
              ),
            ),
          ],
        ],
      );
}

class _SmallToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SmallToggle({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: active ? const Color(0xFFEAF1FF) : Colors.white,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: active ? const Color(0xFFB8D0FF) : _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: active ? _primary : _muted),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? _darkBlue : _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ResourceCard extends StatelessWidget {
  final KnowledgeResourceModel resource;
  final VoidCallback onTap;
  const _ResourceCard({required this.resource, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = knowledgeTypeColor(resource.resourceType);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResourceVisual(resource: resource, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resource.resourceTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(status: resource.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(.09),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            resource.resourceType.apiValue,
                            style: TextStyle(
                              color: color,
                              fontSize: 8.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (resource.isOwner) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.person_rounded, size: 12, color: _muted),
                          const SizedBox(width: 2),
                          const Text(
                            'Yours',
                            style: TextStyle(color: _muted, fontSize: 9),
                          ),
                        ],
                        const Spacer(),
                        if (resource.hasAttachment)
                          const Icon(
                            Icons.attach_file_rounded,
                            color: _muted,
                            size: 15,
                          ),
                        if (resource.hasUrl)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.link_rounded,
                              color: _muted,
                              size: 15,
                            ),
                          ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF98A2B3),
                          size: 19,
                        ),
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

class _ResourceVisual extends StatelessWidget {
  final KnowledgeResourceModel resource;
  final Color color;
  const _ResourceVisual({required this.resource, required this.color});

  @override
  Widget build(BuildContext context) {
    final thumbnail = resource.thumbnail;
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 66,
        height: 76,
        color: color.withOpacity(.09),
        child: thumbnail == null
            ? Icon(knowledgeTypeIcon(resource.resourceType), color: color, size: 28)
            : Image.network(
                absoluteKnowledgeUrl(thumbnail),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  knowledgeTypeIcon(resource.resourceType),
                  color: color,
                  size: 28,
                ),
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final KnowledgeResourceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = knowledgeStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.apiValue,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool filtered;
  final Future<void> Function() onClear;
  final VoidCallback onAdd;
  const _EmptyState({
    required this.filtered,
    required this.onClear,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 110),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF1FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                filtered ? 'No matching resources' : 'Start sharing knowledge',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                filtered
                    ? 'Try changing the search or filters.'
                    : 'Add a useful link, document, course, note or project.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: filtered ? onClear : onAdd,
                child: Text(filtered ? 'Clear filters' : 'Add Knowledge'),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318), size: 16),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFFB42318), fontSize: 10.5),
              ),
            ),
          ],
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
              const Icon(Icons.cloud_off_rounded, color: _muted, size: 44),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
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

class _KnowledgeSkeleton extends StatelessWidget {
  const _KnowledgeSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Skeleton(height: 82, radius: 18),
          SizedBox(height: 12),
          _Skeleton(height: 46),
          SizedBox(height: 12),
          _Skeleton(height: 35),
          SizedBox(height: 20),
          _Skeleton(height: 102),
          SizedBox(height: 10),
          _Skeleton(height: 102),
          SizedBox(height: 10),
          _Skeleton(height: 102),
        ],
      );
}

class _ResourceListSkeleton extends StatelessWidget {
  const _ResourceListSkeleton();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _Skeleton(height: 102),
            SizedBox(height: 10),
            _Skeleton(height: 102),
            SizedBox(height: 10),
            _Skeleton(height: 102),
          ],
        ),
      );
}

class _Skeleton extends StatelessWidget {
  final double height;
  final double radius;
  const _Skeleton({required this.height, this.radius = 14});
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF2),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

IconData knowledgeTypeIcon(KnowledgeResourceType type) {
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

Color knowledgeTypeColor(KnowledgeResourceType type) {
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

Color knowledgeStatusColor(KnowledgeResourceStatus status) {
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

String absoluteKnowledgeUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) return value;
  return Uri.parse(ApiEndpoints.baseUrl).resolve(value).toString();
}
