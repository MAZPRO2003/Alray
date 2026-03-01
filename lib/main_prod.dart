import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alray_app/firebase_options.dart';
import 'package:alray_app/services/call_service.dart';
import 'package:alray_app/app_config.dart';
import 'package:alray_app/main.dart' show MyApp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setFlavor(Flavor.prod);
  // Guard against duplicate-app exception if the background service
  // has already initialized Firebase at the native layer.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase already initialized: $e');
  }
  await CallService().init();
  runApp(const MyApp());
}
