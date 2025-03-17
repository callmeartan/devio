import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/llm/cubit/llm_cubit.dart';

class ReconnectionPrompt extends StatefulWidget {
  final String? errorMessage;
  final VoidCallback? onSetupTap;
  final VoidCallback? onRetrySuccess;

  const ReconnectionPrompt({
    super.key,
    this.errorMessage,
    this.onSetupTap,
    this.onRetrySuccess,
  });

  @override
  State<ReconnectionPrompt> createState() => _ReconnectionPromptState();
}

class _ReconnectionPromptState extends State<ReconnectionPrompt> {
  bool _isRetrying = false;

  Future<void> _retryConnection() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      final llmCubit = context.read<LlmCubit>();
      final result = await llmCubit.testConnection();

      if (result['status'] == 'connected') {
        if (widget.onRetrySuccess != null) {
          widget.onRetrySuccess!();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection failed: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connection Lost',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.errorMessage ??
                'Unable to connect to Ollama. Please check your connection settings.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.onSetupTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                child: const Text('Setup'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isRetrying ? null : _retryConnection,
                icon: _isRetrying
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
