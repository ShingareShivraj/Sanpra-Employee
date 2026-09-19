import 'package:flutter/foundation.dart';

import '../../model/lead_model.dart';
import '../../services/lead_service.dart';

class EditLeadViewModel extends ChangeNotifier {
  final String leadName;
  final LeadService _service;
  LeadModel? lead;
  LeadMasterDataModel masterData = const LeadMasterDataModel();
  List<LeadEventModel> events = const [];
  bool loading = false;
  bool saving = false;
  bool eventBusy = false;
  String? error;
  String? eventsError;
  bool _disposed = false;

  EditLeadViewModel({
    required this.leadName,
    LeadModel? initialLead,
    LeadService? service,
  })  : lead = initialLead,
        _service = service ?? LeadService();

  String get currentLeadId {
    final canonicalName = lead?.name.trim() ?? '';
    return canonicalName.isNotEmpty
        ? canonicalName
        : leadName.trim();
  }

  Future<void> initialise() async {
    loading = true;
    error = null;
    _notify();
    try {
      final results = await Future.wait<dynamic>([
        _service.getLead(leadName),
        _service.getMasterData(),
      ]);
      lead = results[0] as LeadModel;
      masterData = results[1] as LeadMasterDataModel;
      await loadEvents();
    } catch (e) {
      error = _message(e);
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> refresh() => initialise();

  Future<void> loadEvents() async {
    eventsError = null;
    try {
      final result = await _service.getLeadEvents(currentLeadId);
      events = result.events;
    } catch (e) {
      eventsError = _message(e);
    }
    _notify();
  }

  Future<String?> updateLead(LeadModel value) async {
    if (saving) return null;
    saving = true;
    error = null;
    _notify();
    try {
      final result = await _service.updateLead(value);
      lead = result.lead.name.isEmpty ? value : result.lead;
      return result.message;
    } catch (e) {
      error = _message(e);
      return null;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<String?> saveEvent(LeadEventModel value) async {
    if (eventBusy) return null;
    eventBusy = true;
    eventsError = null;
    _notify();
    try {
      final result = value.name.isEmpty
          ? await _service.createLeadEvent(
        leadName: currentLeadId,
        event: value,
      )
          : await _service.updateLeadEvent(value);
      await loadEvents();
      return result.message;
    } catch (e) {
      eventsError = _message(e);
      return null;
    } finally {
      eventBusy = false;
      _notify();
    }
  }

  Future<String?> deleteEvent(String eventName) async {
    if (eventBusy) return null;
    eventBusy = true;
    eventsError = null;
    _notify();
    try {
      final result = await _service.deleteLeadEvent(eventName);
      events = events.where((event) => event.name != eventName).toList();
      return result.message;
    } catch (e) {
      eventsError = _message(e);
      return null;
    } finally {
      eventBusy = false;
      _notify();
    }
  }

  String _message(Object e) => e is LeadServiceException
      ? e.message
      : e.toString().replaceFirst('Exception: ', '');

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
