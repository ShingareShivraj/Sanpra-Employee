import 'package:android_id/android_id.dart';

class DeviceService {
  DeviceService._();

  static final DeviceService instance = DeviceService._();

  Future<String> getAndroidId() async {
    const AndroidId androidId = AndroidId();

    return await androidId.getId() ?? "";
  }
}