import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../features/llm/models/llm_response.dart';
import '../widgets/performance_metrics.dart';

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
    final content = message.content.trim();

    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 32 : 0,
        right: isUser ? 0 : 16,
        bottom: 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxBubbleWidth = constraints.maxWidth * (isUser ? 0.78 : 0.86);

          return Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
              Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: GestureDetector(
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
                      child: isUser
                          ? SelectableText(
                              content,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : _AssistantMessageContent(content: content),
                    ),
                  ),
                ),
              ),
              if (!isUser && message.totalDuration != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: PerformanceMetrics(
                      response: LlmResponse(
                        text: content,
                        totalDuration: message.totalDuration,
                        loadDuration: message.loadDuration,
                        promptEvalCount: message.promptEvalCount,
                        promptEvalDuration: message.promptEvalDuration,
                        promptEvalRate: message.promptEvalRate,
                        evalCount: message.evalCount,
                        evalDuration: message.evalDuration,
                        evalRate: message.evalRate,
                      ),
                      isExpanded: showMetrics,
                      onToggle: onMetricsToggle ?? () {},
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final isUser = !message.isAI;

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
            if (!isUser && message.totalDuration != null)
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

class _AssistantMessageContent extends StatelessWidget {
  final String content;

  const _AssistantMessageContent({
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final parts = _splitCodeFences(content);
    if (parts.length == 1 && !parts.first.isCode) {
      return SelectableText(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        if (part.isCode) {
          return _CodeBlock(
            code: part.text,
            language: part.language,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SelectableText(
            part.text.trim(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        );
      }).toList(),
    );
  }

  List<_MessagePart> _splitCodeFences(String text) {
    final parts = <_MessagePart>[];
    final pattern = RegExp(r'```([A-Za-z0-9_+\-.#]*)\n([\s\S]*?)```');
    var index = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > index) {
        final plainText = text.substring(index, match.start);
        if (plainText.trim().isNotEmpty) {
          parts.add(_MessagePart.text(plainText));
        }
      }

      parts.add(_MessagePart.code(
        match.group(2) ?? '',
        language: match.group(1)?.trim(),
      ));
      index = match.end;
    }

    if (index < text.length) {
      final plainText = text.substring(index);
      if (plainText.trim().isNotEmpty) {
        parts.add(_MessagePart.text(plainText));
      }
    }

    if (parts.isEmpty) {
      parts.add(_MessagePart.text(text));
    }
    return parts;
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final String? language;

  const _CodeBlock({
    required this.code,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language == null || language!.isEmpty ? 'code' : language!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy code',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code.trim()));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code.trimRight(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagePart {
  final String text;
  final String? language;
  final bool isCode;

  const _MessagePart._({
    required this.text,
    required this.isCode,
    this.language,
  });

  factory _MessagePart.text(String text) {
    return _MessagePart._(text: text, isCode: false);
  }

  factory _MessagePart.code(String text, {String? language}) {
    return _MessagePart._(
      text: text,
      language: language,
      isCode: true,
    );
  }
}
