import 'package:flutter/material.dart';

class DemoModeBanner extends StatelessWidget {
  final VoidCallback? onSetupTap;

  const DemoModeBanner({
    super.key,
    this.onSetupTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.science_outlined,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Demo Mode - Limited AI Functionality',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onSetupTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Setup',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
