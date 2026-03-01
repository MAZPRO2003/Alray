import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alray_app/routes/app_router.dart';
import 'package:alray_app/firebase_options.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/services/call_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alray_app/app_config.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: AppConfig.isDev,
        title: AppConfig.appName,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4), // Deep Premium Purple
            primary: const Color(0xFF6750A4), // Purple
            onPrimary: Colors.white,
            secondary: const Color(0xFF03DAC6), // Vibrant Teal
            onSecondary: Colors.black,
            tertiary: const Color(0xFFEF233C), // Vibrant Red accent
            surface: const Color(0xFFFDFBFF), // Very light purple-tinted white
            background: const Color(0xFFF4F3F7), // Light premium grey/purple
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ), // Poppins often feels more premium/colorful than Inter
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF6750A4), // Solid colored app bar
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6750A4), // Match primary
                width: 2.0,
              ),
            ),
            labelStyle: TextStyle(color: Colors.grey.shade700),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shadowColor: const Color(0xFF6750A4).withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 8,
            shadowColor: const Color(0xFF6750A4).withOpacity(0.15),
            color: Colors.white,
            surfaceTintColor: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF03DAC6), // Vibrant Teal
            foregroundColor: Colors.black87,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}
