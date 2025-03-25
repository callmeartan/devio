import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/auth/auth_cubit.dart';
import 'package:devio/utils/state_extension_helpers.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    _displayNameController = TextEditingController(
      text: authState.maybeWhen(
        authenticated: (_, displayName, __) => displayName,
        orElse: () => '',
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get the current user
      final authState = context.read<AuthCubit>().state;
      final userId = authState.maybeWhen(
        authenticated: (uid, _, __) => uid,
        orElse: () => null,
      );

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update the display name
      await context.read<AuthCubit>().updateProfile(
            displayName: _displayNameController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with gradient
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.withOpacity(0.3)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.check,
                            color: isDark
                                ? Colors.white
                                : theme.colorScheme.primary,
                          ),
                          onPressed: _saveChanges,
                        ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.grey.shade800,
                            Colors.grey.shade900,
                            Colors.black,
                          ]
                        : [
                            theme.colorScheme.primary.withOpacity(0.7),
                            theme.colorScheme.surface,
                          ],
                    stops: isDark ? [0.0, 0.5, 1.0] : [0.0, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle pattern overlay
                    Opacity(
                      opacity: 0.05,
                      child: CustomPaint(
                        painter: WavePatternPainter(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                    // Title
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Text(
                          'Edit Profile',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form Content
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 20,
                            color: isDark
                                ? Colors.white
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Personal Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Fields Container
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Display Name Field
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: TextFormField(
                              controller: _displayNameController,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Display Name',
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.7)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                ),
                                hintText: 'Enter your display name',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.7)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your display name';
                                }
                                return null;
                              },
                            ),
                          ),

                          Divider(
                            height: 1,
                            indent: 56,
                            color: isDark
                                ? Colors.grey.shade800
                                : theme.colorScheme.outline.withOpacity(0.1),
                          ),

                          // Email Field (Read-only)
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: TextFormField(
                                  initialValue: state.maybeWhen(
                                    authenticated: (_, __, email) => email,
                                    orElse: () => '',
                                  ),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.7)
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                  ),
                                  readOnly: true,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.7)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.7)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Help Text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900.withOpacity(0.5)
                            : theme.colorScheme.surface.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: isDark
                                ? Colors.white.withOpacity(0.7)
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your display name is visible to other users in the app.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? Colors.white.withOpacity(0.7)
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Wave pattern painter for the background
class WavePatternPainter extends CustomPainter {
  final Color color;

  WavePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final path = Path();

    // Create wave pattern
    for (int i = 0; i < 10; i++) {
      final y = size.height * 0.1 + (i * size.height * 0.08);
      path.moveTo(0, y);

      for (int j = 0; j < 10; j++) {
        final x1 = size.width * (j * 0.1 + 0.05);
        final x2 = size.width * (j * 0.1 + 0.1);
        path.quadraticBezierTo(
          x1,
          y + (i % 2 == 0 ? 10 : -10),
          x2,
          y,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
