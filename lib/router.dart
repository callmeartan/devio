import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:devio/screens/landing_screen.dart';
import 'package:devio/screens/intro_screen.dart';
import 'package:devio/screens/auth_screen.dart';
import 'package:devio/screens/llm_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devio/blocs/auth/auth_cubit.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  redirect: (context, state) async {
    // Get SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;

    // Check authentication state
    final authState = context?.read<AuthCubit>().state;
    final isAuthenticated = authState?.maybeWhen(
      authenticated: (_, __, ___) => true,
      orElse: () => false,
    ) ?? false;

    // If user is authenticated, redirect to LLM chat screen
    if (isAuthenticated && state.matchedLocation != '/llm') {
      return '/llm';
    }

    // If user hasn't seen intro and trying to access a different route, let them proceed
    if (!hasSeenIntro && state.matchedLocation != '/') {
      return null;
    }

    // If user has seen intro but not authenticated, redirect to landing
    if (hasSeenIntro && state.matchedLocation == '/') {
      return '/landing';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'intro',
      builder: (context, state) => const IntroScreen(),
    ),
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
  ],
); 