import 'package:flutter/material.dart';

class DrawerMenuItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool showLeadingBackground;
  final bool showTrailingIcon;
  final bool isSelected;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.showLeadingBackground = true,
    this.showTrailingIcon = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (showLeadingBackground)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: icon,
              )
            else
              icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showTrailingIcon)
              Icon(
                Icons.more_vert,
                size: 20,
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
} 