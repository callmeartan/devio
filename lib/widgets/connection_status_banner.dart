import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/llm/cubit/llm_cubit.dart';

/// A non-intrusive banner that displays connection status at the top of the chat screen
/// without using harsh error messaging
class ConnectionStatusBanner extends StatelessWidget {
  /// Callback when the user taps the connect button
  final VoidCallback? onConnectTap;

  /// Whether the banner should be animated
  final bool animate;

  const ConnectionStatusBanner({
    super.key,
    this.onConnectTap,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<LlmCubit>().testConnection(),
      builder: (context, snapshot) {
        // While testing connection, show a subtle loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatusBanner(
            context,
            icon: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withOpacity(0.7),
              ),
              strokeWidth: 2,
            ),
            title: 'Checking connection...',
            backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.7),
            textColor: theme.colorScheme.onSurfaceVariant,
            showButton: false,
          );
        }

        // Handle connection test result
        final isConnected = snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!['status'] == 'connected';

        if (isConnected) {
          // Connected - show subtle success message that auto-dismisses
          return _buildStatusBanner(
            context,
            icon: Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 20,
            ),
            title: 'Connected to Ollama',
            subtitle: 'Version: ${snapshot.data!['version'] ?? 'unknown'}',
            backgroundColor: Colors.green.withOpacity(0.1),
            textColor: Colors.green.shade800,
            showButton: false,
            autoDismiss: true,
          );
        } else {
          // Not connected - show friendly setup prompt
          return _buildStatusBanner(
            context,
            icon: Icon(
              Icons.router_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            title: 'Ollama connection needed',
            subtitle: 'Set up a connection to start chatting with AI',
            backgroundColor:
                theme.colorScheme.primaryContainer.withOpacity(0.7),
            textColor: theme.colorScheme.onPrimaryContainer,
            showButton: true,
            buttonText: 'Connect',
            onButtonTap: onConnectTap,
          );
        }
      },
    );
  }

  Widget _buildStatusBanner(
    BuildContext context, {
    required Widget icon,
    required String title,
    String? subtitle,
    required Color backgroundColor,
    required Color textColor,
    bool showButton = false,
    String buttonText = 'Connect',
    VoidCallback? onButtonTap,
    bool autoDismiss = false,
  }) {
    final theme = Theme.of(context);

    // Auto-dismiss banner after delay if requested
    if (autoDismiss) {
      Future.delayed(const Duration(seconds: 3), () {
        // Only dismiss if still in the tree
        if (context.mounted) {
          // This requires the parent to listen for this notification
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        }
      });
    }

    Widget banner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(child: icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showButton) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onButtonTap,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                foregroundColor: textColor,
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Add animation if requested
    if (animate) {
      return AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedSlide(
          offset: const Offset(0, 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: banner,
        ),
      );
    }

    return banner;
  }
}

/// Extension method to easily show the connection banner
extension ConnectionBannerExtension on ScaffoldMessengerState {
  /// Shows a connection status banner at the top of the scaffold
  void showConnectionBanner({
    required BuildContext context,
    VoidCallback? onConnectTap,
  }) {
    showMaterialBanner(
      MaterialBanner(
        padding: EdgeInsets.zero,
        content: ConnectionStatusBanner(
          onConnectTap: onConnectTap,
        ),
        backgroundColor: Colors.transparent,
        // Empty leading to avoid the default icon
        leading: const SizedBox.shrink(),
        // No actions as they're handled in the banner itself
        actions: const [SizedBox.shrink()],
        forceActionsBelow: false,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
