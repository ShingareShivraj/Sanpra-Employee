import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'screen/splash/splash_page.dart';

// Replace this with your actual Task screen import.


import 'services/firebase_background.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(const EmployeeManagementApp());

  // Initialize after runApp so the Navigator is available.
  await NotificationService.instance.initialize();
}

class EmployeeManagementApp extends StatelessWidget {
  const EmployeeManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Employee Management',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),

    );
  }
}