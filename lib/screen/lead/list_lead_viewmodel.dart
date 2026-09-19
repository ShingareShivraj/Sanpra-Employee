import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/lead_model.dart';
import '../../services/lead_service.dart';

class ListLeadViewModel extends ChangeNotifier {
  final LeadService _service;

  ListLeadViewModel({LeadService? service})
      : _service = service ?? LeadService();

  final List<LeadModel> _leads = [];
  LeadMasterDataModel _masterData = const LeadMasterDataModel();
  Timer? _searchTimer;
  bool _loading = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _disposed = false;
  String? _error;
  String _search = '';
  String _status = '';
  String _territory = '';
  int _page = 1;
  bool _hasMore = false;

  List<LeadModel> get leads => List.unmodifiable(_leads);
  LeadMasterDataModel get masterData => _masterData;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  String get search => _search;
  String get status => _status;
  String get territory => _territory;
  bool get hasMore => _hasMore;
  bool get hasFilters => _status.isNotEmpty || _territory.isNotEmpty;

  Future<void> initialise() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _notify();
    try {
      final results = await Future.wait<dynamic>([
        _service.getMasterData(),
        _service.getLeads(page: 1),
      ]);
      _masterData = results[0] as LeadMasterDataModel;
      _replacePage(results[1] as LeadPageModel);
    } catch (error) {
      _error = _message(error);
    } finally {
      _loading = false;
      _notify();
    }
  }

  void updateSearch(String value) {
    _search = value.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 450), refresh);
  }

  Future<void> applyFilters({String? status, String? territory}) async {
    _status = status?.trim() ?? '';
    _territory = territory?.trim() ?? '';
    await refresh();
  }

  Future<void> clearFilters() async {
    _status = '';
    _territory = '';
    await refresh();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    _notify();
    try {
      final page = await _fetch(1);
      _replacePage(page);
    } catch (error) {
      _error = _message(error);
    } finally {
      _refreshing = false;
      _notify();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    _notify();
    try {
      final result = await _fetch(_page + 1);
      final names = _leads.map((lead) => lead.name).toSet();
      _leads.addAll(result.leads.where((lead) => names.add(lead.name)));
      _page = result.page;
      _hasMore = result.hasMore && result.leads.isNotEmpty;
    } catch (error) {
      _error = _message(error);
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  Future<String?> deleteLead(String leadName) async {
    try {
      final result = await _service.deleteLead(leadName);
      _leads.removeWhere((lead) => lead.name == leadName);
      _notify();
      return result.message;
    } catch (error) {
      _error = _message(error);
      _notify();
      return null;
    }
  }

  Future<LeadPageModel> _fetch(int page) {
    return _service.getLeads(
      search: _search,
      status: _status,
      territory: _territory,
      page: page,
    );
  }

  void _replacePage(LeadPageModel result) {
    _leads
      ..clear()
      ..addAll(result.leads);
    _page = result.page;
    _hasMore = result.hasMore;
  }

  String _message(Object error) {
    return error is LeadServiceException
        ? error.message
        : error.toString().replaceFirst('Exception: ', '');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
