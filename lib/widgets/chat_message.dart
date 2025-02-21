import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool showMetrics;
  final VoidCallback? onMetricsToggle;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.showMetrics = false,
    this.onMetricsToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = !message.isAI;

    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 32 : 0,
        right: isUser ? 0 : 32,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.senderName ?? 'AI Assistant',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onLongPress: () => _showMessageOptions(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy message'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: message.content));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            if (!message.isAI && onMetricsToggle != null)
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('Toggle metrics'),
                onTap: () {
                  Navigator.pop(context);
                  onMetricsToggle?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
} 