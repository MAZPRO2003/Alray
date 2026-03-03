import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:alray_app/screens/main_tab_screen.dart';
import 'package:alray_app/screens/dashboard_screen.dart';
import 'package:alray_app/screens/projects_list_screen.dart';
import 'package:alray_app/screens/settings_screen.dart';
import 'package:alray_app/screens/project_details_screen.dart';
import 'package:alray_app/screens/contacts_screen.dart';
import 'package:alray_app/screens/contact_details_screen.dart';
import 'package:alray_app/screens/profile_screen.dart';
import 'package:alray_app/screens/login_screen.dart';
import 'package:alray_app/screens/signup_screen.dart';
import 'package:alray_app/screens/labor_payment_screen.dart';
import 'package:alray_app/providers/auth_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter? appRouter;

GoRouter createAppRouter(AuthProvider authProvider) {
  appRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: authProvider,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';

      if (!isAuthenticated) {
        if (!isLoggingIn && !isSigningUp) return '/login';
        return null;
      }

      if (isLoggingIn || isSigningUp) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainTabScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Projects
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const ProjectsListScreen(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ProjectDetailsScreen(projectId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'labor-payments',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return LaborPaymentScreen(projectId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: People
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                builder: (context, state) {
                  final highlightId = state.uri.queryParameters['highlightId'];
                  final openNoteId = state.uri.queryParameters['openNoteId'];
                  return ContactsScreen(
                    highlightId: highlightId,
                    openNoteId: openNoteId,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final openNote =
                          state.uri.queryParameters['openNote'] == 'true';
                      return ContactDetailsScreen(
                        contactId: id,
                        openNote: openNote,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return appRouter!;
}
