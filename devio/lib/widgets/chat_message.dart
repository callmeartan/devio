import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

class ChatMessage extends StatelessWidget {
  final Message message;

  const ChatMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.isUserMessage;
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Text(
                'AI',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUserMessage
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      color: isUserMessage ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeFormat.format(message.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isUserMessage
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (isUserMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: const Icon(
                Icons.person_outline,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 