import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/llm/cubit/llm_cubit.dart';
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ollama Setup Required',
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
                color: theme.colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'To use AI features, you need to connect to Ollama running on your computer.',
            style: theme.textTheme.bodyLarge,
          ),
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
                icon: const Icon(Icons.settings),
                label: const Text('Setup Now'),
              ),
            ],
          ),
        ],
      ),
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
            title: const Text('Ollama Setup Guide'),
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
    // Extract the most relevant part of the error message
    String simplifiedError = errorMessage;

    if (errorMessage.contains('Connection refused') ||
        errorMessage.contains('Unable to connect')) {
      simplifiedError =
          'Please configure your Ollama server IP address in settings. Make sure Ollama is running on your computer.';
    } else if (errorMessage.contains('SocketException')) {
      simplifiedError =
          'Network error. Please check your Ollama IP configuration and ensure Ollama is running.';
    } else if (errorMessage.contains('timed out')) {
      simplifiedError =
          'Connection timed out. Please verify your Ollama IP address and ensure the server is running.';
    }

    return SetupRequiredView(
      errorMessage: simplifiedError,
      onSetupComplete: onSetupComplete,
      onDismiss: onDismiss,
      showDismissButton: showDismissButton,
    );
  }
}
