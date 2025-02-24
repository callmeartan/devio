import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:devio/screens/landing_screen.dart';
import 'package:devio/screens/intro_screen.dart';
import 'package:devio/screens/auth_screen.dart';
import 'package:devio/screens/llm_chat_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
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