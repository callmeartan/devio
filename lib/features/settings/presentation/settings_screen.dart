import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/preferences_cubit.dart';
import '../cubit/preferences_state.dart';
import '../../../blocs/auth/auth_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return BlocConsumer<PreferencesCubit, PreferencesState>(
            listener: (context, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: theme.colorScheme.error,
                    action: SnackBarAction(
                      label: 'Dismiss',
                      textColor: theme.colorScheme.onError,
                      onPressed: () {
                        context.read<PreferencesCubit>().clearError();
                      },
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  authState.maybeWhen(
                    authenticated: (uid, displayName, email) => _buildSection(
                      theme,
                      title: 'Account',
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout_outlined),
                          title: const Text('Log Out'),
                          textColor: theme.colorScheme.error,
                          iconColor: theme.colorScheme.error,
                          onTap: () => _showLogoutDialog(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_forever_outlined),
                          title: const Text('Delete Account'),
                          subtitle: const Text('This action cannot be undone'),
                          textColor: theme.colorScheme.error,
                          iconColor: theme.colorScheme.error,
                          onTap: () => _showDeleteAccountDialog(context),
                        ),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  
                  _buildSection(
                    theme,
                    title: 'Appearance',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Theme'),
                        subtitle: Text(_getThemeModeName(state.themeMode)),
                        onTap: () => _showThemeDialog(context, state.themeMode),
                      ),
                    ],
                  ),
                  
                  _buildSection(
                    theme,
                    title: 'Notifications',
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_outlined),
                        title: const Text('Enable Notifications'),
                        subtitle: const Text('Receive app notifications'),
                        value: state.isNotificationsEnabled,
                        onChanged: (value) => context
                            .read<PreferencesCubit>()
                            .toggleNotifications(value),
                      ),
                      if (state.isNotificationsEnabled) ...[
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications_active_outlined),
                          title: const Text('Push Notifications'),
                          subtitle: const Text('Receive push notifications'),
                          value: state.isPushNotificationsEnabled,
                          onChanged: (value) => context
                              .read<PreferencesCubit>()
                              .togglePushNotifications(value),
                        ),
                        SwitchListTile(
                          secondary: const Icon(Icons.email_outlined),
                          title: const Text('Email Notifications'),
                          subtitle: const Text('Receive email updates'),
                          value: state.isEmailNotificationsEnabled,
                          onChanged: (value) => context
                              .read<PreferencesCubit>()
                              .toggleEmailNotifications(value),
                        ),
                      ],
                    ],
                  ),
                  
                  _buildSection(
                    theme,
                    title: 'About',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Version'),
                        subtitle: const Text('1.0.0'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.update_outlined),
                        title: const Text('Check for Updates'),
                        onTap: () {
                          // Implement update check
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) => RadioListTile<ThemeMode>(
            title: Text(_getThemeModeName(mode)),
            value: mode,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                context.read<PreferencesCubit>().setThemeMode(value);
              }
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().signOut();
              context.go('/');
            },
            child: Text(
              'Log Out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account? This action cannot be undone and you will lose:',
            ),
            SizedBox(height: 16),
            Text('• All your chat history'),
            Text('• Your preferences and settings'),
            Text('• Your saved data'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();
              try {
                await context.read<AuthCubit>().deleteAccount();
                if (context.mounted) {
                  router.go('/');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete Account',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
} 