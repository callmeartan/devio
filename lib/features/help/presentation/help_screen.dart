import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            theme,
            title: 'Quick Help',
            children: [
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search Help Articles'),
                subtitle: const Text('Find answers to common questions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Implement help article search
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: const Text('Chat with Support'),
                subtitle: const Text('Get help from our team'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'support@devio.app',
                    queryParameters: {
                      'subject': 'Support Request: DevIO App',
                    },
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  }
                },
              ),
            ],
          ),
          
          _buildSection(
            theme,
            title: 'Frequently Asked Questions',
            children: [
              ExpansionTile(
                title: const Text('How do I get started?'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'To get started with DevIO, simply select an AI model from the dropdown menu and start chatting. You can ask questions about programming, get code reviews, or discuss software architecture.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('Which AI models are supported?'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'DevIO supports various Ollama models including deepseek-coder, llama2, and more. Each model has different capabilities and specializations. You can install additional models using the Ollama CLI.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('How do I view performance metrics?'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Performance metrics are displayed below each AI response. Click the "Performance Metrics" button to view detailed information about processing time, token counts, and generation speeds.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          _buildSection(
            theme,
            title: 'Contact Us',
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email Support'),
                subtitle: const Text('support@devio.app'),
                onTap: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'support@devio.app',
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Report a Bug'),
                subtitle: const Text('Help us improve'),
                onTap: () {
                  // Navigate to bug report form
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('Submit Feedback'),
                subtitle: const Text('Share your thoughts'),
                onTap: () {
                  // Navigate to feedback form
                },
              ),
            ],
          ),
          
          _buildSection(
            theme,
            title: 'Resources',
            children: [
              ListTile(
                leading: const Icon(Icons.library_books_outlined),
                title: const Text('Documentation'),
                subtitle: const Text('Read our guides and tutorials'),
                onTap: () async {
                  final Uri docsUri = Uri.parse('https://docs.devio.app');
                  if (await canLaunchUrl(docsUri)) {
                    await launchUrl(docsUri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Video Tutorials'),
                subtitle: const Text('Watch how-to guides'),
                onTap: () async {
                  final Uri videosUri = Uri.parse('https://devio.app/tutorials');
                  if (await canLaunchUrl(videosUri)) {
                    await launchUrl(videosUri);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
} 