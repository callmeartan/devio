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
                          onTap: () => _showAboutDialog(context),
                          showDivider: true,
                        ),
                        _buildTile(
                          theme,
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () => _showPrivacyPolicyDialog(context),
                          showDivider: true,
                        ),
                        _buildTile(
                          theme,
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          onTap: () => _showTermsOfServiceDialog(context),
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

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('About DevIO'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_outlined,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'DevIO',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'DevIO is an AI-powered chat application designed to help developers with coding tasks, debugging, and learning new technologies.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Features:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(
                theme,
                icon: Icons.chat_outlined,
                text: 'AI-powered chat assistance',
              ),
              _buildFeatureItem(
                theme,
                icon: Icons.image_outlined,
                text: 'Image analysis capabilities',
              ),
              _buildFeatureItem(
                theme,
                icon: Icons.code_outlined,
                text: 'Code generation and debugging',
              ),
              _buildFeatureItem(
                theme,
                icon: Icons.dark_mode_outlined,
                text: 'Customizable theme options',
              ),
              const SizedBox(height: 16),
              Text(
                '© 2023 DevIO. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    ThemeData theme, {
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: June 1, 2023',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'At DevIO, we prioritize your privacy and do not collect any personal information from our users.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '1. No Data Collection',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'DevIO does not collect, store, or process any personal information from users. All interactions with the app remain on your device.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '2. Local Storage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Any data generated during your use of the app (such as chat history or preferences) is stored locally on your device and is not transmitted to our servers or third parties.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '3. Authentication',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'While we use Firebase Authentication for account management, we only store the minimum required information for this service to function. We do not use this information for any other purpose.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '4. Third-Party Services',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our app may use third-party services (like Firebase) that have their own privacy policies. We recommend reviewing their privacy policies for more information.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '5. Contact Us',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you have any questions about this Privacy Policy, please contact us at privacy@devio.app',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsOfServiceDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: June 1, 2023',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please read these Terms of Service ("Terms") carefully before using the DevIO mobile application operated by DevIO ("us", "we", or "our").',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '1. Acceptance of Terms',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By accessing or using our service, you agree to be bound by these Terms. If you disagree with any part of the terms, you may not access the service.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '2. Use of Service',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You agree to use the service only for purposes that are permitted by these Terms and any applicable law, regulation, or generally accepted practices or guidelines in the relevant jurisdictions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '3. Privacy and Data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'DevIO does not collect personal data from users. Any data generated during your use of the app is stored locally on your device and is not transmitted to our servers or third parties.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '4. Intellectual Property',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The service and its original content, features, and functionality are and will remain the exclusive property of DevIO and its licensors.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '5. Termination',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We may terminate or suspend your access to our service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '6. Limitation of Liability',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'In no event shall DevIO, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the service.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '7. Contact Us',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you have any questions about these Terms, please contact us at terms@devio.app',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
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