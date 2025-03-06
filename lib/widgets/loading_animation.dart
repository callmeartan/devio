import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoadingAnimation extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showRefreshIndicator;

  const LoadingAnimation({
    super.key,
    this.onTap,
    this.showRefreshIndicator = true,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _scaleController;
  late final AnimationController _opacityController;
  
  final List<AnimationController> _dotControllers = [];
  final int numberOfDots = 3;

  @override
  void initState() {
    super.initState();
    
    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Opacity animation
    _opacityController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize dot animations
    for (int i = 0; i < numberOfDots; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 600 + (i * 200)),
        vsync: this,
      )..repeat(reverse: true);
      _dotControllers.add(controller);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _opacityController.dispose();
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main rotating circle with AI icon
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating circle
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 8,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Inner pulsing circle with AI icon
            ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(_scaleController),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        // Animated dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(numberOfDots, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedBuilder(
                animation: _dotControllers[index],
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -4 * _dotControllers[index].value),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withOpacity(0.6 + (0.4 * _dotControllers[index].value)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        // Loading text with fade animation
        FadeTransition(
          opacity: Tween<double>(
            begin: 0.6,
            end: 1.0,
          ).animate(_opacityController),
          child: Text(
            'Tap anywhere to start chatting',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );

    if (widget.showRefreshIndicator) {
      content = RefreshIndicator(
        onRefresh: () async {
          // Add a small delay to make the refresh feel more natural
          await Future.delayed(const Duration(milliseconds: 500));
          if (widget.onTap != null) {
            widget.onTap!();
          }
        },
        displacement: 40,
        strokeWidth: 3,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: content,
              ),
            ),
          ],
        ),
      );
    } else {
      content = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    
    return Center(child: content);
  }
} 