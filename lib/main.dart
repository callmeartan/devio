import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/settings/cubit/preferences_cubit.dart';
import 'features/settings/cubit/preferences_state.dart';
import 'blocs/auth/auth_cubit.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'repositories/chat_repository.dart';
import 'cubits/chat/chat_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({
    required this.prefs,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        BlocProvider(
          create: (context) => PreferencesCubit(prefs),
        ),
        BlocProvider(
          create: (context) => AuthCubit(),
          lazy: false,
        ),
        Provider<ChatRepository>(
          create: (_) => ChatRepository(),
        ),
        BlocProvider(
          create: (context) => ChatCubit(
            chatRepository: context.read<ChatRepository>(),
          ),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          // Listen for auth state changes if needed
        },
        child: BlocBuilder<PreferencesCubit, PreferencesState>(
          builder: (context, state) {
            if (state.error != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    action: SnackBarAction(
                      label: 'Dismiss',
                      textColor: Theme.of(context).colorScheme.onError,
                      onPressed: () {
                        context.read<PreferencesCubit>().clearError();
                      },
                    ),
                  ),
                );
              });
            }

            return MaterialApp.router(
              title: 'Devio',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: state.themeMode,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}