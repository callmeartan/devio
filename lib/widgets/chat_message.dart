import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

enum MessageRole {
  user,
  assistant,
  system,
}

class ChatMessage extends StatelessWidget {
  final String message;
  final MessageRole role;
  final DateTime timestamp;
  final bool showTimestamp;

  const ChatMessage({
    super.key,
    required this.message,
    required this.role,
    required this.timestamp,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = role == MessageRole.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: isUser 
            ? theme.scaffoldBackgroundColor
            : theme.colorScheme.surface,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              _buildAvatar(context),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: isDark ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                    if (!isUser) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildActionButton(
                            context,
                            icon: Icons.thumb_up_outlined,
                            tooltip: 'Like',
                            onPressed: () {},
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            context,
                            icon: Icons.thumb_down_outlined,
                            tooltip: 'Dislike',
                            onPressed: () {},
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            context,
                            icon: Icons.copy_outlined,
                            tooltip: 'Copy to clipboard',
                            onPressed: () => _copyToClipboard(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (role) {
      case MessageRole.user:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF5C5C5C) : const Color(0xFFEBEBEB),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.person,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF585858),
          ),
        );
      case MessageRole.assistant:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.smart_toy,
            size: 18,
            color: Colors.white,
          ),
        );
      case MessageRole.system:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.warning,
            size: 18,
            color: theme.colorScheme.error,
          ),
        );
    }
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark 
                  ? Colors.white.withOpacity(0.6)
                  : Colors.black.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final theme = Theme.of(context);
    
    await Clipboard.setData(ClipboardData(text: message));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Copied to clipboard'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 