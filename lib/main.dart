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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
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
        BlocProvider(
          create: (context) => LlmCubit(),
        ),
      ],
      child: MaterialApp.router(
        title: 'DevIO',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            brightness: Brightness.light,
            primary: Colors.black,
            secondary: Colors.black87,
            surface: Colors.white,
            background: Colors.white,
            error: Colors.red.shade900,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}