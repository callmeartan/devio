import 'package:flutter/material.dart';

import '../features/llm/models/model_capabilities.dart';

class CompactModelIndicator extends StatelessWidget {
  final String? selectedModel;
  final ModelCapabilities capabilities;
  final bool showModelSelection;
  final VoidCallback onTap;
  final String Function(String) getModelDisplayName;

  const CompactModelIndicator({
    super.key,
    required this.selectedModel,
    required this.capabilities,
    required this.showModelSelection,
    required this.onTap,
    required this.getModelDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              capabilities.supportsVision
                  ? Icons.image_search_outlined
                  : Icons.smart_toy_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: Text(
                  selectedModel != null
                      ? getModelDisplayName(selectedModel!)
                      : 'Select Model',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (selectedModel != null) ...[
              Tooltip(
                message: capabilities.supportsVision
                    ? 'Vision model: text and image input'
                    : 'Text model: text input only',
                child: Icon(
                  capabilities.supportsVision
                      ? Icons.visibility_outlined
                      : Icons.text_fields_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              if (capabilities.supportsToolUse) ...[
                Tooltip(
                  message: 'Tool-use capable model',
                  child: Icon(
                    Icons.handyman_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (capabilities.supportsReasoning) ...[
                Tooltip(
                  message: 'Reasoning-capable model',
                  child: Icon(
                    Icons.psychology_alt_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
            Icon(
              showModelSelection
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
