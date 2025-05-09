import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../blocs/auth/auth_cubit.dart';
import '../../../features/settings/cubit/preferences_cubit.dart';
import '../../../features/settings/cubit/preferences_state.dart';
import '../../../cubits/chat/chat_cubit.dart';
import 'dart:ui';
import 'package:devio/utils/state_extension_helpers.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.colorScheme.surface,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final displayName = state.maybeWhen(
            authenticated: (_, name, __) => name ?? 'User',
            orElse: () => 'User',
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header with gradient and profile info
              SliverAppBar(
                expandedHeight: 240.0,
                floating: false,
                pinned: true,
                backgroundColor:
                    isDark ? Colors.black : theme.colorScheme.surface,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                title: AnimatedOpacity(
                  opacity:
                      MediaQuery.of(context).viewPadding.top > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color:
                          isDark ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  centerTitle: false,
                  expandedTitleScale: 1.0,
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                Colors.grey.shade800,
                                Colors.grey.shade900,
                                Colors.black,
                              ]
                            : [
                                theme.colorScheme.primary.withOpacity(0.7),
                                theme.colorScheme.surface,
                              ],
                        stops: isDark ? [0.0, 0.5, 1.0] : [0.0, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Subtle pattern overlay
                        Opacity(
                          opacity: 0.05,
                          child: CustomPaint(
                            painter: WavePatternPainter(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                        // Profile info at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      state.maybeWhen(
                                        authenticated: (_, __, email) => Text(
                                          email ?? '',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.black.withOpacity(0.7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        orElse: () => const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : theme.colorScheme.primary
                                            .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey.shade700
                                          : theme.colorScheme.primary
                                              .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'LLM User',
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: isDark
                                          ? Colors.white
                                          : theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Profile Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    children: [
                      // Account Section
                      _buildSection(
                        context,
                        title: 'Account',
                        icon: Icons.person_outline,
                        children: [
                          _buildTile(
                            context,
                            icon: Icons.edit_outlined,
                            title: 'Edit Profile',
                            onTap: () => context.push('/edit-profile'),
                            showDivider: true,
                          ),
                          _buildTile(
                            context,
                            icon: Icons.logout,
                            title: 'Log Out',
                            onTap: () => _showLogoutDialog(context),
                            isDestructive: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Preferences Section
                      _buildSection(
                        context,
                        title: 'Preferences',
                        icon: Icons.settings_outlined,
                        children: [
                          BlocBuilder<PreferencesCubit, PreferencesState>(
                            builder: (context, prefsState) => _buildTile(
                              context,
                              icon: prefsState.themeMode == ThemeMode.dark
                                  ? Icons.dark_mode
                                  : prefsState.themeMode == ThemeMode.light
                                      ? Icons.light_mode
                                      : Icons.brightness_auto,
                              title: 'Theme',
                              subtitle: _getThemeModeDescription(
                                  prefsState.themeMode),
                              onTap: () => _showThemeDialog(
                                  context, prefsState.themeMode),
                              showDivider: true,
                            ),
                          ),
                          _buildTile(
                            context,
                            icon: Icons.settings,
                            title: 'Settings',
                            onTap: () => context.push('/settings'),
                            showDivider: true,
                          ),
                          _buildTile(
                            context,
                            icon: Icons.delete_outline,
                            title: 'Clear Chat History',
                            onTap: () => _showClearChatHistoryDialog(context),
                            isDestructive: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // App Section
                      _buildSection(
                        context,
                        title: 'App',
                        icon: Icons.info_outline,
                        children: [
                          _buildTile(
                            context,
                            icon: Icons.info_outline,
                            title: 'About',
                            onTap: () => _showAboutDialog(context),
                            showDivider: true,
                          ),
                          _buildTile(
                            context,
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            onTap: () => _showPrivacyPolicyDialog(context),
                            showDivider: true,
                          ),
                          _buildTile(
                            context,
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            onTap: () => _showTermsOfServiceDialog(context),
                            showDivider: true,
                          ),
                          _buildTile(
                            context,
                            icon: Icons.star_outline,
                            title: 'Star us on GitHub',
                            onTap: () => _launchGitHubRepo(context),
                            showDivider: true,
                          ),
                          _buildTile(
                            context,
                            icon: Icons.computer_outlined,
                            title: 'How to Run Ollama?',
                            onTap: () => _showOllamaGuideDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        final isPlatformDark =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark;
        return 'System (${isPlatformDark ? 'Dark' : 'Light'})';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
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
          children: [
            _buildThemeOption(
              context,
              mode: ThemeMode.system,
              currentMode: currentMode,
              icon: Icons.brightness_auto,
              title: 'System',
              subtitle: 'Follow system settings',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context,
              mode: ThemeMode.light,
              currentMode: currentMode,
              icon: Icons.light_mode,
              title: 'Light',
              subtitle: 'Light theme',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context,
              mode: ThemeMode.dark,
              currentMode: currentMode,
              icon: Icons.dark_mode,
              title: 'Dark',
              subtitle: 'Dark theme',
              isDark: isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final isSelected = mode == currentMode;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        context.read<PreferencesCubit>().setThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : isDark
                      ? Colors.white
                      : Colors.black,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().signOut();
              context.go('/landing');
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
    final isDark = theme.brightness == Brightness.dark;

    // Cache the NavigatorState to use for checking if context is still mounted
    final navigator = Navigator.of(context);
    // Cache the ScaffoldMessengerState to avoid using context later
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Clear Chat History'),
        content: const Text(
            'Are you sure you want to clear all chat history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              // Close the dialog first
              navigator.pop();

              // Use cached scaffoldMessenger instead of context
              final loadingSnackBar = SnackBar(
                content: Text(
                  'Clearing chat history...',
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.9)
                    : theme.colorScheme.primary,
                duration: const Duration(seconds: 60),
              );

              // Show loading indicator using cached scaffoldMessenger
              scaffoldMessenger.showSnackBar(loadingSnackBar);

              try {
                // Get the ChatCubit instance here before async operation starts
                final chatCubit = context.read<ChatCubit>();

                // Call the clear chat method and await its completion
                await chatCubit.clearChat();

                // Check if navigator is still active before showing results
                if (navigator.mounted) {
                  // Hide the loading indicator using cached messenger
                  scaffoldMessenger.hideCurrentSnackBar();

                  // Show success message using cached messenger
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Chat history cleared successfully',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.9)
                          : theme.colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                // Check if navigator is still active before showing error
                if (navigator.mounted) {
                  // Hide the loading indicator
                  scaffoldMessenger.hideCurrentSnackBar();

                  // Show error message
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error clearing chat history: ${e.toString()}',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Clear History'),
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
                'DevIO is a mobile interface for interacting with locally hosted large language models. Connect to Ollama or other LLM servers while keeping your data private and secure.',
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
                icon: Icons.devices_outlined,
                text: 'Local LLM server integration',
              ),
              _buildFeatureItem(
                theme,
                icon: Icons.image_outlined,
                text: 'Advanced chat capabilities',
              ),
              _buildFeatureItem(
                theme,
                icon: Icons.lock_outlined,
                text: 'Privacy-focused design',
              ),
              _buildFeatureItem(
                theme,
                icon: Icons.dark_mode_outlined,
                text: 'Modern mobile interface',
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
                'This Privacy Policy describes how DevIO ("we", "our", or "us") collects, uses, and protects your information when you use our mobile application.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '1. Information We Collect',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We collect information necessary to provide our services, including account information, chat history, and app preferences. This information is stored securely on Firebase.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '2. How We Use Your Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We use the information we collect to provide and improve our services, personalize your experience, and maintain the functionality of the app. Your data is used solely for these purposes.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '3. Data Storage and Security',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your data is stored on Firebase, a secure cloud platform. We implement appropriate security measures to protect against unauthorized access, alteration, disclosure, or destruction of your information.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '4. Data Retention',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We retain your data for as long as your account is active or as needed to provide you services. You can request deletion of your data at any time through the app settings.',
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
                '3. User Data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your data is stored on Firebase and is used to provide and improve our services. We implement appropriate security measures to protect your information as detailed in our Privacy Policy.',
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

  void _showOllamaGuideDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(
              Icons.computer_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'How to Run Ollama',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Install Ollama
              _buildOllamaStep(
                context,
                stepNumber: '1',
                title: 'Install Ollama',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visit ollama.ai and download the installer for your operating system.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Step 2: Run Ollama Server
              _buildOllamaStep(
                context,
                stepNumber: '2',
                title: 'Run Ollama Server',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open terminal and run:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText(
                        'OLLAMA_HOST=0.0.0.0:11434 ollama serve',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Step 3: Find IP Address
              _buildOllamaStep(
                context,
                stepNumber: '3',
                title: 'Find Your IP Address',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Run the appropriate command for your OS:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '# macOS/Linux:\n',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isDark ? Colors.grey : Colors.grey.shade700,
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text:
                                  'ifconfig | grep "inet " | grep -v 127.0.0.1\n\n',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text: '# Windows:\n',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isDark ? Colors.grey : Colors.grey.shade700,
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text: 'ipconfig',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Step 4: Connect in App
              _buildOllamaStep(
                context,
                stepNumber: '4',
                title: 'Connect in App',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your IP address with port in the app:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText(
                        '192.168.1.x:11434',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Replace 192.168.1.x with your actual IP address',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Important Notes
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Important Notes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Do NOT use 0.0.0.0 as the connection address\n'
                      '• Ensure port 11434 is allowed in your firewall\n'
                      '• Both devices must be on the same network\n'
                      '• Pull a model first using: ollama pull mistral',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
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

  Widget _buildOllamaStep(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchGitHubRepo(BuildContext context) async {
    final Uri url = Uri.parse('https://github.com/callmeartan/devio');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not open GitHub repository',
                style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.9)
                  : theme.colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error opening URL: ${e.toString()}',
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.grey.shade800
                  : theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = false,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: isDestructive
                ? theme.colorScheme.error
                : isDark
                    ? Colors.white.withOpacity(0.8)
                    : theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDestructive
                  ? theme.colorScheme.error
                  : isDark
                      ? Colors.white
                      : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            color: isDark
                ? Colors.grey.shade800
                : theme.colorScheme.outline.withOpacity(0.1),
          ),
      ],
    );
  }
}

// Wave pattern painter for the background
class WavePatternPainter extends CustomPainter {
  final Color color;

  WavePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final path = Path();

    // Create wave pattern
    for (int i = 0; i < 10; i++) {
      final y = size.height * 0.1 + (i * size.height * 0.08);
      path.moveTo(0, y);

      for (int j = 0; j < 10; j++) {
        final x1 = size.width * (j * 0.1 + 0.05);
        final x2 = size.width * (j * 0.1 + 0.1);
        path.quadraticBezierTo(
          x1,
          y + (i % 2 == 0 ? 10 : -10),
          x2,
          y,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
