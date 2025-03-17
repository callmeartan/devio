import 'package:flutter/material.dart';

/// A banner that indicates the app is in demo mode
/// and provides a way to configure a real connection
class DemoModeIndicator extends StatelessWidget {
  /// Callback when the connect button is tapped
  final VoidCallback? onConnectTap;

  /// Whether the indicator should be compact
  final bool compact;

  const DemoModeIndicator({
    super.key,
    this.onConnectTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (compact) {
      return _buildCompactIndicator(context, theme, isDark);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Demo mode icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onTertiaryContainer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),

              // Demo mode title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Mode',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      'Limited functionality available',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer
                            .withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'You\'re seeing pre-defined responses. Connect to an Ollama server for full AI capabilities.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 16),

          // Connect button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onConnectTap,
              icon: const Icon(Icons.link),
              label: const Text('Connect to Ollama'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    theme.colorScheme.onTertiaryContainer.withOpacity(0.8),
                foregroundColor: theme.colorScheme.tertiaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactIndicator(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            'Demo Mode',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onConnectTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.onTertiaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link,
                    size: 12,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Connect',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Factory method to create a floating indicator that appears at the bottom of the screen
  static Widget asFloatingBanner(BuildContext context,
      {VoidCallback? onConnectTap}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: DemoModeIndicator(
        onConnectTap: onConnectTap,
      ),
    );
  }

  /// Factory method to create a compact chip-like indicator
  static Widget asChip(BuildContext context, {VoidCallback? onConnectTap}) {
    return DemoModeIndicator(
      compact: true,
      onConnectTap: onConnectTap,
    );
  }
}
