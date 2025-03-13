import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/settings/cubit/preferences_cubit.dart';
import 'features/settings/cubit/preferences_state.dart';
import 'blocs/auth/auth_cubit.dart';
import 'repositories/chat_repository.dart';
import 'cubits/chat/chat_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:devio/router.dart';
import 'features/llm/cubit/llm_cubit.dart';
import 'theme/app_theme.dart';
import 'features/storage/cubit/storage_mode_cubit.dart';
import 'features/storage/models/storage_mode.dart';
import 'features/storage/services/local_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final localAuthService = LocalAuthService(prefs: prefs);

  runApp(MyApp(
    prefs: prefs,
    localAuthService: localAuthService,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final LocalAuthService localAuthService;

  const MyApp({
    required this.prefs,
    required this.localAuthService,
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
          create: (context) => StorageModeCubit(prefs),
          lazy: false,
        ),
        BlocProvider(
          create: (context) {
            final storageCubit = context.read<StorageModeCubit>();
            return AuthCubit(
              prefs: prefs,
              localAuthService: localAuthService,
              storageMode: storageCubit.state.mode,
            );
          },
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
        BlocProvider(
          create: (context) => LlmCubit(),
        ),
      ],
      child: BlocBuilder<PreferencesCubit, PreferencesState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'DevIO',
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,
            themeMode: state.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
          );
        },
      ),
    );
  }
}
