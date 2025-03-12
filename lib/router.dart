import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:devio/screens/landing_screen.dart';
import 'package:devio/screens/auth_screen.dart';
import 'package:devio/screens/llm_chat_screen.dart';
import 'package:devio/features/profile/presentation/profile_screen.dart';
import 'package:devio/features/profile/presentation/edit_profile_screen.dart';
import 'package:devio/features/settings/presentation/settings_screen.dart';
import 'package:devio/features/notifications/presentation/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devio/blocs/auth/auth_cubit.dart';
import 'package:devio/features/settings/cubit/preferences_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Create a class to listen for auth state changes
class AuthStateChangeNotifier extends ChangeNotifier {
  AuthStateChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }
}

final appRouter = GoRouter(
  initialLocation: '/landing',
  debugLogDiagnostics: true,
  redirect: (context, state) async {
    if (context == null) return null;

    // Check if user is authenticated using Firebase directly
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthenticated = currentUser != null;

    // List of routes that require authentication
    final authenticatedRoutes = [
      '/llm',
      '/profile',
      '/settings',
      '/notifications',
      '/edit-profile'
    ];

    // If user is authenticated, redirect from initial/auth routes to LLM
    if (isAuthenticated) {
      // If currently on landing, auth or empty path, go to LLM
      if (state.matchedLocation == '/landing' ||
          state.matchedLocation == '/auth' ||
          state.matchedLocation == '/') {
        return '/llm';
      }
      // Otherwise, allow access to other routes for authenticated users
      return null;
    } else {
      // If user is not authenticated and trying to access authenticated routes, redirect to landing
      if (authenticatedRoutes.contains(state.matchedLocation)) {
        return '/landing';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/landing',
      name: 'landing',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) {
        final mode = (state.extra as Map<String, String>?)?['mode'] ?? 'login';
        return AuthScreen(isLogin: mode == 'login');
      },
    ),
    GoRoute(
      path: '/llm',
      name: 'llm',
      builder: (context, state) => const LlmChatScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      name: 'edit_profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => PreferencesCubit(
              context.read<SharedPreferences>(),
            ),
          ),
          BlocProvider.value(
            value: context.read<AuthCubit>(),
          ),
        ],
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
  // Refresh when auth state changes
  refreshListenable: AuthStateChangeNotifier(),
);
