import 'package:flutter/material.dart';

class CompactModelIndicator extends StatelessWidget {
  final String? selectedModel;
  final bool showModelSelection;
  final VoidCallback onTap;
  final String Function(String) getModelDisplayName;

  const CompactModelIndicator({
    super.key,
    required this.selectedModel,
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
              Icons.smart_toy_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              selectedModel != null
                  ? getModelDisplayName(selectedModel!)
                  : 'Select Model',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
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
