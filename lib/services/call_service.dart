import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:alray_app/firebase_options.dart';
import 'package:alray_app/routes/app_router.dart';
import 'package:flutter/services.dart' show appFlavor;

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Background isolate has its own Dart heap — init Firebase only if not done.
  // Use the same flavor-aware options as the main isolate so the background
  // service connects to the correct Firebase project (dev vs prod).
  if (Firebase.apps.isEmpty) {
    final opts = (appFlavor == 'dev')
        ? DevFirebaseOptions.currentPlatform
        : ProdFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: opts);
  }

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // The background isolate needs its own initialization
  await CallService().initNotifications();
  CallService().startListening();
}

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isListening = false;
  String? _lastNotifiedNumber;
  String? _activeContactId; // Store DB ID of the person currently calling
  String? _activeContactName; // Store Name for post-call prompt

  Future<void> init() async {
    // Request permissions from the UI thread FIRST
    await [Permission.phone, Permission.notification].request();

    // Configure and Start Background Service
    await initNotifications();

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'call_alerts',
        initialNotificationTitle: 'Alray Tracker',
        initialNotificationContent: '',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );
  }

  String? initialPayload;

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    final details = await _notificationsPlugin
        .getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      initialPayload = details.notificationResponse?.payload;
    }

    // Initialize with a callback to handle when a user TAPS the notification
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          debugPrint('Notification tapped, navigating to ${response.payload}');
          if (appRouter != null) {
            appRouter!.go(response.payload!);
          } else {
            initialPayload = response.payload;
          }
        }
      },
    );
  }

  void startListening() {
    if (_isListening) return;
    _isListening = true;

    PhoneState.stream.listen((event) {
      if (event.status == PhoneStateStatus.CALL_INCOMING) {
        final number = event.number;
        if (number != null && number.isNotEmpty) {
          // Avoid duplicate notifications for the same call
          if (_lastNotifiedNumber != number) {
            _lastNotifiedNumber = number;
            _checkContactAndNotify(number);
          }
        }
      } else if (event.status == PhoneStateStatus.CALL_ENDED ||
          event.status == PhoneStateStatus.NOTHING) {
        // If we were just talking to a known contact, prompt for notes
        if (_activeContactId != null &&
            _activeContactName != null &&
            event.status == PhoneStateStatus.CALL_ENDED) {
          _showPostCallNotePrompt(_activeContactId!, _activeContactName!);
        }

        _lastNotifiedNumber = null;
        _activeContactId = null;
        _activeContactName = null;
      }
    });
  }

  Future<void> _checkContactAndNotify(String incomingNumber) async {
    try {
      final cleanIncoming = incomingNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      final snapshot = await FirebaseFirestore.instance
          .collection('contacts')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final phone = data['phoneNumber'] as String?;
        if (phone != null) {
          final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

          if (cleanPhone.isNotEmpty &&
              (cleanIncoming.endsWith(cleanPhone) ||
                  cleanPhone.endsWith(cleanIncoming))) {
            _activeContactId = doc.id;
            _activeContactName = data['name'] as String? ?? 'Unknown';
            final role = data['role'] as String? ?? 'Team Member';

            // 1. Notify user of incoming Team Member call
            await showNotification(doc.id, _activeContactName!, role);

            // 2. Increment Call Count in DB
            await FirebaseFirestore.instance
                .collection('contacts')
                .doc(doc.id)
                .update({'callCount': FieldValue.increment(1)});
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error matching contact: $e');
    }
  }

  Future<void> showNotification(
    String contactId,
    String contactName,
    String role,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'call_alerts',
          'Call Alerts',
          channelDescription:
              'Notifications for incoming calls from team members',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Incoming Team Call',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: 0,
      title: 'Team Member Calling',
      body: '$contactName ($role) is calling you.',
      notificationDetails: platformChannelSpecifics,
      payload:
          '/contacts/details/$contactId', // Tells the router where to go on tap
    );
  }

  Future<void> _showPostCallNotePrompt(
    String contactId,
    String contactName,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'call_notes',
          'Call Notes Prompt',
          channelDescription: 'Reminders to add notes after team calls',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: 1, // Separate ID so it doesn't overwrite the incoming ring notification
      title: 'Call Ended: $contactName',
      body: 'Tap to open Alray and log your meeting notes.',
      notificationDetails: platformChannelSpecifics,
      payload: '/contacts/details/$contactId?openNote=true',
    );
  }
}
