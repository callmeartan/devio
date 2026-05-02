import 'package:go_router/go_router.dart';
import 'package:devio/screens/landing_screen.dart';
import 'package:devio/screens/llm_chat_screen.dart';
import 'package:devio/features/profile/presentation/profile_screen.dart';
import 'package:devio/features/profile/presentation/edit_profile_screen.dart';
import 'package:devio/features/settings/presentation/settings_screen.dart';
import 'package:devio/features/notifications/presentation/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devio/blocs/auth/auth_cubit.dart';
import 'package:devio/features/settings/cubit/preferences_cubit.dart';

final appRouter = GoRouter(
  initialLocation: '/llm',
  debugLogDiagnostics: true,
  redirect: (context, state) {
    if (state.matchedLocation == '/' || state.matchedLocation == '/auth') {
      return '/llm';
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
      builder: (context, state) => const LlmChatScreen(),
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
);
