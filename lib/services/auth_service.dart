import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:github_sign_in/github_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      // Here you would typically create a user session or store the credentials
      print('Google Sign in successful: ${googleUser.email}');
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS && !kIsWeb) {
      throw UnsupportedError('Apple Sign In is only supported on iOS, macOS, and Web');
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      // Here you would typically create a user session or store the credentials
      print('Apple Sign in successful: ${credential.email}');
    } catch (e) {
      print('Error signing in with Apple: $e');
      rethrow;
    }
  }

  Future<void> signInWithGitHub(BuildContext context, String clientId, String clientSecret) async {
    try {
      final GitHubSignIn gitHubSignIn = GitHubSignIn(
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUrl: 'your-redirect-url',
      );

      final result = await gitHubSignIn.signIn(context);
      if (result.status == GitHubSignInResultStatus.ok) {
        // Here you would typically create a user session or store the credentials
        print('GitHub Sign in successful: ${result.token}');
      }
    } catch (e) {
      print('Error signing in with GitHub: $e');
      rethrow;
    }
  }

  void signInOffline() {
    // Implement offline mode logic here
    print('Signed in offline');
  }
} 