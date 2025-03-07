import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:github_sign_in/github_sign_in.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devio/constants/assets.dart';
import 'package:devio/blocs/auth/auth_cubit.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;

  const AuthScreen({
    super.key,
    required this.isLogin,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isLoading = false;
  var _socialLoading = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      context.go('/llm');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Authentication failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _socialLoading = 'google');
    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.signInWithGoogle();

      // Only navigate if the state is authenticated
      if (!mounted) return;
      final state = authCubit.state;
      state.maybeWhen(
        authenticated: (uid, displayName, email) => context.go('/llm'),
        error: (message) => _showError(message),
        orElse: () {},
      );
    } catch (e) {
      if (mounted) {
        _showError('Google Sign In Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _socialLoading = '');
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _socialLoading = 'apple');
    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.signInWithApple();

      // Only navigate if the state is authenticated
      if (!mounted) return;
      final state = authCubit.state;
      state.maybeWhen(
        authenticated: (uid, displayName, email) => context.go('/llm'),
        error: (message) => _showError(message),
        orElse: () {},
      );
    } catch (e) {
      if (mounted) {
        _showError('Apple sign in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _socialLoading = '');
    }
  }

  Future<void> _signInWithGithub() async {
    setState(() => _socialLoading = 'github');
    try {
      final GitHubSignIn gitHubSignIn = GitHubSignIn(
        clientId: const String.fromEnvironment('GITHUB_CLIENT_ID'),
        clientSecret: const String.fromEnvironment('GITHUB_CLIENT_SECRET'),
        redirectUrl: const String.fromEnvironment('GITHUB_REDIRECT_URL'),
      );

      final result = await gitHubSignIn.signIn(context);
      if (result.status == GitHubSignInResultStatus.ok) {
        final githubAuthCredential =
            GithubAuthProvider.credential(result.token!);
        await FirebaseAuth.instance.signInWithCredential(githubAuthCredential);
        if (!mounted) return;
        context.go('/llm');
      }
    } catch (e) {
      _showError('GitHub sign in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _socialLoading = '');
    }
  }

  void _showError(String message) {
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
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isLoading,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.8),
                  theme.colorScheme.primary.withOpacity(0.2),
                ],
              ),
            ),
          ),
          // Animated circles in the background
          Positioned(
            right: -100,
            top: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.primary.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Center(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.asset(
                                AppAssets.logo,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            widget.isLogin
                                ? 'Welcome Back!'
                                : 'Join the Future of Development',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isLogin
                                ? 'Sign in to continue your development journey'
                                : 'Create an account to start building amazing apps',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Email field with icon
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: _validateEmail,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password field with icon
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: Icon(Icons.lock_outline),
                                border: InputBorder.none,
                              ),
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              validator: _validatePassword,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(widget.isLogin
                                    ? 'Login'
                                    : 'Create Account'),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.google,
                            label: 'Continue with Google',
                            onPressed: _signInWithGoogle,
                            isLoading: _socialLoading == 'google',
                            color: Colors.red,
                          ),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.apple,
                            label: 'Continue with Apple',
                            onPressed: _signInWithApple,
                            isLoading: _socialLoading == 'apple',
                            color: Colors.black,
                          ),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.github,
                            label: 'Continue with GitHub',
                            onPressed: _signInWithGithub,
                            isLoading: _socialLoading == 'github',
                            color: Colors.black,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go(
                              '/auth',
                              extra: {
                                'mode': widget.isLogin ? 'signup' : 'login'
                              },
                            ),
                            child: Text(
                              widget.isLogin
                                  ? 'Don\'t have an account? Sign up'
                                  : 'Already have an account? Login',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
