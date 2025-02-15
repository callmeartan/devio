import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),
                      const Text(
                        'Habitly',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Get it done. Build the habit.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Join thousands of people who use Habitly to transform their lives, one habit at a time.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(flex: 3),
                      _SocialButton(
                        text: 'Continue with Apple',
                        icon: FontAwesomeIcons.apple,
                        onPressed: authProvider.isLoading
                            ? null
                            : () => authProvider.signInWithApple(),
                      ),
                      const SizedBox(height: 12),
                      _SocialButton(
                        text: 'Continue with Google',
                        icon: FontAwesomeIcons.google,
                        onPressed: authProvider.isLoading
                            ? null
                            : () => authProvider.signInWithGoogle(),
                      ),
                      const SizedBox(height: 12),
                      _SocialButton(
                        text: 'Continue with GitHub',
                        icon: FontAwesomeIcons.github,
                        onPressed: authProvider.isLoading
                            ? null
                            : () => authProvider.signInWithGitHub(context),
                      ),
                      const SizedBox(height: 12),
                      _SocialButton(
                        text: 'Continue Offline',
                        icon: Icons.offline_bolt_outlined,
                        isOutlined: true,
                        onPressed: authProvider.isLoading
                            ? null
                            : () => authProvider.signInOffline(),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'By continuing, you agree to our Terms and Privacy Policy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                  if (authProvider.isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isOutlined;

  const _SocialButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : Colors.white,
        foregroundColor: isOutlined ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isOutlined ? const BorderSide(color: Colors.white) : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 