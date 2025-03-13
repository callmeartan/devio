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
import 'dart:developer' as developer;
import 'package:devio/features/storage/cubit/storage_mode_cubit.dart';
import 'package:devio/features/storage/models/storage_mode.dart';
import 'package:devio/features/storage/services/local_auth_service.dart';

// Create a class to listen for auth state changes
class AuthStateChangeNotifier extends ChangeNotifier {
  AuthStateChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }
}

// Flag to completely bypass redirect logic
bool bypassRedirect = false;

// Flag to track if we're in the process of signing out
bool isSigningOut = false;

final appRouter = GoRouter(
  initialLocation: '/landing',
  debugLogDiagnostics: true,
  redirect: (context, state) async {
    if (context == null) return null;

    // If we're in the process of signing out and going to landing, allow it
    if (isSigningOut && state.matchedLocation == '/landing') {
      developer.log('Detected sign-out navigation to landing screen');
      isSigningOut = false; // Reset the flag
      return null; // Allow direct navigation to landing
    }

    // If bypass flag is set, allow direct navigation without any redirects
    if (bypassRedirect) {
      developer.log('Bypassing redirect logic completely');
      bypassRedirect = false; // Reset the flag after use
      return null;
    }

    // Check if we're in Local Mode
    final storageCubit = context.read<StorageModeCubit?>();
    final isLocalMode = storageCubit != null && storageCubit.isLocalMode;

    // Get the current auth state
    final authCubit = context.read<AuthCubit?>();
    final isAuthenticated = authCubit?.state.maybeWhen(
          authenticated: (_, __, ___) => true,
          orElse: () => false,
        ) ??
        false;

    // If in Local Mode, check if a local user exists
    if (isLocalMode) {
      // List of routes that require authentication
      final authenticatedRoutes = [
        '/llm',
        '/profile',
        '/settings',
        '/notifications',
        '/edit-profile'
      ];

      // If user is authenticated in Local Mode
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
        // If user is not authenticated and trying to access authenticated routes
        if (authenticatedRoutes.contains(state.matchedLocation)) {
          return '/landing';
        }
      }
    } else {
      // In Cloud Mode, use Firebase authentication
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
        // If user is not authenticated and trying to access authenticated routes
        if (authenticatedRoutes.contains(state.matchedLocation)) {
          // Try anonymous sign-in first
          try {
            developer.log('Attempting anonymous sign-in from router...');
            await FirebaseAuth.instance.signInAnonymously();
            developer.log('Anonymous sign-in successful from router');
            // After successful sign-in, allow access to the requested route
            return state.matchedLocation;
          } catch (e) {
            developer.log('Anonymous sign-in failed from router: $e');
            // If anonymous sign-in fails, redirect to landing
            return '/landing';
          }
        }
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
        final mode = (state.extra as Map<String, dynamic>?)?['mode'] ?? 'login';
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
          BlocProvider.value(
            value: context.read<StorageModeCubit>(),
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

// Helper function to set the bypass flag
void setBypassRedirect() {
  bypassRedirect = true;
}

// Helper function to set the signing out flag
void setSigningOut() {
  isSigningOut = true;
}
