import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/customer_call_model.dart';
import '../../services/customer_call_service.dart';

class CustomerCallViewModel extends ChangeNotifier {
  CustomerCallViewModel({CustomerCallService? service})
      : _service = service ?? CustomerCallService();

  static const int _historyPageLength = 20;
  static const int _customerPageLength = 20;
  static const int _maximumSyncBatchSize = 100;

  final CustomerCallService _service;
  final List<CustomerCallModel> _calls = [];
  final List<CustomerCallCustomerModel> _customers = [];

  CustomerCallAccessModel? _access;
  CustomerPhoneLookupModel? _phoneLookup;
  CustomerDetailsModel? _customerDetails;
  CustomerCallModel? _selectedCall;

  CustomerCallType? _callTypeFilter;
  String? _customerFilter;
  DateTime? _fromDate;
  DateTime? _toDate;

  Timer? _customerSearchTimer;
  String _customerSearch = '';
  int _customerSearchGeneration = 0;
  bool _customerHasMore = false;

  bool _initialLoading = false;
  bool _refreshing = false;
  bool _historyLoading = false;
  bool _historyLoadingMore = false;
  bool _customerSearching = false;
  bool _customerLoadingMore = false;
  bool _customerDetailsLoading = false;
  bool _lookupRefreshing = false;
  bool _syncing = false;
  String? _uploadingCallRecord;
  double _recordingUploadProgress = 0;
  bool _disposed = false;
  bool _hasInitialised = false;
  bool _historyHasMore = false;
  int _historyGeneration = 0;

  String? _error;
  String? _operationError;
  String? _operationMessage;

  List<CustomerCallModel> get calls => List.unmodifiable(_calls);
  List<CustomerCallCustomerModel> get customers =>
      List.unmodifiable(_customers);
  CustomerCallAccessModel? get access => _access;
  CustomerPhoneLookupModel? get phoneLookup => _phoneLookup;
  CustomerDetailsModel? get customerDetails => _customerDetails;
  CustomerCallModel? get selectedCall => _selectedCall;

  CustomerCallType? get callTypeFilter => _callTypeFilter;
  String? get customerFilter => _customerFilter;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  String get customerSearch => _customerSearch;

  bool get initialLoading => _initialLoading;
  bool get refreshing => _refreshing;
  bool get historyLoading => _historyLoading;
  bool get historyLoadingMore => _historyLoadingMore;
  bool get customerSearching => _customerSearching;
  bool get customerLoadingMore => _customerLoadingMore;
  bool get customerDetailsLoading => _customerDetailsLoading;
  bool get lookupRefreshing => _lookupRefreshing;
  bool get syncing => _syncing;
  bool get historyHasMore => _historyHasMore;
  bool get customerHasMore => _customerHasMore;
  bool get hasInitialised => _hasInitialised;
  bool get hasAccess => _access?.hasAccess ?? false;
  bool get hasHistoryFilters =>
      _callTypeFilter != null ||
          _customerFilter?.isNotEmpty == true ||
          _fromDate != null ||
          _toDate != null;
  bool get isUploadingRecording => _uploadingCallRecord != null;
  String? get uploadingCallRecord => _uploadingCallRecord;
  double get recordingUploadProgress => _recordingUploadProgress;
  String? get error => _error;
  String? get operationError => _operationError;
  String? get operationMessage => _operationMessage;
  int get localCustomerPhoneCount => _phoneLookup?.phones.length ?? 0;
  DateTime? get lookupGeneratedAt => _phoneLookup?.generatedAt;

  Future<void> initialise() async {
    if (_initialLoading || _hasInitialised) return;
    _initialLoading = true;
    _error = null;
    _notify();

    try {
      _access = await _service.getAccess();
      if (!hasAccess) {
        _calls.clear();
        _customers.clear();
        _phoneLookup = null;
        return;
      }

      final results = await Future.wait<dynamic>([
        _service.getPhoneLookup(),
        _service.getCalls(pageLength: _historyPageLength),
      ]);
      _phoneLookup = results[0] as CustomerPhoneLookupModel;
      _replaceHistory(results[1] as CustomerCallPageModel);
    } catch (exception) {
      _error = _message(exception);
    } finally {
      _initialLoading = false;
      _hasInitialised = true;
      _notify();
    }
  }

  Future<void> retry() async {
    _hasInitialised = false;
    await initialise();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    _operationError = null;
    _notify();

    try {
      _access = await _service.getAccess();
      if (!hasAccess) {
        _calls.clear();
        _customers.clear();
        _phoneLookup = null;
        return;
      }

      final results = await Future.wait<dynamic>([
        _service.getPhoneLookup(),
        _fetchHistoryPage(start: 0),
      ]);
      _phoneLookup = results[0] as CustomerPhoneLookupModel;
      _replaceHistory(results[1] as CustomerCallPageModel);
    } catch (exception) {
      _error = _message(exception);
    } finally {
      _refreshing = false;
      _notify();
    }
  }

  Future<void> refreshPhoneLookup() async {
    if (_lookupRefreshing || !hasAccess) return;
    _lookupRefreshing = true;
    _operationError = null;
    _notify();
    try {
      _phoneLookup = await _service.getPhoneLookup();
      _operationMessage =
      'Customer phone list updated successfully.';
    } catch (exception) {
      _operationError = _message(exception);
    } finally {
      _lookupRefreshing = false;
      _notify();
    }
  }

  Future<void> loadHistory({bool reset = true}) async {
    if (!hasAccess) return;
    if (reset) {
      if (_historyLoading) return;
      _historyLoading = true;
      _error = null;
    } else {
      if (_historyLoadingMore || !_historyHasMore) return;
      _historyLoadingMore = true;
    }
    _notify();

    final generation = reset ? ++_historyGeneration : _historyGeneration;
    try {
      final page = await _fetchHistoryPage(
        start: reset ? 0 : _calls.length,
      );
      if (generation != _historyGeneration) return;
      if (reset) {
        _replaceHistory(page);
      } else {
        _appendHistory(page);
      }
    } catch (exception) {
      _error = _message(exception);
    } finally {
      _historyLoading = false;
      _historyLoadingMore = false;
      _notify();
    }
  }

  Future<void> loadMoreHistory() => loadHistory(reset: false);

  Future<void> applyHistoryFilters({
    CustomerCallType? callType,
    String? customer,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
      _operationError = 'From date cannot be after to date.';
      _notify();
      return;
    }
    _callTypeFilter = callType;
    _customerFilter = _nullable(customer);
    _fromDate = fromDate;
    _toDate = toDate;
    await loadHistory();
  }

  Future<void> clearHistoryFilters() async {
    _callTypeFilter = null;
    _customerFilter = null;
    _fromDate = null;
    _toDate = null;
    await loadHistory();
  }

  void searchCustomers(String value) {
    _customerSearch = value.trim();
    _customerSearchTimer?.cancel();
    _customerSearchTimer = Timer(
      const Duration(milliseconds: 350),
          () => loadCustomers(reset: true),
    );
  }

  Future<void> loadCustomers({bool reset = true}) async {
    if (!hasAccess) return;
    if (reset) {
      if (_customerSearching) return;
      _customerSearching = true;
    } else {
      if (_customerLoadingMore || !_customerHasMore) return;
      _customerLoadingMore = true;
    }

    final generation = reset
        ? ++_customerSearchGeneration
        : _customerSearchGeneration;
    _operationError = null;
    _notify();

    try {
      final page = await _service.searchCustomers(
        search: _customerSearch,
        start: reset ? 0 : _customers.length,
        pageLength: _customerPageLength,
      );
      if (generation != _customerSearchGeneration) return;

      if (reset) _customers.clear();
      final existing = _customers.map((item) => item.name).toSet();
      _customers.addAll(
        page.customers.where((item) => existing.add(item.name)),
      );
      _customerHasMore = page.hasMore;
    } catch (exception) {
      _operationError = _message(exception);
    } finally {
      _customerSearching = false;
      _customerLoadingMore = false;
      _notify();
    }
  }

  Future<void> loadMoreCustomers() => loadCustomers(reset: false);

  void clearCustomerSearch() {
    _customerSearchTimer?.cancel();
    _customerSearch = '';
    _customers.clear();
    _customerHasMore = false;
    _notify();
  }

  Future<CustomerDetailsModel?> loadCustomerDetails(String customer) async {
    if (_customerDetailsLoading) return _customerDetails;
    _customerDetailsLoading = true;
    _operationError = null;
    _notify();
    try {
      _customerDetails = await _service.getCustomerDetails(customer);
      return _customerDetails;
    } catch (exception) {
      _operationError = _message(exception);
      return null;
    } finally {
      _customerDetailsLoading = false;
      _notify();
    }
  }

  CustomerPhoneMatchModel? matchCustomerPhone(String phoneNumber) {
    return _phoneLookup?.match(phoneNumber);
  }

  /// Returns null for an unmatched/private phone number. Null entries must
  /// never be uploaded by the caller.
  CustomerCallCreateModel? prepareDeviceCall(DeviceCallLogEntry entry) {
    final match = matchCustomerPhone(entry.phoneNumber);
    if (match == null) return null;

    return CustomerCallCreateModel(
      customer: match.customer,
      contact: match.contact,
      phoneNumber: entry.phoneNumber,
      callType: entry.callType,
      callDateTime: entry.callDateTime,
      durationSeconds: entry.callType == CustomerCallType.missed ||
          entry.callType == CustomerCallType.rejected
          ? 0
          : entry.durationSeconds,
      idempotencyKey: _idempotencyKey(entry),
      deviceId: entry.deviceId,
      androidCallLogId: entry.androidCallLogId,
      source: entry.source,
    );
  }

  Future<CustomerCallSyncSummary> syncDeviceCalls(
      List<DeviceCallLogEntry> deviceCalls,
      ) async {
    if (_syncing) {
      return const CustomerCallSyncSummary(
        scanned: 0,
        matched: 0,
        skippedUnmatched: 0,
        synced: 0,
        failed: 0,
        results: [],
      );
    }
    if (_phoneLookup == null) {
      _operationError =
      'Customer phone list is not loaded. Refresh it and try again.';
      _notify();
      return CustomerCallSyncSummary.empty(scanned: deviceCalls.length);
    }

    final matchedCalls = <CustomerCallCreateModel>[];
    for (final entry in deviceCalls) {
      final call = prepareDeviceCall(entry);
      if (call != null) matchedCalls.add(call);
    }

    if (matchedCalls.isEmpty) {
      _operationMessage = deviceCalls.isEmpty
          ? 'No new device calls were found.'
          : 'No customer calls matched. Personal calls were not uploaded.';
      _operationError = null;
      _notify();
      return CustomerCallSyncSummary(
        scanned: deviceCalls.length,
        matched: 0,
        skippedUnmatched: deviceCalls.length,
        synced: 0,
        failed: 0,
        results: const [],
      );
    }

    _syncing = true;
    _operationError = null;
    _operationMessage = null;
    _notify();

    final results = <CustomerCallSyncItemModel>[];
    final syncedAndroidCallLogIds = <String>{};
    var synced = 0;
    var failed = 0;
    try {
      for (var offset = 0;
      offset < matchedCalls.length;
      offset += _maximumSyncBatchSize) {
        final end = (offset + _maximumSyncBatchSize < matchedCalls.length)
            ? offset + _maximumSyncBatchSize
            : matchedCalls.length;
        final batch = await _service.syncCalls(
          matchedCalls.sublist(offset, end),
        );
        synced += batch.synced;
        failed += batch.failed;
        for (final result in batch.results) {
          final absoluteIndex = offset + result.index;

          results.add(
            CustomerCallSyncItemModel(
              index: absoluteIndex,
              success: result.success,
              created: result.created,
              idempotencyKey: result.idempotencyKey,
              error: result.error,
              call: result.call,
            ),
          );

          // The service response tells us which individual records succeeded.
          // Map that response index back to the matched DeviceCallLogEntry.
          if (result.success &&
              absoluteIndex >= 0 &&
              absoluteIndex < matchedCalls.length) {
            final androidCallLogId =
            matchedCalls[absoluteIndex].androidCallLogId.trim();

            if (androidCallLogId.isNotEmpty) {
              syncedAndroidCallLogIds.add(androidCallLogId);
            }
          }
        }
      }

      if (synced > 0) {
        try {
          final page = await _fetchHistoryPage(start: 0);
          _replaceHistory(page);
        } catch (_) {
          // Sync succeeded; a history-refresh failure must not mark it failed.
        }
      }
      _operationMessage = failed == 0
          ? '$synced customer call${synced == 1 ? '' : 's'} synced.'
          : '$synced calls synced and $failed failed.';

      return CustomerCallSyncSummary(
        scanned: deviceCalls.length,
        matched: matchedCalls.length,
        skippedUnmatched: deviceCalls.length - matchedCalls.length,
        synced: synced,
        failed: failed,
        results: results,
        syncedAndroidCallLogIds: syncedAndroidCallLogIds.toList(),
      );
    } catch (exception) {
      _operationError = _message(exception);
      return CustomerCallSyncSummary(
        scanned: deviceCalls.length,
        matched: matchedCalls.length,
        skippedUnmatched: deviceCalls.length - matchedCalls.length,
        synced: synced,
        failed: matchedCalls.length - synced,
        results: results,
        syncedAndroidCallLogIds: syncedAndroidCallLogIds.toList(),
      );
    } finally {
      _syncing = false;
      _notify();
    }
  }

  Future<CustomerCallModel?> createCall(CustomerCallCreateModel call) async {
    if (_syncing) return null;
    _syncing = true;
    _operationError = null;
    _operationMessage = null;
    _notify();
    try {
      final result = await _service.createCall(call);
      _upsertCall(result.call, moveToTop: true);
      _operationMessage = result.message.isEmpty
          ? 'Customer call saved successfully.'
          : result.message;
      return result.call;
    } catch (exception) {
      _operationError = _message(exception);
      return null;
    } finally {
      _syncing = false;
      _notify();
    }
  }

  Future<CustomerCallModel?> loadCallDetails(String callRecord) async {
    _operationError = null;
    try {
      final call = await _service.getCall(callRecord);
      _selectedCall = call;
      _upsertCall(call);
      _notify();
      return call;
    } catch (exception) {
      _operationError = _message(exception);
      _notify();
      return null;
    }
  }

  Future<CustomerCallModel?> uploadRecording({
    required String callRecord,
    required String filePath,
    String? fileName,
  }) async {
    if (_uploadingCallRecord != null) return null;
    _uploadingCallRecord = callRecord;
    _recordingUploadProgress = 0;
    _operationError = null;
    _operationMessage = null;
    _notify();

    try {
      final call = await _service.uploadAndAttachRecording(
        callRecord: callRecord,
        filePath: filePath,
        fileName: fileName,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          _recordingUploadProgress =
              (sent / total).clamp(0.0, 1.0).toDouble();
          _notify();
        },
      );
      _upsertCall(call);
      if (_selectedCall?.name == call.name) _selectedCall = call;
      _operationMessage = 'Recording attached successfully.';
      return call;
    } catch (exception) {
      _operationError = _message(exception);
      return null;
    } finally {
      _uploadingCallRecord = null;
      _recordingUploadProgress = 0;
      _notify();
    }
  }

  Future<bool> removeRecording(String callRecord) async {
    if (_uploadingCallRecord != null) return false;
    _uploadingCallRecord = callRecord;
    _operationError = null;
    _operationMessage = null;
    _notify();
    try {
      final call = await _service.removeRecording(callRecord);
      _upsertCall(call);
      if (_selectedCall?.name == call.name) _selectedCall = call;
      _operationMessage = 'Recording removed successfully.';
      return true;
    } catch (exception) {
      _operationError = _message(exception);
      return false;
    } finally {
      _uploadingCallRecord = null;
      _notify();
    }
  }

  bool isUploadingRecordingFor(String callRecord) {
    return _uploadingCallRecord == callRecord;
  }

  void clearSelectedCall() {
    _selectedCall = null;
    _notify();
  }

  void clearCustomerDetails() {
    _customerDetails = null;
    _notify();
  }

  void clearError() {
    _error = null;
    _notify();
  }

  void clearOperationFeedback() {
    _operationError = null;
    _operationMessage = null;
    _notify();
  }

  Future<CustomerCallPageModel> _fetchHistoryPage({required int start}) {
    return _service.getCalls(
      customer: _customerFilter,
      callType: _callTypeFilter,
      fromDate: _fromDate,
      toDate: _toDate,
      start: start,
      pageLength: _historyPageLength,
    );
  }

  void _replaceHistory(CustomerCallPageModel page) {
    _calls
      ..clear()
      ..addAll(page.calls);
    _historyHasMore = page.hasMore;
  }

  void _appendHistory(CustomerCallPageModel page) {
    final existing = _calls.map((call) => call.name).toSet();
    _calls.addAll(page.calls.where((call) => existing.add(call.name)));
    _historyHasMore = page.hasMore;
  }

  void _upsertCall(CustomerCallModel call, {bool moveToTop = false}) {
    final index = _calls.indexWhere((item) => item.name == call.name);
    if (index >= 0) _calls.removeAt(index);
    if (moveToTop || index < 0) {
      _calls.insert(0, call);
    } else {
      _calls.insert(index.clamp(0, _calls.length).toInt(), call);
    }
  }

  String _idempotencyKey(DeviceCallLogEntry entry) {
    final employee = _access?.employee?.name ?? 'employee';
    final callIdentity = entry.androidCallLogId.trim().isNotEmpty
        ? entry.androidCallLogId.trim()
        : '${entry.callDateTime.millisecondsSinceEpoch}-'
        '${entry.callType.apiValue}-'
        '${normalizePhoneNumber(entry.phoneNumber)}';
    final value = 'call:$employee:${entry.deviceId}:$callIdentity';
    return value.length <= 140 ? value : value.substring(value.length - 140);
  }

  String? _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _message(Object exception) {
    if (exception is CustomerCallServiceException) return exception.message;
    return exception.toString().replaceFirst(
      RegExp(r'^(Exception|CustomerCallServiceException):\s*'),
      '',
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _customerSearchTimer?.cancel();
    _disposed = true;
    super.dispose();
  }
}

/// Platform-neutral call-log data supplied by the Android integration layer.
/// This ViewModel does not request permissions or scan the device itself.
class DeviceCallLogEntry {
  final String phoneNumber;
  final CustomerCallType callType;
  final DateTime callDateTime;
  final int durationSeconds;
  final String androidCallLogId;
  final String deviceId;
  final CustomerCallSource source;

  const DeviceCallLogEntry({
    required this.phoneNumber,
    required this.callType,
    required this.callDateTime,
    required this.durationSeconds,
    required this.androidCallLogId,
    required this.deviceId,
    this.source = CustomerCallSource.androidCallLog,
  });
}

class CustomerCallSyncSummary {
  final int scanned;
  final int matched;
  final int skippedUnmatched;
  final int synced;
  final int failed;
  final List<CustomerCallSyncItemModel> results;

  /// Android call-log IDs that were confirmed by the ERPNext sync response.
  final List<String> syncedAndroidCallLogIds;

  const CustomerCallSyncSummary({
    required this.scanned,
    required this.matched,
    required this.skippedUnmatched,
    required this.synced,
    required this.failed,
    required this.results,
    this.syncedAndroidCallLogIds = const [],
  });

  factory CustomerCallSyncSummary.empty({required int scanned}) {
    return CustomerCallSyncSummary(
      scanned: scanned,
      matched: 0,
      skippedUnmatched: scanned,
      synced: 0,
      failed: 0,
      results: const [],
    );
  }

  bool get completedWithoutFailure => failed == 0;
  bool get uploadedAnything => synced > 0;
}
