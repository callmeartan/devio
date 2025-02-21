import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/signup_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/llm_chat_screen.dart';
import 'blocs/auth/auth_cubit.dart';
import 'features/llm/cubit/llm_cubit.dart';
import 'features/llm/services/llm_service.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/settings/cubit/preferences_cubit.dart';
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/help/presentation/help_screen.dart';
import 'features/feedback/presentation/feedback_screen.dart';
import 'repositories/chat_repository.dart';
import 'cubits/chat/chat_cubit.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final authState = context.read<AuthCubit>().state;
    final isAuthenticated = authState.maybeWhen(
      authenticated: (uid, displayName, email) => true,
      initial: () => false,
      loading: () => false,
      unauthenticated: () => false,
      error: (_) => false,
      orElse: () => false,
    );

    final isAuthRoute = state.matchedLocation == '/auth';
    final isInitialRoute = state.matchedLocation == '/';
    final isSignupRoute = state.matchedLocation == '/signup';

    // Don't redirect if we're on the initial route or signup route and not authenticated
    if (!isAuthenticated && (isInitialRoute || isSignupRoute)) {
      return null;
    }

    // Redirect to initial route if not authenticated
    if (!isAuthenticated && !isAuthRoute) {
      return '/';
    }

    // Redirect to LLM chat if authenticated and on auth, initial, or home route
    if (isAuthenticated && (isAuthRoute || isInitialRoute)) {
      return '/llm';
    }

    return null;
  },
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) {
        final params = state.extra as Map<String, String>?;
        return AuthScreen(
          isLogin: params?['mode'] == 'login',
        );
      },
    ),
    GoRoute(
      path: '/llm',
      builder: (context, state) => MultiProvider(
        providers: [
          Provider<LlmService>(
            create: (_) => LlmService(),
          ),
          Provider<ChatRepository>(
            create: (_) => ChatRepository(),
          ),
          BlocProvider<LlmCubit>(
            create: (context) => LlmCubit(
              llmService: context.read<LlmService>(),
            ),
            lazy: false,
          ),
        ],
        child: const LlmChatScreen(),
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: context.read<AuthCubit>(),
          ),
          BlocProvider.value(
            value: context.read<ChatCubit>(),
          ),
        ],
        child: const ProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
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
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    ),
  ),
);
