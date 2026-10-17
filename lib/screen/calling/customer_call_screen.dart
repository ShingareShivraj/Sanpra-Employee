import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import '../../model/customer_call_model.dart';
import 'android_call_log_adapter.dart';
import 'customer_call_viewmodel.dart';
import 'customer_search_screen.dart';

const _blue = Color(0xFF1B5FE0);
const _navy = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF182230);
const _muted = Color(0xFF667085);
const _border = Color(0xFFEAECF0);

typedef CustomerCallLogLoader = Future<List<DeviceCallLogEntry>> Function();
typedef CustomerRecordingPicker = Future<CustomerRecordingFile?> Function();

class CustomerRecordingFile {
  const CustomerRecordingFile({required this.path, this.name});
  final String path;
  final String? name;
}

class CustomerCallScreen extends StatefulWidget {
  const CustomerCallScreen({
    super.key,
    this.viewModel,
    this.callLogLoader,
    this.recordingPicker,
  });

  /// Pass the Android permission/call-log adapter here. The UI never reads the
  /// system call log directly.
  final CustomerCallLogLoader? callLogLoader;

  /// Pass a Storage Access Framework/file-picker adapter here. The selected
  /// audio file is uploaded privately by the existing service.
  final CustomerRecordingPicker? recordingPicker;
  final CustomerCallViewModel? viewModel;

  @override
  State<CustomerCallScreen> createState() => _CustomerCallScreenState();
}

class _CustomerCallScreenState extends State<CustomerCallScreen> {
  late final CustomerCallViewModel _viewModel;
  late final bool _ownsViewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? CustomerCallViewModel();
    _scrollController.addListener(_onScroll);
    _viewModel.initialise();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 280) {
      _viewModel.loadMoreHistory();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
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
            'Customer Calls',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Customers',
              onPressed: _openCustomers,
              icon: const Icon(Icons.people_alt_outlined),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _viewModel.refreshing ? null : _viewModel.refresh,
              icon: _viewModel.refreshing
                  ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _blue,
                ),
              )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(child: _body()),
        floatingActionButton: _viewModel.hasAccess
            ? FloatingActionButton.extended(
          onPressed: _viewModel.syncing ? null : _syncCalls,
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 5,
          icon: _viewModel.syncing
              ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.sync_rounded, size: 20),
          label: Text(
            _viewModel.syncing ? 'Syncing' : 'Sync Calls',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
            : null,
      ),
    );
  }

  Widget _body() {
    if (_viewModel.initialLoading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }

    if (_viewModel.error != null && _viewModel.access == null) {
      return _PageState(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to load customer calls',
        message: _viewModel.error!,
        actionLabel: 'Try again',
        onAction: _viewModel.retry,
      );
    }

    if (!_viewModel.hasAccess) {
      return const _PageState(
        icon: Icons.lock_outline_rounded,
        title: 'Access not available',
        message:
        'The Mobile Caller role is required to use customer call tracking.',
      );
    }

    return RefreshIndicator(
      color: _blue,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _OverviewCard(
                  employeeName:
                  _viewModel.access?.employee?.employeeName ?? '',
                  callCount: _viewModel.calls.length,
                  phoneCount: _viewModel.localCustomerPhoneCount,
                  lookupTime: _viewModel.lookupGeneratedAt,
                  onCustomers: _openCustomers,
                  onSync: _syncCalls,
                  syncing: _viewModel.syncing,
                ),
                const SizedBox(height: 10),
                _FilterBar(
                  viewModel: _viewModel,
                  onFilter: _showFilters,
                  onClear: _viewModel.clearHistoryFilters,
                ),
                if (_viewModel.error != null) ...[
                  const SizedBox(height: 9),
                  _FeedbackBanner(
                    message: _viewModel.error!,
                    isError: true,
                    onClose: _viewModel.clearError,
                  ),
                ],
                if (_viewModel.operationError != null) ...[
                  const SizedBox(height: 9),
                  _FeedbackBanner(
                    message: _viewModel.operationError!,
                    isError: true,
                    onClose: _viewModel.clearOperationFeedback,
                  ),
                ] else if (_viewModel.operationMessage != null) ...[
                  const SizedBox(height: 9),
                  _FeedbackBanner(
                    message: _viewModel.operationMessage!,
                    isError: false,
                    onClose: _viewModel.clearOperationFeedback,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Call history',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_viewModel.calls.length} loaded',
                      style: const TextStyle(color: _muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ]),
            ),
          ),
          if (_viewModel.historyLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _blue)),
            )
          else if (_viewModel.calls.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _HistoryEmpty(
                filtered: _viewModel.hasHistoryFilters,
                onSync: _syncCalls,
                onClear: _viewModel.clearHistoryFilters,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.builder(
                itemCount: _viewModel.calls.length + 1,
                itemBuilder: (context, index) {
                  if (index == _viewModel.calls.length) {
                    return _HistoryFooter(
                      loading: _viewModel.historyLoadingMore,
                      hasMore: _viewModel.historyHasMore,
                      onLoad: _viewModel.loadMoreHistory,
                    );
                  }
                  final call = _viewModel.calls[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _CallCard(
                      call: call,
                      uploadProgress:
                      _viewModel.isUploadingRecordingFor(call.name)
                          ? _viewModel.recordingUploadProgress
                          : null,
                      onTap: () => _showCallDetails(call),
                      onCall: () => _dial(call.phoneNumber),
                      onAddRecording: () => _pickRecording(call),
                      onRemoveRecording: call.hasRecording
                          ? () => _confirmRemoveRecording(call)
                          : null,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openCustomers() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerSearchScreen(viewModel: _viewModel),
      ),
    );
  }

  Future<void> _syncCalls() async {
    // Use the Android Call Log adapter by default.
    // A custom loader can still be injected by a caller if needed.
    final loader = widget.callLogLoader ?? AndroidCallLogAdapter.loadCalls;

    try {
      final entries = await loader();
      if (!mounted) return;

      final summary = await _viewModel.syncDeviceCalls(entries);

      // Persist only the Android call-log IDs that ERPNext confirmed as
      // successfully synchronized. Failed calls remain eligible for retry.
      await AndroidCallLogAdapter.markCallsAsSynced(
        summary.syncedAndroidCallLogIds,
      );

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _SyncResultSheet(summary: summary),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_plainError(error))),
      );
    }
  }

  Future<void> _showFilters() async {
    var callType = _viewModel.callTypeFilter;
    var customer = _viewModel.customerFilter;
    var fromDate = _viewModel.fromDate;
    var toDate = _viewModel.toDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter Calls',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        callType = null;
                        customer = null;
                        fromDate = null;
                        toDate = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Call type',
                style: TextStyle(
                  color: _ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: CustomerCallType.values.map((type) {
                  return ChoiceChip(
                    label: Text(type.apiValue),
                    selected: callType == type,
                    onSelected: (selected) =>
                        setSheetState(() => callType = selected ? type : null),
                    labelStyle: const TextStyle(fontSize: 10.5),
                    selectedColor: const Color(0xFFDCE8FF),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 13),
              _FilterTile(
                icon: Icons.business_outlined,
                title: 'Customer',
                value: customer ?? 'All customers',
                onTap: () async {
                  final selected = await Navigator.of(context)
                      .push<CustomerCallCustomerModel>(
                    MaterialPageRoute(
                      builder: (_) => CustomerSearchScreen(
                        viewModel: _viewModel,
                        selectionMode: true,
                      ),
                    ),
                  );
                  if (selected != null) {
                    setSheetState(() => customer = selected.name);
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _FilterTile(
                      icon: Icons.date_range_outlined,
                      title: 'From',
                      value: fromDate == null ? 'Any date' : _date(fromDate!),
                      onTap: () async {
                        final picked = await _pickDate(fromDate);
                        if (picked != null) {
                          setSheetState(() => fromDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterTile(
                      icon: Icons.event_available_outlined,
                      title: 'To',
                      value: toDate == null ? 'Any date' : _date(toDate!),
                      onTap: () async {
                        final picked = await _pickDate(toDate);
                        if (picked != null) {
                          setSheetState(() => toDate = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _viewModel.applyHistoryFilters(
                      callType: callType,
                      customer: customer,
                      fromDate: fromDate,
                      toDate: toDate,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
  }

  Future<void> _showCallDetails(CustomerCallModel initialCall) async {
    _viewModel.loadCallDetails(initialCall.name);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final call = _viewModel.selectedCall?.name == initialCall.name
              ? _viewModel.selectedCall!
              : initialCall;
          return _CallDetailsSheet(
            call: call,
            uploading: _viewModel.isUploadingRecordingFor(call.name),
            uploadProgress: _viewModel.recordingUploadProgress,
            onCall: () => _dial(call.phoneNumber),
            onAddRecording: () => _pickRecording(call),
            onRemoveRecording: call.hasRecording
                ? () => _confirmRemoveRecording(call)
                : null,
          );
        },
      ),
    );
    _viewModel.clearSelectedCall();
  }

  Future<void> _pickRecording(CustomerCallModel call) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'm4a',
          'aac',
          'wav',
          'ogg',
          'opus',
          'amr',
          '3gp',
        ],
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;

      final filePath = file.path;

      if (filePath == null || filePath.trim().isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access the selected recording file.'),
          ),
        );
        return;
      }

      await _viewModel.uploadRecording(
        callRecord: call.name,
        filePath: filePath,
        fileName: file.name,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_plainError(error)),
        ),
      );
    }
  }

  Future<void> _confirmRemoveRecording(CustomerCallModel call) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove recording?'),
        content: const Text(
          'The recording will be detached from this customer call record.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _viewModel.removeRecording(call.name);
    }
  }

  Future<void> _dial(String number) async {
    final uri = Uri(scheme: 'tel', path: number.trim());
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the Phone app.')),
      );
    }
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.employeeName,
    required this.callCount,
    required this.phoneCount,
    required this.lookupTime,
    required this.onCustomers,
    required this.onSync,
    required this.syncing,
  });

  final String employeeName;
  final int callCount;
  final int phoneCount;
  final DateTime? lookupTime;
  final VoidCallback onCustomers;
  final VoidCallback onSync;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    final firstName = employeeName.trim().isEmpty
        ? 'Sales calls'
        : employeeName.trim().split(' ').first;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_navy, _blue]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28123FA0),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lookupTime == null
                          ? 'Customer numbers ready for local matching'
                          : 'Customer list updated ${_relative(lookupTime!)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  value: '$callCount',
                  label: 'Calls loaded',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetric(
                  value: '$phoneCount',
                  label: 'Customer numbers',
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCustomers,
                  icon: const Icon(Icons.people_alt_outlined, size: 17),
                  label: const Text('Customers'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    textStyle: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: syncing ? null : onSync,
                  icon: const Icon(Icons.sync_rounded, size: 17),
                  label: Text(syncing ? 'Syncing' : 'Sync now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _navy,
                    disabledBackgroundColor: Colors.white54,
                    textStyle: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: const TextStyle(color: Colors.white70, fontSize: 9.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.viewModel,
    required this.onFilter,
    required this.onClear,
  });

  final CustomerCallViewModel viewModel;
  final VoidCallback onFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ActionChip(
            onPressed: onFilter,
            avatar: Icon(
              Icons.tune_rounded,
              size: 16,
              color: viewModel.hasHistoryFilters ? _blue : _muted,
            ),
            label: Text(
              viewModel.hasHistoryFilters ? 'Filters active' : 'Filter',
            ),
            labelStyle: TextStyle(
              color: viewModel.hasHistoryFilters ? _navy : _muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: viewModel.hasHistoryFilters
                ? const Color(0xFFEAF1FF)
                : Colors.white,
            side: BorderSide.none,
          ),
          if (viewModel.callTypeFilter != null) ...[
            const SizedBox(width: 7),
            _ActiveFilter(label: viewModel.callTypeFilter!.apiValue),
          ],
          if (viewModel.customerFilter != null) ...[
            const SizedBox(width: 7),
            _ActiveFilter(label: viewModel.customerFilter!),
          ],
          if (viewModel.fromDate != null || viewModel.toDate != null) ...[
            const SizedBox(width: 7),
            _ActiveFilter(
              label: viewModel.fromDate != null && viewModel.toDate != null
                  ? '${_date(viewModel.fromDate!)} – ${_date(viewModel.toDate!)}'
                  : viewModel.fromDate != null
                  ? 'From ${_date(viewModel.fromDate!)}'
                  : 'Until ${_date(viewModel.toDate!)}',
            ),
          ],
          if (viewModel.hasHistoryFilters) ...[
            const SizedBox(width: 5),
            IconButton(
              tooltip: 'Clear filters',
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 17, color: _muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveFilter extends StatelessWidget {
  const _ActiveFilter({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _navy,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({
    required this.call,
    required this.onTap,
    required this.onCall,
    required this.onAddRecording,
    this.onRemoveRecording,
    this.uploadProgress,
  });

  final CustomerCallModel call;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onAddRecording;
  final VoidCallback? onRemoveRecording;
  final double? uploadProgress;

  @override
  Widget build(BuildContext context) {
    final tone = _tone(call.callType);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: tone.background,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(tone.icon, size: 19, color: tone.foreground),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                call.customer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _TypeBadge(type: call.callType),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          call.phoneNumber,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 11,
                          runSpacing: 5,
                          children: [
                            _Meta(
                              icon: Icons.schedule_rounded,
                              text: _dateTime(call.callDateTime),
                            ),
                            _Meta(
                              icon: Icons.timer_outlined,
                              text: _duration(call.durationSeconds),
                            ),
                            if (call.hasRecording)
                              const _Meta(
                                icon: Icons.mic_none_rounded,
                                text: 'Recording',
                                color: _blue,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_CallAction>(
                    tooltip: 'Call actions',
                    onSelected: (action) {
                      switch (action) {
                        case _CallAction.call:
                          onCall();
                          break;
                        case _CallAction.recording:
                          onAddRecording();
                          break;
                        case _CallAction.removeRecording:
                          onRemoveRecording?.call();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _CallAction.call,
                        child: _MenuItem(
                          icon: Icons.call_outlined,
                          label: 'Call customer',
                        ),
                      ),
                      PopupMenuItem(
                        value: _CallAction.recording,
                        child: _MenuItem(
                          icon: Icons.upload_file_outlined,
                          label: call.hasRecording
                              ? 'Replace recording'
                              : 'Add recording',
                        ),
                      ),
                      if (call.hasRecording)
                        const PopupMenuItem(
                          value: _CallAction.removeRecording,
                          child: _MenuItem(
                            icon: Icons.link_off_rounded,
                            label: 'Remove recording',
                            color: Color(0xFFB42318),
                          ),
                        ),
                    ],
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: _muted,
                    ),
                  ),
                ],
              ),
              if (uploadProgress != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: uploadProgress == 0 ? null : uploadProgress,
                        color: _blue,
                        backgroundColor: const Color(0xFFEAF1FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      uploadProgress == 0
                          ? 'Uploading'
                          : '${(uploadProgress! * 100).round()}%',
                      style: const TextStyle(color: _muted, fontSize: 9.5),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _CallAction { call, recording, removeRecording }

class _CallDetailsSheet extends StatelessWidget {
  const _CallDetailsSheet({
    required this.call,
    required this.uploading,
    required this.uploadProgress,
    required this.onCall,
    required this.onAddRecording,
    this.onRemoveRecording,
  });

  final CustomerCallModel call;
  final bool uploading;
  final double uploadProgress;
  final VoidCallback onCall;
  final VoidCallback onAddRecording;
  final VoidCallback? onRemoveRecording;

  @override
  Widget build(BuildContext context) {
    final tone = _tone(call.callType);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      decoration: const BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 1, 8, 9),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Call Details',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: tone.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tone.icon,
                          color: tone.foreground,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              call.customer,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              call.phoneNumber,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _TypeBadge(type: call.callType),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _DetailsCard(
                  children: [
                    _DetailRow(
                      label: 'Date & time',
                      value: _dateTime(call.callDateTime),
                    ),
                    _DetailRow(
                      label: 'Duration',
                      value: _duration(call.durationSeconds),
                    ),
                    _DetailRow(label: 'Source', value: call.source.apiValue),
                    _DetailRow(
                      label: 'Contact',
                      value: call.contact ?? 'Customer number',
                    ),
                    _DetailRow(
                      label: 'Sync status',
                      value: call.syncStatus.apiValue,
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            call.hasRecording
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: call.hasRecording ? _blue : _muted,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              call.hasRecording
                                  ? 'Recording attached'
                                  : 'No recording attached',
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (uploading) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: uploadProgress == 0 ? null : uploadProgress,
                          color: _blue,
                          backgroundColor: const Color(0xFFEAF1FF),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: uploading ? null : onAddRecording,
                              icon: const Icon(
                                Icons.upload_file_outlined,
                                size: 17,
                              ),
                              label: Text(
                                call.hasRecording ? 'Replace' : 'Add recording',
                              ),
                            ),
                          ),
                          if (onRemoveRecording != null) ...[
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              tooltip: 'Remove recording',
                              onPressed: uploading ? null : onRemoveRecording,
                              color: const Color(0xFFB42318),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call_rounded, size: 19),
                    label: const Text('Call Customer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final String label;
  final String value;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 10.5),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncResultSheet extends StatelessWidget {
  const _SyncResultSheet({required this.summary});
  final CustomerCallSyncSummary summary;
  @override
  Widget build(BuildContext context) {
    final successful = summary.failed == 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
      decoration: const BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          CircleAvatar(
            radius: 27,
            backgroundColor: successful
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFFECEC),
            child: Icon(
              successful ? Icons.check_rounded : Icons.warning_amber_rounded,
              color: successful
                  ? const Color(0xFF067647)
                  : const Color(0xFFB42318),
              size: 29,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            successful ? 'Call sync completed' : 'Call sync needs attention',
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Only numbers matching company customers were sent.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 10.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ResultMetric(label: 'Scanned', value: summary.scanned),
              const SizedBox(width: 7),
              _ResultMetric(label: 'Matched', value: summary.matched),
              const SizedBox(width: 7),
              _ResultMetric(label: 'Synced', value: summary.synced),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _ResultMetric(
                label: 'Personal skipped',
                value: summary.skippedUnmatched,
              ),
              const SizedBox(width: 7),
              _ResultMetric(label: 'Failed', value: summary.failed),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: _blue),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: _navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: _blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: _muted, fontSize: 9.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final CustomerCallType type;
  @override
  Widget build(BuildContext context) {
    final tone = _tone(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.apiValue,
        style: TextStyle(
          color: tone.foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? _muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color ?? _muted, fontSize: 9.5),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? _muted),
        const SizedBox(width: 9),
        Text(label, style: TextStyle(fontSize: 12, color: color ?? _ink)),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.isError,
    required this.onClose,
  });
  final String message;
  final bool isError;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB42318) : const Color(0xFF067647);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 3, 7),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFECEC) : const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 10.5)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({
    required this.filtered,
    required this.onSync,
    required this.onClear,
  });
  final bool filtered;
  final VoidCallback onSync;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 45, 28, 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone_in_talk_outlined, size: 54, color: Color(0xFF98A2B3)),
          const SizedBox(height: 13),
          Text(
            filtered ? 'No matching calls' : 'No customer calls yet',
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            filtered
                ? 'Change or clear the selected filters.'
                : 'Sync the device call history. Only matched customer calls will be uploaded.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 10.5),
          ),
          const SizedBox(height: 13),
          OutlinedButton.icon(
            onPressed: filtered ? onClear : onSync,
            icon: Icon(
              filtered ? Icons.filter_alt_off_outlined : Icons.sync_rounded,
              size: 17,
            ),
            label: Text(filtered ? 'Clear filters' : 'Sync calls'),
          ),
        ],
      ),
    );
  }
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter({
    required this.loading,
    required this.hasMore,
    required this.onLoad,
  });
  final bool loading;
  final bool hasMore;
  final VoidCallback onLoad;
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
          ),
        ),
      );
    }
    if (!hasMore) return const SizedBox(height: 5);
    return Center(
      child: TextButton(onPressed: onLoad, child: const Text('Load more')),
    );
  }
}

class _PageState extends StatelessWidget {
  const _PageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 54, color: const Color(0xFF98A2B3)),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: _blue),
                child: Text(actionLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD0D5DD),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _CallTone {
  const _CallTone(this.foreground, this.background, this.icon);
  final Color foreground;
  final Color background;
  final IconData icon;
}

_CallTone _tone(CustomerCallType type) {
  switch (type) {
    case CustomerCallType.incoming:
      return const _CallTone(
        Color(0xFF067647),
        Color(0xFFDCFCE7),
        Icons.call_received_rounded,
      );
    case CustomerCallType.outgoing:
      return const _CallTone(
        _blue,
        Color(0xFFEAF1FF),
        Icons.call_made_rounded,
      );
    case CustomerCallType.missed:
      return const _CallTone(
        Color(0xFFB42318),
        Color(0xFFFFECEC),
        Icons.phone_missed_rounded,
      );
    case CustomerCallType.rejected:
      return const _CallTone(
        Color(0xFFB54708),
        Color(0xFFFFF4E5),
        Icons.call_end_rounded,
      );
  }
}

String _date(DateTime value) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String _dateTime(DateTime? value) {
  if (value == null) return 'Date unavailable';
  final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${_date(value)}, $hour:$minute $period';
}

String _duration(int seconds) {
  if (seconds <= 0) return '0 sec';
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  if (minutes == 0) return '$remaining sec';
  if (remaining == 0) return '$minutes min';
  return '$minutes min $remaining sec';
}

String _relative(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  return _date(value);
}

String _plainError(Object error) {
  return error.toString().replaceFirst(RegExp(r'^(Exception):\s*'), '');
}
