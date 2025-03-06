import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:devio/constants/assets.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<IntroPage> _pages = [
    IntroPage(
      image: 'assets/images/intro_1.png',
      title: 'AI-Powered Development',
      subtitle: 'Write better code faster with intelligent suggestions and real-time assistance',
      gradient: [
        Colors.black,
        Colors.black87,
        Colors.black54,
      ],
      illustration: Icons.code_rounded,
    ),
    IntroPage(
      image: 'assets/images/intro_2.png',
      title: 'Smart Code Analysis',
      subtitle: 'Get instant feedback on code quality, performance, and security',
      gradient: [
        Colors.black87,
        Colors.black54,
        Colors.black38,
      ],
      illustration: Icons.analytics_rounded,
    ),
    IntroPage(
      image: 'assets/images/intro_3.png',
      title: 'Seamless Integration',
      subtitle: 'Works with your existing workflow and favorite development tools',
      gradient: [
        Colors.black54,
        Colors.black38,
        Colors.black26,
      ],
      illustration: Icons.integration_instructions_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient animation
          AnimatedContainer(
            duration: 600.ms,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _pages[_currentPage].gradient,
              ),
            ),
          ),
          
          // Floating particles
          ...List.generate(
            20,
            (index) => _IntroParticle(
              color: _pages[_currentPage].gradient[0],
            ),
          ),
          
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _IntroPageView(
                      page: page,
                      isActive: _currentPage == index,
                    );
                  },
                ),
              ),
              
              // Navigation dots and buttons
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicator
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: 300.ms,
                            margin: EdgeInsets.only(right: 8),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                _currentPage == index ? 0.9 : 0.3,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      
                      // Next/Get Started button
                      _IntroButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: 600.ms,
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // Set the flag that user has seen intro
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setBool('has_seen_intro', true);
                            });
                            context.go('/landing');
                          }
                        },
                        text: _currentPage < _pages.length - 1
                            ? 'Next'
                            : 'Get Started',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class IntroPage {
  final String image;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData illustration;

  const IntroPage({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.illustration,
  });
}

class _IntroPageView extends StatelessWidget {
  final IntroPage page;
  final bool isActive;

  const _IntroPageView({
    required this.page,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Icon(
            page.illustration,
            size: 180,
            color: Colors.white.withOpacity(0.9),
          ).animate(
            target: isActive ? 1 : 0,
          ).fade(
            duration: 600.ms,
          ).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            page.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate(
            target: isActive ? 1 : 0,
          ).fadeIn(
            delay: 200.ms,
            duration: 600.ms,
          ).moveY(
            begin: 20,
            end: 0,
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            page.subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ).animate(
            target: isActive ? 1 : 0,
          ).fadeIn(
            delay: 400.ms,
            duration: 600.ms,
          ).moveY(
            begin: 20,
            end: 0,
          ),
        ],
      ),
    );
  }
}

class _IntroButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const _IntroButton({
    required this.onPressed,
    required this.text,
  });

  @override
  State<_IntroButton> createState() => _IntroButtonState();
}

class _IntroButtonState extends State<_IntroButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovered ? 0.3 : 0.1),
              blurRadius: isHovered ? 20 : 10,
              spreadRadius: isHovered ? 2 : 0,
            ),
          ],
        ),
        child: TextButton(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            widget.text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroParticle extends StatelessWidget {
  final Color color;
  final random = math.Random();

  _IntroParticle({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Positioned(
      left: random.nextDouble() * size.width,
      top: random.nextDouble() * size.height,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(),
      ).scaleXY(
        duration: Duration(seconds: 2 + random.nextInt(2)),
        begin: 0.5,
        end: 1.5,
      ).fadeIn(
        duration: Duration(seconds: 2),
      ).fadeOut(
        delay: Duration(seconds: 1),
        duration: Duration(seconds: 2),
      ).move(
        begin: const Offset(0, 0),
        end: Offset(
          random.nextDouble() * 100 - 50,
          random.nextDouble() * 100 - 50,
        ),
      ),
    );
  }
} 