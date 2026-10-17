import 'package:flutter/foundation.dart';

import '../../model/lead_model.dart';
import '../../services/lead_service.dart';

class EditLeadViewModel extends ChangeNotifier {
  final String leadName;
  final LeadService _service;
  LeadModel? lead;
  LeadMasterDataModel masterData = const LeadMasterDataModel();
  List<LeadEventModel> events = const [];
  List<LeadTaskModel> tasks = const [];
  bool _disposed = false;

  bool loading = false;
  bool saving = false;

  bool eventBusy = false;
  bool taskBusy = false;

  String? error;
  String? eventsError;
  String? tasksError;

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

  List<LeadTaskAssigneeModel> get taskAssignees =>
      masterData.taskAssignees;

  List<String> get taskStatuses =>
      masterData.taskStatuses.isNotEmpty
          ? masterData.taskStatuses
          : const [
        'Open',
        'Closed',
        'Cancelled',
      ];

  List<String> get taskPriorities =>
      masterData.taskPriorities.isNotEmpty
          ? masterData.taskPriorities
          : const [
        'Low',
        'Medium',
        'High',
      ];

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
      await Future.wait([
        loadEvents(),
        loadTasks(),
      ]);
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

  Future<void> loadTasks() async {
    tasksError = null;

    try {
      final result = await _service.getLeadTasks(
        currentLeadId,
      );

      final loadedTasks = [...result.tasks];

      loadedTasks.sort((first, second) {
        final firstDate = first.dueDate;
        final secondDate = second.dueDate;

        if (firstDate == null && secondDate == null) {
          return second.creation
              ?.compareTo(first.creation ?? DateTime(1970)) ??
              0;
        }

        if (firstDate == null) return 1;
        if (secondDate == null) return -1;

        return firstDate.compareTo(secondDate);
      });

      tasks = loadedTasks;
    } catch (e) {
      tasksError = _message(e);
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

  Future<String?> saveTask(
      LeadTaskModel value,
      ) async {
    if (taskBusy) return null;

    taskBusy = true;
    tasksError = null;
    _notify();

    try {
      final LeadTaskMutationResultModel result;

      if (value.name.trim().isEmpty) {
        result = await _service.createLeadTask(
          leadName: currentLeadId,
          task: value.copyWith(
            leadId: currentLeadId,
          ),
        );
      } else {
        result = await _service.updateLeadTask(
          value.copyWith(
            leadId: currentLeadId,
          ),
        );
      }

      await loadTasks();

      return result.message;
    } catch (e) {
      tasksError = _message(e);
      return null;
    } finally {
      taskBusy = false;
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

  Future<String?> deleteTask(
      String taskName,
      ) async {
    if (taskBusy) return null;

    final cleanTaskName = taskName.trim();

    if (cleanTaskName.isEmpty) {
      tasksError = 'Task is required.';
      _notify();
      return null;
    }

    taskBusy = true;
    tasksError = null;
    _notify();

    try {
      final result = await _service.deleteLeadTask(
        cleanTaskName,
      );

      tasks = tasks
          .where(
            (task) => task.name != cleanTaskName,
      )
          .toList(growable: false);

      return result.message;
    } catch (e) {
      tasksError = _message(e);
      return null;
    } finally {
      taskBusy = false;
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
