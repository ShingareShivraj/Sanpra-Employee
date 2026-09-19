import 'package:flutter/foundation.dart';

import '../../model/lead_model.dart';
import '../../services/lead_service.dart';
import '../../services/lead_service.dart';

class AddLeadViewModel extends ChangeNotifier {
  final LeadService _service;

  AddLeadViewModel({LeadService? service})
      : _service = service ?? LeadService();

  LeadMasterDataModel masterData = const LeadMasterDataModel();
  bool loading = false;
  bool saving = false;
  String? error;
  bool _disposed = false;


  Future<void> initialise() async {
    loading = true;
    error = null;
    _notify();
    try {
      masterData = await _service.getMasterData();
    } catch (e) {
      error = _message(e);
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<LeadMutationResultModel?> createLead(LeadModel lead) async {
    if (saving) return null;
    saving = true;
    error = null;
    _notify();
    try {
      return await _service.createLead(lead);
    } catch (e) {
      error = _message(e);
      return null;
    } finally {
      saving = false;
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
