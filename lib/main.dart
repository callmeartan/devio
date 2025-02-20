import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/llm/presentation/llm_chat_screen.dart';
import 'features/llm/cubit/llm_cubit.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LlmCubit(),
      child: MaterialApp(
        title: 'DevIO',
        theme: AppTheme.darkTheme,
        home: const LlmChatScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
