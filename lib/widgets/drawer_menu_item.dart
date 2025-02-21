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
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
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
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}

class DrawerMenuItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool showLeadingBackground;
  final bool showTrailingIcon;
  final bool isSelected;
  final bool isPinned;
  final Function(String) onPin;
  final Function(String) onUnpin;
  final Function(String) onDelete;
  final Function(String, String) onRename;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    required this.onPin,
    required this.onUnpin,
    required this.onDelete,
    required this.onRename,
    this.showLeadingBackground = true,
    this.showTrailingIcon = false,
    this.isSelected = false,
    this.isPinned = false,
  });

  void _showOptionsDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Chat Options',
          style: theme.textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              title: Text(
                isPinned ? 'Unpin chat' : 'Pin chat',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (isPinned) {
                  onUnpin(title);
                } else {
                  onPin(title);
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              title: Text(
                'Rename chat',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete chat',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Rename Chat',
          style: theme.textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != title) {
                onRename(title, newTitle);
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Delete Chat',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              onDelete(title);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isSelected
        ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showOptionsDialog(context),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (showLeadingBackground)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
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
            if (isPinned)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.push_pin,
                  size: 16,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                ),
              ),
            if (showTrailingIcon)
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
} 