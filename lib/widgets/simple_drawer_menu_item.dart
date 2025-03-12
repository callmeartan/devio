import 'package:flutter/material.dart';

class SimpleDrawerMenuItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool showLeadingBackground;
  final bool showTrailingIcon;

  const SimpleDrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.showLeadingBackground = true,
    this.showTrailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (showLeadingBackground)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: icon,
              )
            else
              icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showTrailingIcon)
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}
