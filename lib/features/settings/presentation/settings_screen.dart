import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/preferences_cubit.dart';
import '../cubit/preferences_state.dart';
import '../../../blocs/auth/auth_cubit.dart';
import 'dart:ui';
import 'package:devio/utils/state_extension_helpers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.colorScheme.surface,
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

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header with gradient
                  SliverAppBar(
                    expandedHeight: 180.0,
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
                      opacity: MediaQuery.of(context).viewPadding.top > 0
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        'Settings',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
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
                            // Settings title at bottom
                            Positioned(
                              bottom: 16,
                              left: 20,
                              child: Text(
                                'Settings',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Settings Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        children: [
                          authState.maybeWhen(
                            authenticated: (uid, displayName, email) =>
                                _buildSection(
                              context,
                              title: 'Account',
                              icon: Icons.person_outline,
                              children: [
                                _buildTile(
                                  context,
                                  icon: Icons.logout_outlined,
                                  title: 'Log Out',
                                  onTap: () => _showLogoutDialog(context),
                                  isDestructive: true,
                                  showDivider: true,
                                ),
                                _buildTile(
                                  context,
                                  icon: Icons.delete_forever_outlined,
                                  title: 'Delete Account',
                                  subtitle: 'This action cannot be undone',
                                  onTap: () =>
                                      _showDeleteAccountDialog(context),
                                  isDestructive: true,
                                ),
                              ],
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            context,
                            title: 'Appearance',
                            icon: Icons.palette_outlined,
                            children: [
                              _buildTile(
                                context,
                                icon: _getThemeModeIcon(state.themeMode),
                                title: 'Theme',
                                subtitle: _getThemeModeName(state.themeMode),
                                onTap: () =>
                                    _showThemeDialog(context, state.themeMode),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            context,
                            title: 'Notifications',
                            icon: Icons.notifications_outlined,
                            children: [
                              _buildSwitchTile(
                                context,
                                icon: Icons.notifications_outlined,
                                title: 'Enable Notifications',
                                subtitle: 'Receive app notifications',
                                value: state.isNotificationsEnabled,
                                onChanged: (value) => context
                                    .read<PreferencesCubit>()
                                    .toggleNotifications(value),
                                showDivider: state.isNotificationsEnabled,
                              ),
                              if (state.isNotificationsEnabled) ...[
                                _buildSwitchTile(
                                  context,
                                  icon: Icons.notifications_active_outlined,
                                  title: 'Push Notifications',
                                  subtitle: 'Receive push notifications',
                                  value: state.isPushNotificationsEnabled,
                                  onChanged: (value) => context
                                      .read<PreferencesCubit>()
                                      .togglePushNotifications(value),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            context,
                            title: 'About',
                            icon: Icons.info_outline,
                            children: [
                              _buildTile(
                                context,
                                icon: Icons.info_outline,
                                title: 'Version',
                                subtitle: '1.0.0',
                                showDivider: true,
                              ),
                              _buildTile(
                                context,
                                icon: Icons.update_outlined,
                                title: 'Check for Updates',
                                onTap: () {
                                  // Implement update check
                                },
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
          );
        },
      ),
    );
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  String _getThemeModeName(ThemeMode mode) {
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

  void _showThemeDialog(BuildContext context, ThemeMode currentMode) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? Colors.grey.shade900 : theme.colorScheme.surface,
        title: Text(
          'Choose Theme',
          style: TextStyle(
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values
              .map((mode) => RadioListTile<ThemeMode>(
                    title: Text(
                      _getThemeModeName(mode).split(' ')[0],
                      style: TextStyle(
                        color:
                            isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    activeColor: theme.colorScheme.primary,
                    value: mode,
                    groupValue: currentMode,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PreferencesCubit>().setThemeMode(value);
                      }
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? Colors.grey.shade900 : theme.colorScheme.surface,
        title: Text(
          'Log Out',
          style: TextStyle(
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.8)
                : theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
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
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            isDark ? Colors.grey.shade900 : theme.colorScheme.surface,
        title: Text(
          'Delete Account',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account? This action cannot be undone and you will lose:',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.8)
                    : theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            _buildBulletPoint(context, 'All your chat history'),
            _buildBulletPoint(context, 'Your preferences and settings'),
            _buildBulletPoint(context, 'Your saved data'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();
              try {
                await context.read<AuthCubit>().deleteAccount();
                if (context.mounted) {
                  router.go('/intro');
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

  Widget _buildBulletPoint(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.8)
                  : theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.8)
                    : theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
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
    VoidCallback? onTap,
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
          trailing: onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                )
              : null,
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

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(
            icon,
            color: isDark
                ? Colors.white.withOpacity(0.8)
                : theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
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
          value: value,
          activeColor: theme.colorScheme.primary,
          onChanged: onChanged,
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
