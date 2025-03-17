import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/llm/cubit/llm_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

/// A conversational guide that appears in the chat to help users set up Ollama
class OllamaSetupChatGuide extends StatelessWidget {
  /// Callback for when the user wants to configure Ollama
  final VoidCallback? onConfigureTap;

  /// Callback for when the user wants to learn more about Ollama
  final VoidCallback? onLearnMoreTap;

  const OllamaSetupChatGuide({
    super.key,
    this.onConfigureTap,
    this.onLearnMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 64, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
            : theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withOpacity(0.2)
              : theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI Avatar
          _buildHeader(context, theme, isDark),

          // Welcome message
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to DevIO! I notice you haven\'t connected to an Ollama server yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'DevIO is designed to connect with Ollama, a local AI server that runs on your computer. This allows for private, high-performance AI interactions.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 16),

                // Quick setup steps
                _buildSetupSteps(context, theme, isDark),

                const SizedBox(height: 16),

                // Setup buttons
                _buildActionButtons(context, theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // AI Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // AI Name
          Text(
            'AI Assistant',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupSteps(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Here\'s how to get started:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Steps with clickable actions
        _buildActionStep(
          context,
          number: 1,
          title: 'Download Ollama',
          description: 'Install Ollama on your computer from ollama.ai',
          actionText: 'Visit ollama.ai',
          actionIcon: Icons.open_in_new,
          onAction: () => _launchUrl('https://ollama.ai'),
          theme: theme,
          isDark: isDark,
        ),

        _buildActionStep(
          context,
          number: 2,
          title: 'Start the Server',
          description: 'Run OLLAMA_HOST=0.0.0.0:11434 ollama serve in terminal',
          actionText: 'Copy Command',
          actionIcon: Icons.content_copy,
          onAction: () => _copyToClipboard(
              context, 'OLLAMA_HOST=0.0.0.0:11434 ollama serve'),
          theme: theme,
          isDark: isDark,
        ),

        _buildActionStep(
          context,
          number: 3,
          title: 'Configure Connection',
          description: 'Enter your computer\'s IP address in DevIO settings',
          actionText: 'Configure Now',
          actionIcon: Icons.settings,
          onAction: onConfigureTap,
          theme: theme,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActionStep(
    BuildContext context, {
    required int number,
    required String title,
    required String description,
    required String actionText,
    required IconData actionIcon,
    required ThemeData theme,
    required bool isDark,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              number.toString(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),

                // Action button
                InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          actionIcon,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          actionText,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onLearnMoreTap,
            icon: const Icon(Icons.help_outline, size: 16),
            label: const Text('Learn More'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onConfigureTap,
            icon: const Icon(Icons.settings_ethernet, size: 16),
            label: const Text('Configure'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    // This would use a clipboard package in a real implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Command copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Factory method to create an instance as a chat message
  static Widget asChatMessage(BuildContext context) {
    return OllamaSetupChatGuide(
      onConfigureTap: () {
        // Show configuration dialog
        // This would be implemented in your LlmChatScreen
        // For now just show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configure Ollama to start chatting'),
            duration: Duration(seconds: 3),
          ),
        );
      },
      onLearnMoreTap: () {
        // Show learn more dialog or screen
        // For now just launch the Ollama website
        final uri = Uri.parse('https://ollama.ai');
        launchUrl(uri);
      },
    );
  }
}
