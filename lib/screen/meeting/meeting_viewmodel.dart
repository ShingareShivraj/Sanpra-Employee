import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/meeting/meeting_model.dart';
import '../../services/meeting_service.dart';

class MeetingViewModel extends ChangeNotifier {
  final MeetingService _service;

  MeetingViewModel({MeetingService? service})
      : _service = service ?? MeetingService();

  final List<MeetingModel> _meetings = [];
  MeetingAccessModel? _access;
  MeetingListView _selectedView = MeetingListView.upcoming;
  Timer? _searchTimer;
  String _search = '';
  bool _initialLoading = false;
  bool _contentLoading = false;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _hasMore = false;
  String? _error;
  int _requestGeneration = 0;

  List<MeetingModel> get meetings => List.unmodifiable(_meetings);
  MeetingAccessModel? get access => _access;
  MeetingListView get selectedView => _selectedView;
  bool get initialLoading => _initialLoading;
  bool get contentLoading => _contentLoading;
  bool get loadingMore => _loadingMore;
  bool get refreshing => _refreshing;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isMeetingManager => _access?.isMeetingManager ?? false;

  Future<void> initialise() async {
    if (_initialLoading) return;
    _initialLoading = true;
    _error = null;
    notifyListeners();
    try {
      _access = await _service.getAccess();
      await _fetch(reset: true);
    } catch (error) {
      _error = _message(error);
    } finally {
      _initialLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectView(MeetingListView view) async {
    if (_selectedView == view) return;
    _selectedView = view;
    notifyListeners();
    await loadMeetings(reset: true);
  }

  void searchMeetings(String value) {
    _search = value.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => loadMeetings(reset: true),
    );
  }

  Future<void> loadMeetings({required bool reset}) async {
    if ((reset && _contentLoading) ||
        (!reset && (_loadingMore || !_hasMore))) {
      return;
    }
    if (reset) {
      _contentLoading = true;
      _error = null;
    } else {
      _loadingMore = true;
    }
    notifyListeners();
    try {
      await _fetch(reset: reset);
    } catch (error) {
      _error = _message(error);
    } finally {
      _contentLoading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetch({required bool reset}) async {
    final generation = reset ? ++_requestGeneration : _requestGeneration;
    final response = await _service.getMeetings(
      view: _selectedView,
      search: _search,
      start: reset ? 0 : _meetings.length,
    );
    if (generation != _requestGeneration) return;
    if (reset) _meetings.clear();
    final names = _meetings.map((meeting) => meeting.name).toSet();
    _meetings.addAll(
      response.meetings.where((meeting) => names.add(meeting.name)),
    );
    _hasMore = response.hasMore;
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    notifyListeners();
    try {
      _access = await _service.getAccess();
      await _fetch(reset: true);
    } catch (error) {
      _error = _message(error);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  String _message(Object error) => error.toString().replaceFirst(
        RegExp(r'^(Exception|MeetingServiceException):\s*'),
        '',
      );

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
