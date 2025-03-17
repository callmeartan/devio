import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/llm/cubit/llm_cubit.dart';
import '../features/llm/cubit/llm_state.dart';

/// A widget that replaces error messages in the chat with friendly guidance
/// when trying to use chat functionality without an Ollama connection
class ConnectionRequiredPlaceholder extends StatelessWidget {
  /// Callback for when the user taps the connect button
  final VoidCallback? onConnectTap;

  const ConnectionRequiredPlaceholder({
    super.key,
    this.onConnectTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.8)
            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings_ethernet,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ollama Connection Required',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'To chat with AI, you need to connect to an Ollama server running on your computer or network.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildSetupStep(
            context,
            number: '1',
            text: 'Install Ollama on your computer',
            isDark: isDark,
          ),
          _buildSetupStep(
            context,
            number: '2',
            text: 'Run Ollama with network access enabled',
            isDark: isDark,
          ),
          _buildSetupStep(
            context,
            number: '3',
            text: 'Connect DevIO to your Ollama server',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: onConnectTap,
              icon: const Icon(Icons.link),
              label: const Text('Connect to Ollama'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStep(
    BuildContext context, {
    required String number,
    required String text,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? theme.colorScheme.onSurface.withOpacity(0.8)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Factory method to create a typing-like indicator in the chat
  static Widget asTypingMessage(BuildContext context) {
    return BlocBuilder<LlmCubit, LlmState>(
      builder: (context, state) {
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: ConnectionRequiredPlaceholder(
              onConnectTap: () {
                // Show connection dialog
                final llmCubit = context.read<LlmCubit>();
                // Call the configuration dialog
                // This would typically be in your LlmChatScreen class
                // We'll use a simple scaffold message for now
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        const Text('Configure Ollama connection to continue'),
                    action: SnackBarAction(
                      label: 'Configure',
                      onPressed: () {
                        // TODO: Show the actual configuration dialog
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
