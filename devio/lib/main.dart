import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'routes.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  developer.log('Starting Devio app...');
  runApp(const DevioApp());
}

class DevioApp extends StatelessWidget {
  const DevioApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('Building DevioApp with router configuration');
    return MaterialApp.router(
      title: 'Devio',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
