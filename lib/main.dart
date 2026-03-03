import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alray_app/providers/attendance_provider.dart';
import 'package:alray_app/routes/app_router.dart';
import 'package:alray_app/firebase_options.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/providers/theme_provider.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/services/call_service.dart';
import 'package:alray_app/app_config.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-detect flavor from the Android product flavor — no -t flag needed.
  AppConfig.setFlavor(appFlavor == 'dev' ? Flavor.dev : Flavor.prod);

  // Select the Firebase project that matches the flavor.
  // The native google-services.json is picked by Gradle per flavor, so the
  // Dart-level options must align with it.
  final firebaseOptions = AppConfig.isDev
      ? DevFirebaseOptions.currentPlatform
      : ProdFirebaseOptions.currentPlatform;

  // The background service may already have initialized Firebase at the native
  // layer — silently skip if that's the case.
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    // duplicate-app is fine; it means the bg service already initialized it.
    debugPrint('Firebase already initialized: $e');
  }

  await CallService().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = createAppRouter(_authProvider);
    _initPreferences();

    final payload = CallService().initialPayload;
    if (payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // A slight delay ensures the initial /projects route has settled
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _router.go(payload);
            CallService().initialPayload = null;
          }
        });
      });
    }
  }

  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Load currency system preference
    final useIndian = prefs.getBool('indian_system') ?? true;
    CurrencyUtils.useIndianSystem = useIndian;
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProxyProvider<AuthProvider, BudgetProvider>(
          create: (_) => BudgetProvider(),
          update: (_, auth, budget) => budget!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ContactsProvider>(
          create: (_) => ContactsProvider(),
          update: (_, auth, contacts) =>
              contacts!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (_) => AttendanceProvider(),
          update: (_, auth, attendance) =>
              attendance!..updateUserId(auth.user?.uid),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: AppConfig.isDev,
            title: AppConfig.appName,
            theme: themeProvider.themeData,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
