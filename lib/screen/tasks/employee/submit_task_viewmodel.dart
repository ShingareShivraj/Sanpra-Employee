import 'package:flutter/foundation.dart';

import '../../../model/task_model.dart';
import '../../../services/task_service.dart';

class TaskLocation {
  const TaskLocation(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

typedef TaskPhotoUploader = Future<String> Function(String localPath);
typedef TaskLocationProvider = Future<TaskLocation?> Function();

class SubmitTaskViewModel extends ChangeNotifier {
  SubmitTaskViewModel({
    required this.taskName,
    TaskService? taskService,
    this.photoUploader,
    this.locationProvider,
  }) : _taskService = taskService ?? TaskService();

  final String taskName;
  final TaskService _taskService;
  final TaskPhotoUploader? photoUploader;
  final TaskLocationProvider? locationProvider;

  bool submitting = false;
  bool obtainingLocation = false;
  String? selectedPhotoPath;
  TaskLocation? location;
  String? errorMessage;
  TaskModel? submittedTask;

  void setPhoto(String? path) {
    selectedPhotoPath = path?.trim().isEmpty == true ? null : path;
    notifyListeners();
  }

  void removePhoto() {
    selectedPhotoPath = null;
    notifyListeners();
  }

  Future<void> captureLocation() async {
    if (obtainingLocation || locationProvider == null) return;
    obtainingLocation = true;
    errorMessage = null;
    notifyListeners();
    try {
      location = await locationProvider!();
      if (location == null) errorMessage = 'Current location was not available.';
    } catch (error) {
      errorMessage = _cleanError(error);
    } finally {
      obtainingLocation = false;
      notifyListeners();
    }
  }

  void removeLocation() {
    location = null;
    notifyListeners();
  }

  String? validateRemarks(String value) {
    if (value.trim().isEmpty) return 'Completion remarks are required.';
    return null;
  }

  Future<bool> submit(String remarks) async {
    if (submitting) return false;
    final validation = validateRemarks(remarks);
    if (validation != null) {
      errorMessage = validation;
      notifyListeners();
      return false;
    }

    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      String? photoUrl;
      if (selectedPhotoPath != null) {
        if (photoUploader == null) {
          throw Exception('Photo upload is not configured.');
        }
        photoUrl = await photoUploader!(selectedPhotoPath!);
        if (photoUrl.trim().isEmpty) throw Exception('Photo upload failed.');
      }

      submittedTask = await _taskService.submitTaskCompletion(
        taskName: taskName,
        completionRemarks: remarks.trim(),
        completionPhoto: photoUrl,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
      return true;
    } catch (error) {
      errorMessage = _cleanError(error);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  static String _cleanError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
