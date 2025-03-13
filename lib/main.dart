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
import 'dart:developer' as developer;

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
        Provider<ChatRepository>(
          create: (_) => ChatRepository(),
        ),
      ],
      child: BlocBuilder<PreferencesCubit, PreferencesState>(
        builder: (context, state) {
          return AuthCubitProvider(
            prefs: prefs,
            localAuthService: localAuthService,
            child: ChatCubitProvider(
              child: BlocProvider(
                create: (context) => LlmCubit(),
                child: MaterialApp.router(
                  title: 'DevIO',
                  debugShowCheckedModeBanner: false,
                  routerConfig: appRouter,
                  themeMode: state.themeMode,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget that provides the AuthCubit and recreates it when the storage mode changes
class AuthCubitProvider extends StatefulWidget {
  final Widget child;
  final SharedPreferences prefs;
  final LocalAuthService localAuthService;

  const AuthCubitProvider({
    required this.child,
    required this.prefs,
    required this.localAuthService,
    Key? key,
  }) : super(key: key);

  @override
  State<AuthCubitProvider> createState() => _AuthCubitProviderState();
}

class _AuthCubitProviderState extends State<AuthCubitProvider> {
  late AuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    final storageMode = context.read<StorageModeCubit>().state.mode;
    developer.log('Initial AuthCubit creation with mode: ${storageMode.name}');
    _authCubit = AuthCubit(
      prefs: widget.prefs,
      localAuthService: widget.localAuthService,
      storageMode: storageMode,
    );
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StorageModeCubit, StorageModeState>(
      listenWhen: (previous, current) => previous.mode != current.mode,
      listener: (context, state) {
        developer.log(
            'Storage mode changed to: ${state.mode.name}, recreating AuthCubit');

        // Close the old AuthCubit
        _authCubit.close();

        // Create a new AuthCubit with the new storage mode
        _authCubit = AuthCubit(
          prefs: widget.prefs,
          localAuthService: widget.localAuthService,
          storageMode: state.mode,
        );

        // Force a rebuild to use the new AuthCubit
        setState(() {});
      },
      child: BlocProvider.value(
        value: _authCubit,
        child: widget.child,
      ),
    );
  }
}

/// Widget that provides the ChatCubit and recreates it when the storage mode changes
class ChatCubitProvider extends StatefulWidget {
  final Widget child;

  const ChatCubitProvider({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatCubitProvider> createState() => _ChatCubitProviderState();
}

class _ChatCubitProviderState extends State<ChatCubitProvider> {
  late ChatCubit _chatCubit;

  @override
  void initState() {
    super.initState();
    final storageMode = context.read<StorageModeCubit>().state.mode;
    developer.log('Initial ChatCubit creation with mode: ${storageMode.name}');
    _chatCubit = ChatCubit.fromStorageMode(storageMode);
  }

  @override
  void dispose() {
    _chatCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StorageModeCubit, StorageModeState>(
      listenWhen: (previous, current) => previous.mode != current.mode,
      listener: (context, state) {
        developer.log(
            'Storage mode changed to: ${state.mode.name}, recreating ChatCubit');

        // Close the old ChatCubit
        _chatCubit.close();

        // Create a new ChatCubit with the new storage mode
        _chatCubit = ChatCubit.fromStorageMode(state.mode);

        // Force a rebuild to use the new ChatCubit
        setState(() {});
      },
      child: BlocProvider.value(
        value: _chatCubit,
        child: widget.child,
      ),
    );
  }
}
