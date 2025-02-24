import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/auth/auth_cubit.dart';
import '../../../features/settings/cubit/preferences_cubit.dart';
import '../../../features/settings/cubit/preferences_state.dart';
import '../../../cubits/chat/chat_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // Custom App Bar with Profile Info
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: theme.colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.8),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                  centerTitle: true,
                  title: state.maybeWhen(
                    authenticated: (_, displayName, __) => Text(
                      displayName ?? 'User',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    orElse: () => const Text('User'),
                  ),
                ),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              
              // Profile Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Profile Picture and Email
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Hero(
                            tag: 'profile_picture',
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primaryContainer,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          state.maybeWhen(
                            authenticated: (_, __, email) => Text(
                              email ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    // Account Section
                    _buildSection(
                      theme,
                      title: 'Account',
                      icon: Icons.person_outline,
                      children: [
                        _buildTile(
                          theme,
                          icon: Icons.edit_outlined,
                          title: 'Edit Profile',
                          onTap: () => context.push('/edit-profile'),
                          showDivider: true,
                        ),
                        _buildTile(
                          theme,
                          icon: Icons.logout,
                          title: 'Log Out',
                          onTap: () => _showLogoutDialog(context),
                          isDestructive: true,
                        ),
                      ],
                    ),

                    // Preferences Section
                    _buildSection(
                      theme,
                      title: 'Preferences',
                      icon: Icons.settings_outlined,
                      children: [
                        BlocBuilder<PreferencesCubit, PreferencesState>(
                          builder: (context, prefsState) => _buildTile(
                            theme,
                            icon: prefsState.themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : prefsState.themeMode == ThemeMode.light
                                    ? Icons.light_mode
                                    : Icons.brightness_auto,
                            title: 'Theme',
                            subtitle: _getThemeModeName(prefsState.themeMode),
                            onTap: () => _showThemeDialog(context, prefsState.themeMode),
                            showDivider: true,
                          ),
                        ),
                        _buildTile(
                          theme,
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          onTap: () => context.push('/notifications'),
                          showDivider: true,
                        ),
                        _buildTile(
                          theme,
                          icon: Icons.settings,
                          title: 'Settings',
                          onTap: () => context.push('/settings'),
                          showDivider: true,
                        ),
                        _buildTile(
                          theme,
                          icon: Icons.delete_outline,
                          title: 'Clear Chat History',
                          onTap: () => _showClearChatHistoryDialog(context),
                          isDestructive: true,
                        ),
                      ],
                    ),

                    // App Section
                    _buildSection(
                      theme,
                      title: 'App',
                      icon: Icons.info_outline,
                      children: [
                        _buildTile(
                          theme,
                          icon: Icons.info_outline,
                          title: 'About',
                          onTap: () {},
                          showDivider: true,
                        ),
                        _buildTile(
                          theme,
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () {},
                          showDivider: true,
                        ),
                        _buildTile(
                          theme,
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          onTap: () {},
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) => RadioListTile<ThemeMode>(
            title: Text(
              _getThemeModeName(mode),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            secondary: Icon(
              mode == ThemeMode.dark
                  ? Icons.dark_mode
                  : mode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto,
              color: isDark ? Colors.white : Colors.black,
            ),
            value: mode,
            groupValue: currentMode,
            activeColor: isDark ? Colors.white : Colors.black,
            onChanged: (value) {
              if (value != null) {
                context.read<PreferencesCubit>().setThemeMode(value);
              }
              Navigator.pop(context);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ],
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

  void _showClearChatHistoryDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatCubit>().clearChat();
              context.go('/');
            },
            child: Text(
              'Clear History',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = false,
    bool isDestructive = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: isDestructive
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
      ],
    );
  }
} 