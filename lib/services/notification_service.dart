import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'fcm_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Used to navigate without requiring a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    'default_channel',
    'Employee Notifications',
    description: 'Task and employee-management notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initializeLocalNotifications();
    await _requestPermission();
    await _getFCMToken();

    _listenTokenRefresh();
    _foregroundListener();
    _backgroundOpenListener();

    await _handleTerminatedFCMNotification();
    await _handleTerminatedLocalNotification();

    log('Notification service initialized');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (
          NotificationResponse response,
          ) {
        final payload = response.payload;

        if (payload == null || payload.isEmpty) return;

        try {
          final decoded = jsonDecode(payload);

          if (decoded is Map) {
            _handleNotificationNavigation(
              Map<String, dynamic>.from(decoded),
            );
          }
        } catch (error, stackTrace) {
          log(
            'Unable to decode notification payload',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_androidChannel);

    // Needed on Android 13 and above.
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    log(
      'Notification permission: '
          '${settings.authorizationStatus}',
    );
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await _messaging.getToken();

      log('FCM token: $token');

      if (token != null && token.isNotEmpty) {
        log('FCM token available: $token');
      }
    } catch (error, stackTrace) {
      log(
        'Unable to get FCM token',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      log('FCM token refreshed: $token');

      // This uses your existing, previously working ERPNext request.
      await FCMService.instance.updateFCMToken();
    });
  }

  /// Called when a notification arrives while the app is open.
  void _foregroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log('Foreground notification received');
      log('Data: ${message.data}');

      await _showForegroundNotification(message);
    });
  }

  Future<void> _showForegroundNotification(
      RemoteMessage message,
      ) async {
    final title =
        message.notification?.title ??
            message.data['title']?.toString() ??
            'Employee Management';

    final body =
        message.notification?.body ??
            message.data['body']?.toString() ??
            '';

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId =
        message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Called after the user taps an Android-managed notification while
  /// the app is in the background.
  void _backgroundOpenListener() {
    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        log('Background notification tapped');
        log('Data: ${message.data}');

        _handleNotificationNavigation(message.data);
      },
    );
  }

  /// Called when an FCM notification launches a terminated app.
  Future<void> _handleTerminatedFCMNotification() async {
    final message = await _messaging.getInitialMessage();

    if (message == null) return;

    log('App opened from terminated state using FCM');
    log('Data: ${message.data}');

    _handleNotificationNavigation(message.data);
  }

  /// Handles a local notification that launches a terminated app.
  Future<void> _handleTerminatedLocalNotification() async {
    final launchDetails =
    await _localNotifications.getNotificationAppLaunchDetails();

    final response = launchDetails?.notificationResponse;

    if (launchDetails?.didNotificationLaunchApp != true ||
        response?.payload == null ||
        response!.payload!.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(response.payload!);

      if (decoded is Map) {
        _handleNotificationNavigation(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (error, stackTrace) {
      log(
        'Unable to handle launch notification payload',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleNotificationNavigation(
      Map<String, dynamic> data,
      ) {
    final route = data['route']?.toString();
    final notificationType = data['type']?.toString();

    log('Opening notification route: $route');
    log('Notification type: $notificationType');

    if (route == null || route.isEmpty) return;

    // Navigation may arrive during application startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;

      if (navigator == null) {
        Future<void>.delayed(
          const Duration(milliseconds: 500),
              () => _handleNotificationNavigation(data),
        );
        return;
      }

      navigator.pushNamed(
        route,
        arguments: data,
      );
    });
  }



  Future<String?> getToken() {
    return _messaging.getToken();
  }
}