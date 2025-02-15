import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  final List<String> chatHistory;

  const AppDrawer({
    super.key,
    required this.chatHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 50),
          // Search and New Chat Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF343541) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.search,
                        size: 20,
                        color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.keyboard_command_key,
                        size: 16,
                        color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'K',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // New Chat Button
                InkWell(
                  onTap: () {
                    // Handle new chat
                    context.pop();
                    // Add logic to start new chat
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'New chat',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Chat History Section
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                return _ChatHistoryItem(
                  title: chatHistory[index],
                  onTap: () {
                    context.pop();
                    // Add logic to switch to this chat
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Profile Section
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isDark ? Colors.white : Colors.black,
              child: Icon(
                Icons.person_outline,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
            title: Text(
              'Profile',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              context.pop();
              context.push('/profile');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ChatHistoryItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ChatHistoryItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 20,
              color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
            ),
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
          ],
        ),
      ),
    );
  }
} 