import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_endpoints.dart';
import 'api_service.dart';

class FCMService {
  FCMService._();

  static final FCMService instance = FCMService._();

  final ApiService _api = ApiService();

  Future<void> updateFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();

    if (token == null) return;

    print("FCM Token : $token");

    await _api.post(
      url: ApiEndpoints.updateFCMToken,
      data: {
        "fcm_token": token,
      },
    );
  }
}