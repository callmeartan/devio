import 'package:flutter/material.dart';
import 'ollama_connection_guide.dart';

class SetupRequiredView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onSetupComplete;
  final VoidCallback? onDismiss;
  final bool showDismissButton;

  const SetupRequiredView({
    super.key,
    this.errorMessage,
    this.onSetupComplete,
    this.onDismiss,
    this.showDismissButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connect a provider',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showDismissButton && onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  tooltip: 'Dismiss',
                ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildProviderChoices(theme),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showDismissButton && onDismiss != null)
                OutlinedButton(
                  onPressed: onDismiss,
                  child: const Text('Later'),
                ),
              FilledButton.icon(
                onPressed: () {
                  _showSetupGuide(context);
                },
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Configure'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderChoices(ThemeData theme) {
    final providers = [
      (Icons.computer_rounded, 'Ollama', 'localhost:11434'),
      (Icons.dns_rounded, 'LM Studio', 'localhost:1234'),
      (Icons.hub_rounded, 'OpenAI-compatible', 'api.openai.com'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: providers
          .map(
            (provider) => Container(
              width: 178,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.42),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(provider.$1, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          provider.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  void _showSetupGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Ollama Connection Setup'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: OllamaConnectionGuide(
            onConnectionSuccess: () {
              Navigator.of(context).pop();
              if (onSetupComplete != null) {
                onSetupComplete!();
              }
            },
          ),
        ),
      ),
    );
  }

  /// Factory method to create a setup required view from an error
  static Widget fromError(
    BuildContext context, {
    required String errorMessage,
    VoidCallback? onSetupComplete,
    VoidCallback? onDismiss,
    bool showDismissButton = true,
  }) {
    // Use more positive messaging regardless of the error
    String setupMessage = 'Select the provider you want to connect.';

    return SetupRequiredView(
      errorMessage: setupMessage,
      onSetupComplete: onSetupComplete,
      onDismiss: onDismiss,
      showDismissButton: showDismissButton,
    );
  }
}
