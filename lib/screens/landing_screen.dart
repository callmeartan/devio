import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devio/blocs/auth/auth_cubit.dart';
import 'package:devio/constants/assets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: (uid, displayName, email) => context.go('/llm'),
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText.rich(
                  TextSpan(
                    children: [
                      const WidgetSpan(
                        child: Icon(Icons.error_outline, color: Colors.white, size: 16),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: message),
                    ],
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background
            _AnimatedBackground(),
            
            // Floating code animation
            _FloatingCodeAnimation(),
            
            // Main content
            SafeArea(
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  constraints: BoxConstraints(
                    maxWidth: 480,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      
                      // Hero Section
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          AppAssets.logo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      Text(
                        'DevIO',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          letterSpacing: -1.5,
                          color: theme.colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 20),
                      Container(
                        constraints: BoxConstraints(maxWidth: 360),
                        child: Text(
                          'AI Development Assistant',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 80),
                      
                      // CTA Buttons
                      Container(
                        constraints: BoxConstraints(maxWidth: 360),
                        child: Column(
                          children: [
                            _GlowingButton(
                              onPressed: () => context.go('/auth', extra: {'mode': 'signup'}),
                              text: 'Get Started',
                            ),
                            
                            const SizedBox(height: 16),
                            
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: ElevatedButton(
                                onPressed: () => context.go('/auth', extra: {'mode': 'login'}),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: theme.colorScheme.primary,
                                  elevation: 0,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.background,
                theme.colorScheme.background,
                Colors.grey.shade100,
              ],
            ),
          ),
        ),
        ...List.generate(20, (index) => _ParticleEffect()),
      ],
    );
  }
}

class _FloatingCodeAnimation extends StatelessWidget {
  final List<String> codeSnippets = [
    'class DevIO {',
    '  final ai = true;',
    '}',
    'function optimize() {',
    '  return success;',
    '}',
    'async write() {',
    '  await code;',
    '}',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final random = math.Random();
    
    return Stack(
      children: List.generate(
        6,
        (index) {
          final left = random.nextDouble() * size.width;
          final top = random.nextDouble() * size.height;
          
          return Positioned(
            left: left,
            top: top,
            child: Text(
              codeSnippets[index % codeSnippets.length],
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.black38,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).move(
              duration: 8.seconds,
              begin: Offset(0, 0),
              end: Offset(0, -150),
            ).fadeIn(
              duration: 3.seconds,
            ).fadeOut(
              delay: 4.seconds,
              duration: 3.seconds,
            ),
          );
        },
      ),
    );
  }
}

class _ParticleEffect extends StatelessWidget {
  final random = math.Random();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Positioned(
      left: random.nextDouble() * size.width,
      top: random.nextDouble() * size.height,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black12,
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(),
      ).scaleXY(
        duration: Duration(seconds: 3 + random.nextInt(2)),
        begin: 0.5,
        end: 1.5,
      ).fadeIn(
        duration: Duration(seconds: 4),
      ).fadeOut(
        duration: Duration(seconds: 4),
      ).move(
        begin: Offset.zero,
        end: Offset(
          random.nextDouble() * 40 - 20,
          random.nextDouble() * 40 - 20,
        ),
        duration: Duration(seconds: 4 + random.nextInt(2)),
      ),
    );
  }
}

class _GlowingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const _GlowingButton({
    required this.onPressed,
    required this.text,
  });

  @override
  State<_GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<_GlowingButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovered ? 0.2 : 0.1),
              blurRadius: isHovered ? 20 : 10,
              spreadRadius: isHovered ? 2 : 0,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
} 