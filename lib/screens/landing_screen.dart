import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devio/blocs/auth/auth_cubit.dart';
import 'package:devio/constants/assets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devio/features/storage/models/storage_mode.dart';
import 'package:devio/features/storage/cubit/storage_mode_cubit.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: (uid, displayName, email) => context.go('/llm'),
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText.rich(
                  TextSpan(
                    children: [
                      const WidgetSpan(
                        child: Icon(Icons.error_outline,
                            color: Colors.white, size: 16),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: message),
                    ],
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withOpacity(0.8),
                    theme.colorScheme.primary.withOpacity(0.2),
                  ],
                ),
              ),
            ),

            // Animated circles in the background
            Positioned(
              right: -100,
              top: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.primary.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            // Additional decorative circle
            Positioned(
              left: -80,
              bottom: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.secondary.withOpacity(0.15),
                      theme.colorScheme.secondary.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Code snippets at the top for aesthetic
                      _buildCodeSnippets(theme),

                      // Logo
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          AppAssets.logo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App title
                      Text(
                        'DevIO',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // App subtitle
                      Text(
                        'Mobile Interface for Local LLMs',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Connect to locally hosted LLM servers while keeping your data private and secure',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Main buttons section - more minimal design
                      Column(
                        children: [
                          // Get Started button
                          SizedBox(
                            width: 260,
                            child: ElevatedButton(
                              onPressed: () => _handleGetStarted(context),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Sign in button
                          SizedBox(
                            width: 260,
                            child: OutlinedButton(
                              onPressed: () => _handleSignIn(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    theme.brightness == Brightness.light
                                        ? Colors.black
                                        : Colors.white,
                                backgroundColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                    color: theme.brightness == Brightness.light
                                        ? Colors.black.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.5),
                                    width: 0.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.brightness == Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Simple divider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Divider(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.1),
                              thickness: 0.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Local Mode button
                          SizedBox(
                            width: 260,
                            child: ElevatedButton(
                              onPressed: () => _handleLocalModeLogin(context),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onPrimary,
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Use Local Mode',
                                style: TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Local Mode description
                          Text(
                            'Keep all your data on your device only',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLocalModeLogin(BuildContext context) async {
    try {
      // Set the storage mode to local
      if (context.read<StorageModeCubit?>() != null) {
        developer.log('Setting storage mode to Local Mode');
        await context.read<StorageModeCubit>().useLocalMode();
        developer.log(
            'Storage mode set to Local Mode: ${context.read<StorageModeCubit>().isLocalMode}');
      } else {
        developer.log('StorageModeCubit not available in context');
      }

      // Sign in with local mode
      await context.read<AuthCubit>().signInWithLocalMode();

      // Show a welcome toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Welcome to Local Mode! Your data stays on your device.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      developer.log('Error in _handleLocalModeLogin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleGetStarted(BuildContext context) async {
    try {
      // Set the storage mode to cloud
      if (context.read<StorageModeCubit?>() != null) {
        developer.log('Setting storage mode to Cloud Mode for Get Started');
        await context.read<StorageModeCubit>().useCloudMode();
        developer.log(
            'Storage mode set to Cloud Mode: ${context.read<StorageModeCubit>().isCloudMode}');
      } else {
        developer.log('StorageModeCubit not available in context');
      }

      // Navigate to auth screen with signup mode
      context.go('/auth', extra: {'mode': 'signup'});
    } catch (e) {
      developer.log('Error in _handleGetStarted: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSignIn(BuildContext context) async {
    try {
      // Set the storage mode to cloud
      if (context.read<StorageModeCubit?>() != null) {
        developer.log('Setting storage mode to Cloud Mode for Sign In');
        await context.read<StorageModeCubit>().useCloudMode();
        developer.log(
            'Storage mode set to Cloud Mode: ${context.read<StorageModeCubit>().isCloudMode}');
      } else {
        developer.log('StorageModeCubit not available in context');
      }

      // Navigate to auth screen with login mode
      context.go('/auth', extra: {'mode': 'login'});
    } catch (e) {
      developer.log('Error in _handleSignIn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCodeSnippets(ThemeData theme) {
    final snippets = [
      'class DevIO {',
      '  final privacy = true;',
      '  final localLLM = "ollama";',
      '  final performance = 100;',
      '}',
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32, top: 24),
        child: Text(
          snippets.join('\n'),
          style: TextStyle(
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface.withOpacity(0.08),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
