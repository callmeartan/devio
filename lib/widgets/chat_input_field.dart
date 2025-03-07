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

    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            children: [
              if (selectedImageBytes != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(12),
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
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
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
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              style: theme.textTheme.bodyLarge,
                              enabled: !isWaitingForAiResponse,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.image_outlined,
                            color: selectedImageBytes != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          onPressed:
                              isWaitingForAiResponse ? null : onPickImage,
                          tooltip: 'Add image',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.picture_as_pdf,
                            color: selectedDocument != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          onPressed:
                              isWaitingForAiResponse ? null : onPickDocument,
                          tooltip: 'Add PDF document',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: isWaitingForAiResponse ? null : onSendMessage,
                      tooltip: 'Send message',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
