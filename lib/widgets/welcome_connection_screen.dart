import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/llm/cubit/llm_cubit.dart';
import 'package:lottie/lottie.dart';

/// A welcoming screen that guides users through setting up their Ollama connection
/// instead of showing error messages.
class WelcomeConnectionScreen extends StatelessWidget {
  /// Optional callback when connection setup is complete
  final VoidCallback? onConnectionSetupComplete;

  const WelcomeConnectionScreen({
    super.key,
    this.onConnectionSetupComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with illustration
              _buildHeader(theme, isDark),
              const SizedBox(height: 24),

              // Setup instructions
              _buildInstructions(theme, isDark),
              const SizedBox(height: 32),

              // Connection setup button
              _buildConnectionButton(context, theme, isDark),
              const SizedBox(height: 16),

              // Learn more button
              _buildLearnMoreButton(context, theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Animated illustration
        SizedBox(
          height: 160,
          child: Lottie.asset(
            'assets/animations/connection_setup.json',
            // Fallback if animation doesn't exist
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.devices_other,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Main title
        Text(
          'Connect to Ollama',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle explanation
        Text(
          'DevIO works with your Ollama server to provide AI capabilities on your mobile device.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Getting Started:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildInstructionStep(
          theme,
          isDark,
          icon: Icons.computer,
          title: 'Install Ollama',
          description:
              'Download and install Ollama on your computer from ollama.ai',
        ),
        _buildInstructionStep(
          theme,
          isDark,
          icon: Icons.play_circle_outline,
          title: 'Start Ollama Server',
          description:
              'Run Ollama with the command: OLLAMA_HOST=0.0.0.0:11434 ollama serve',
        ),
        _buildInstructionStep(
          theme,
          isDark,
          icon: Icons.link,
          title: 'Connect',
          description:
              'Configure DevIO to connect to your Ollama server\'s IP address',
        ),
      ],
    );
  }

  Widget _buildInstructionStep(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton(
      BuildContext context, ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _showConnectionSetup(context),
        icon: const Icon(Icons.settings_ethernet),
        label: const Text('Set Up Connection'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLearnMoreButton(
      BuildContext context, ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLearnMore(context),
        icon: const Icon(Icons.help_outline),
        label: const Text('Learn More'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  void _showConnectionSetup(BuildContext context) {
    // Get the LLM Cubit to access connection methods
    final llmCubit = context.read<LlmCubit>();

    // Show the connection setup dialog (existing _showOllamaConfigDialog content)
    // This should be refactored to use a separate dialog widget
    // For now, we'll directly access the method in the LLM Chat Screen

    // TODO: Replace with a call to a separate connection wizard widget
    // This is a temporary solution
    Navigator.of(context).pop(); // Close the welcome screen if it's in a dialog

    // Call the callback if provided
    if (onConnectionSetupComplete != null) {
      onConnectionSetupComplete!();
    }
  }

  void _showLearnMore(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'About DevIO',
              style: theme.textTheme.titleLarge?.copyWith(
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
              Text(
                'DevIO is a client application that connects to Ollama, a local AI server running on your computer.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Why use Ollama with DevIO?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoItem(
                theme,
                isDark,
                icon: Icons.lock_outline,
                title: 'Privacy Focused',
                description:
                    'Your data stays on your devices and never leaves your network.',
              ),
              _buildInfoItem(
                theme,
                isDark,
                icon: Icons.speed,
                title: 'High Performance',
                description:
                    'Run powerful AI models with the computing resources of your computer.',
              ),
              _buildInfoItem(
                theme,
                isDark,
                icon: Icons.devices,
                title: 'Device Synergy',
                description:
                    'Use your mobile device to interact with AI running on your computer.',
              ),
              const SizedBox(height: 16),
              Text(
                'To use DevIO, you\'ll need to have Ollama installed and running on a computer on the same network as this device.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showConnectionSetup(context);
            },
            child: const Text('Set Up Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
