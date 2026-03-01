import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alray_app/firebase_options.dart';
import 'package:alray_app/services/call_service.dart';
import 'package:alray_app/app_config.dart';
import 'package:alray_app/main.dart' show MyApp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setFlavor(Flavor.dev);
  // Use the dev Firebase project (alray-dev) so Firestore writes go to the
  // correct database — matching android/app/src/dev/google-services.json.
  await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);
  await CallService().init();
  runApp(const MyApp());
}
