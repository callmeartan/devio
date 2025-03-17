import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/llm/cubit/llm_cubit.dart';

enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  error,
}

class ConnectionStatusBanner extends StatelessWidget {
  final ConnectionStatus status;
  final String? message;
  final VoidCallback? onTap;

  const ConnectionStatusBanner({
    super.key,
    required this.status,
    this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String statusText;

    switch (status) {
      case ConnectionStatus.connected:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        statusText = 'Connected';
      case ConnectionStatus.connecting:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.sync;
        statusText = 'Connecting';
      case ConnectionStatus.disconnected:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.cloud_off;
        statusText = 'Disconnected';
      case ConnectionStatus.error:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.error_outline;
        statusText = 'Connection Error';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (message != null)
                      Text(
                        message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: textColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Factory constructor to create a banner based on connection test result
  static Future<ConnectionStatusBanner> fromConnectionTest(
    BuildContext context, {
    required VoidCallback onTap,
  }) async {
    final llmCubit = context.read<LlmCubit>();
    final result = await llmCubit.testConnection();

    if (result['status'] == 'connected') {
      return ConnectionStatusBanner(
        status: ConnectionStatus.connected,
        message: 'Ollama v${result['version']} on ${llmCubit.customOllamaIp}',
        onTap: onTap,
      );
    } else {
      return ConnectionStatusBanner(
        status: ConnectionStatus.error,
        message: result['error'] ?? 'Failed to connect to Ollama server',
        onTap: onTap,
      );
    }
  }
}
