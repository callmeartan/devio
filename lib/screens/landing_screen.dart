import 'package:devio/blocs/auth/auth_cubit.dart';
import 'package:devio/constants/assets.dart';
import 'package:devio/utils/state_extension_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: (uid, displayName, email) => context.go('/llm'),
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText.rich(
                  TextSpan(
                    children: [
                      const WidgetSpan(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: message),
                    ],
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBrandLockup(theme),
                    const SizedBox(height: 30),
                    _buildChatSurface(theme),
                    const SizedBox(height: 22),
                    _buildProviderRail(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLockup(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Image.asset(AppAssets.logo),
        ),
        const SizedBox(width: 14),
        Text(
          'DevIO',
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildChatSurface(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.26 : 0.08,
            ),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildWindowDot(const Color(0xFFDD6B4D)),
              const SizedBox(width: 6),
              _buildWindowDot(const Color(0xFFE2B45F)),
              const SizedBox(width: 6),
              _buildWindowDot(const Color(0xFF6EA37A)),
              const Spacer(),
              IconButton(
                onPressed: () => context.go('/llm'),
                icon: const Icon(Icons.open_in_new_rounded),
                tooltip: 'Open DevIO',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'What are we building?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/llm'),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Open'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRail(ThemeData theme) {
    final providers = [
      (Icons.computer_rounded, 'Ollama', 'localhost:11434'),
      (Icons.dns_rounded, 'LM Studio', 'localhost:1234'),
      (Icons.hub_rounded, 'OpenAI-compatible', 'api.openai.com'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: providers
          .map(
            (provider) => Container(
              width: 210,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.72),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(provider.$1, size: 20),
                  const SizedBox(width: 10),
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

  Widget _buildWindowDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
