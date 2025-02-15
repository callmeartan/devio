import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DevioApp());
}

class DevioApp extends StatelessWidget {
  const DevioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Devio',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
