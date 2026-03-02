import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:alray_app/screens/main_tab_screen.dart';
import 'package:alray_app/screens/dashboard_screen.dart';

import 'package:alray_app/screens/all_expenses_screen.dart';
import 'package:alray_app/screens/settings_screen.dart';
import 'package:alray_app/screens/project_details_screen.dart';
import 'package:alray_app/screens/contacts_screen.dart';
import 'package:alray_app/screens/contact_details_screen.dart';
import 'package:alray_app/screens/profile_screen.dart';
import 'package:alray_app/screens/login_screen.dart';
import 'package:alray_app/screens/signup_screen.dart';
import 'package:alray_app/screens/analytics_screen.dart';
import 'package:alray_app/screens/ai_chat_screen.dart';
import 'package:alray_app/providers/auth_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter? appRouter;

GoRouter createAppRouter(AuthProvider authProvider) {
  appRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/projects',
    refreshListenable: authProvider,
    debugLogDiagnostics: kDebugMode, // Enable debug logging only in dev
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';

      debugPrint(
        'ROUTER REDIRECT: '
        'isAuthenticated=$isAuthenticated, '
        'loc=${state.matchedLocation}, '
        'uri=${state.uri.toString()}',
      );

      if (!isAuthenticated) {
        // If not authenticated and not on an auth screen, go to login
        if (!isLoggingIn && !isSigningUp) {
          debugPrint('ROUTER REDIRECT: -> /login (not authenticated)');
          return '/login';
        }
        // Allow staying on login or signup
        return null;
      }

      // If authenticated, don't allow auth screens
      if (isLoggingIn || isSigningUp) {
        debugPrint('ROUTER REDIRECT: -> /projects (already authenticated)');
        return '/projects';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiChatScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainTabScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ProjectDetailsScreen(projectId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const AllExpensesScreen(),
              ),
            ],
          ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
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
