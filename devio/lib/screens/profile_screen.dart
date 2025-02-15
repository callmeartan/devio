import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(
                Icons.person_outline,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'John Doe', // TODO: Replace with actual user name
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'john.doe@example.com', // TODO: Replace with actual email
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              title: 'Current Progress',
              content: 'Planning Phase',
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Project Status',
              content: 'Ideation & Research',
              icon: Icons.lightbulb_outline,
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Next Steps',
              content: 'Define core features and user stories',
              icon: Icons.assignment_outlined,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => context.pushReplacement('/'),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 