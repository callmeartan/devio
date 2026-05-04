import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

class ChatInputField extends StatelessWidget {
  final TextEditingController messageController;
  final Uint8List? selectedImageBytes;
  final File? selectedDocument;
  final bool isWaitingForAiResponse;
  final String? selectedModel;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final VoidCallback onPickDocument;
  final VoidCallback onClearSelectedImage;
  final VoidCallback onClearSelectedDocument;

  const ChatInputField({
    super.key,
    required this.messageController,
    required this.isWaitingForAiResponse,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onPickDocument,
    required this.onClearSelectedImage,
    required this.onClearSelectedDocument,
    this.selectedImageBytes,
    this.selectedDocument,
    this.selectedModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.9);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 14 + MediaQuery.of(context).padding.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedImageBytes != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          selectedImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: theme.colorScheme.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          child: IconButton(
                            icon: Icon(Icons.close,
                                color: theme.colorScheme.onSurface),
                            onPressed: onClearSelectedImage,
                            tooltip: 'Remove image',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (selectedDocument != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          path.basename(selectedDocument!.path),
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: theme.colorScheme.onSurface),
                        onPressed: onClearSelectedDocument,
                        tooltip: 'Remove document',
                      ),
                    ],
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? 0.22 : 0.07,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask DevIO',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.78),
                          ),
                        ),
                        minLines: 1,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        enabled: !isWaitingForAiResponse,
                        onSubmitted: (_) {
                          if (!isWaitingForAiResponse) {
                            onSendMessage();
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _ComposerIconButton(
                            icon: Icons.image_outlined,
                            tooltip: 'Add image',
                            isActive: selectedImageBytes != null,
                            onPressed:
                                isWaitingForAiResponse ? null : onPickImage,
                          ),
                          const SizedBox(width: 4),
                          _ComposerIconButton(
                            icon: Icons.picture_as_pdf_outlined,
                            tooltip: 'Add PDF',
                            isActive: selectedDocument != null,
                            onPressed:
                                isWaitingForAiResponse ? null : onPickDocument,
                          ),
                          const Spacer(),
                          if (selectedModel != null) ...[
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest
                                      .withOpacity(0.68),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  selectedModel!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Material(
                            color: isWaitingForAiResponse
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_upward_rounded,
                                color: isWaitingForAiResponse
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.onPrimary,
                              ),
                              onPressed:
                                  isWaitingForAiResponse ? null : onSendMessage,
                              tooltip: 'Send',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback? onPressed;

  const _ComposerIconButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.secondary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: isActive
          ? theme.colorScheme.secondary.withOpacity(0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
