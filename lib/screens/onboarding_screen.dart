import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ollama_connection_guide.dart';

class OnboardingScreen extends StatefulWidget {
  static const String routeName = '/onboarding';

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;
  bool _isLastPage = false;
  bool _showConnectionSetup = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
        _isLastPage = _currentPage == _totalPages - 1;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);

    if (!mounted) return;

    if (_showConnectionSetup) {
      // Stay on the page but show connection setup
      setState(() {
        _showConnectionSetup = true;
      });
    } else {
      // Navigate to home screen
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_showConnectionSetup) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Connect to Ollama'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () {
                context.go('/');
              },
              child: const Text('Skip'),
            ),
          ],
        ),
        body: OllamaConnectionGuide(
          onConnectionSuccess: () {
            context.go('/');
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                children: [
                  _buildWelcomePage(theme),
                  _buildFeaturesPage(theme),
                  _buildSetupPage(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  Row(
                    children: List.generate(
                      _totalPages,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),

                  // Next/Get Started button
                  FilledButton(
                    onPressed: () {
                      if (_isLastPage) {
                        setState(() {
                          _showConnectionSetup = true;
                        });
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(_isLastPage ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to DevIO',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your AI-powered development assistant',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Get help with coding, debugging, and learning new technologies',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(ThemeData theme) {
    final features = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'AI Chat Assistant',
        'description': 'Get answers to your development questions',
      },
      {
        'icon': Icons.code,
        'title': 'Code Generation',
        'description': 'Generate code snippets and examples',
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'title': 'Local Processing',
        'description': 'Your data stays on your devices with Ollama',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Key Features',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            feature['description'] as String,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSetupPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Connect to Ollama',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'DevIO uses Ollama to run AI models locally on your computer',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSetupStep(
                  theme,
                  icon: Icons.download_outlined,
                  title: 'Install Ollama',
                  description: 'Download and install Ollama on your computer',
                ),
                const SizedBox(height: 16),
                _buildSetupStep(
                  theme,
                  icon: Icons.play_arrow_outlined,
                  title: 'Start Ollama Server',
                  description: 'Run Ollama with network access enabled',
                ),
                const SizedBox(height: 16),
                _buildSetupStep(
                  theme,
                  icon: Icons.link_outlined,
                  title: 'Connect DevIO',
                  description: 'Enter your computer\'s IP address in settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStep(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
