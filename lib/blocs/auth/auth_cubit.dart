import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:devio/firebase_options.dart';

part 'auth_cubit.freezed.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthCubit({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: defaultTargetPlatform == TargetPlatform.iOS 
              ? DefaultFirebaseOptions.currentPlatform.iosClientId
              : null,
        ),
        super(const AuthState.initial()) {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        emit(AuthState.authenticated(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
        ));
      } else {
        emit(const AuthState.unauthenticated());
      }
    });
  }

  Future<void> signInAnonymously() async {
    emit(const AuthState.loading());
    try {
      developer.log('Attempting anonymous sign in through AuthCubit...');
      final userCredential = await _auth.signInAnonymously();
      developer.log('Anonymous sign in successful: ${userCredential.user?.uid}');
      emit(AuthState.authenticated(
        uid: userCredential.user?.uid ?? '',
        displayName: userCredential.user?.displayName,
        email: userCredential.user?.email,
      ));
    } on FirebaseAuthException catch (e) {
      developer.log('Firebase Auth Error in AuthCubit: ${e.code} - ${e.message}');
      emit(AuthState.error(e.message ?? 'Anonymous sign in failed'));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _auth.currentUser;
      emit(AuthState.authenticated(
        uid: user?.uid ?? '',
        displayName: user?.displayName,
        email: user?.email,
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthState.error(e.message ?? 'An error occurred'));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _auth.currentUser;
      emit(AuthState.authenticated(
        uid: user?.uid ?? '',
        displayName: user?.displayName,
        email: user?.email,
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthState.error(e.message ?? 'An error occurred'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());
    try {
      developer.log('Starting Google Sign In process...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        developer.log('Google Sign In was cancelled by user');
        emit(const AuthState.error('Sign in cancelled'));
        return;
      }

      developer.log('Getting Google Auth tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        developer.log('Failed to get Google Auth tokens');
        emit(const AuthState.error('Failed to get authentication tokens'));
        return;
      }

      developer.log('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      developer.log('Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        developer.log('Successfully signed in with Google: ${user.email}');
        if (user.displayName?.isEmpty ?? true) {
          await user.updateDisplayName(googleUser.displayName);
        }
        
        emit(AuthState.authenticated(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
        ));
      } else {
        emit(const AuthState.error('Failed to get user information'));
      }
    } on FirebaseAuthException catch (e) {
      developer.log('Firebase Auth Error: ${e.code} - ${e.message}');
      emit(AuthState.error(e.message ?? 'Firebase authentication failed'));
    } catch (e) {
      developer.log('Google sign in error: $e');
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signInWithApple() async {
    emit(const AuthState.loading());
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      
      if (user != null) {
        // Update display name if provided and current is empty
        if ((user.displayName?.isEmpty ?? true) && 
            appleCredential.givenName != null) {
          final displayName = '${appleCredential.givenName} ${appleCredential.familyName}'.trim();
          await user.updateDisplayName(displayName);
        }
        
        emit(AuthState.authenticated(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
        ));
      }
    } catch (e) {
      developer.log('Apple sign in error: $e');
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> deleteAccount() async {
    emit(const AuthState.loading());
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get the provider data before deleting
        final providers = user.providerData.map((e) => e.providerId).toList();
        
        // Check if user needs to reauthenticate
        try {
          // Delete the user account
          await user.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            // Handle different providers
            if (providers.contains('apple.com')) {
              // Reauthenticate with Apple
              final appleCredential = await SignInWithApple.getAppleIDCredential(
                scopes: [
                  AppleIDAuthorizationScopes.email,
                  AppleIDAuthorizationScopes.fullName,
                ],
              );
              
              final oauthCredential = OAuthProvider('apple.com').credential(
                idToken: appleCredential.identityToken,
                accessToken: appleCredential.authorizationCode,
              );
              
              await user.reauthenticateWithCredential(oauthCredential);
              await user.delete();
            } else if (providers.contains('google.com')) {
              // Reauthenticate with Google
              final googleUser = await _googleSignIn.signIn();
              if (googleUser == null) throw Exception('Google sign in was cancelled');
              
              final googleAuth = await googleUser.authentication;
              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );
              
              await user.reauthenticateWithCredential(credential);
              await user.delete();
            } else {
              throw Exception('Please sign out and sign in again before deleting your account');
            }
          } else {
            throw Exception(e.message ?? 'Failed to delete account');
          }
        }
        
        // Sign out and clean up after successful deletion
        await _googleSignIn.signOut();
        await _auth.signOut();
        emit(const AuthState.unauthenticated());
      } else {
        emit(const AuthState.error('No user found to delete'));
      }
    } catch (e) {
      developer.log('Error deleting account: $e');
      emit(AuthState.error(e.toString()));
      rethrow; // Rethrow to handle in UI
    }
  }
} 