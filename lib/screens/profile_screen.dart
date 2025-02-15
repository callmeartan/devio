import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devio/blocs/auth/auth_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await context.read<AuthCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          unauthenticated: () => context.go('/'),
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText.rich(
                  TextSpan(
                    children: [
                      const WidgetSpan(
                        child: Icon(Icons.error_outline, color: Colors.white, size: 16),
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
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _handleSignOut(context),
              ),
            ],
          ),
          body: state.maybeWhen(
            authenticated: (uid, displayName, email) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Display name
                  Text(
                    displayName ?? 'Anonymous User',
                    style: theme.textTheme.titleLarge,
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      email,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            orElse: () => const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
} 