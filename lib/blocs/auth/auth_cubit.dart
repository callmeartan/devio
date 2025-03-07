import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:devio/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'auth_cubit.freezed.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthCubit(
      {FirebaseAuth? auth,
      GoogleSignIn? googleSignIn,
      FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              clientId: defaultTargetPlatform == TargetPlatform.iOS
                  ? DefaultFirebaseOptions.currentPlatform.iosClientId
                  : null,
            ),
        _firestore = firestore ?? FirebaseFirestore.instance,
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
      developer
          .log('Anonymous sign in successful: ${userCredential.user?.uid}');
      emit(AuthState.authenticated(
        uid: userCredential.user?.uid ?? '',
        displayName: userCredential.user?.displayName,
        email: userCredential.user?.email,
      ));
    } on FirebaseAuthException catch (e) {
      developer
          .log('Firebase Auth Error in AuthCubit: ${e.code} - ${e.message}');
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
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

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
        // Store name from Apple Sign In if it's the first time (when name is provided)
        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          final displayName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();

          // Store in Firebase Auth
          await user.updateDisplayName(displayName);

          // Store in Firestore for future reference
          await _firestore.collection('users').doc(user.uid).set({
            'displayName': displayName,
            'email': user.email,
            'lastSignInTime': FieldValue.serverTimestamp(),
            'provider': 'apple.com',
          }, SetOptions(merge: true));
        } else {
          // Try to get the stored name from Firestore if not provided by Apple
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists && userDoc.data()?['displayName'] != null) {
            final storedDisplayName = userDoc.data()?['displayName'] as String;
            if (user.displayName == null || user.displayName!.isEmpty) {
              await user.updateDisplayName(storedDisplayName);
            }
          }
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

  Future<void> updateProfile({String? displayName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user found');
      }

      // Update display name in Firebase Auth if provided
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      // Update user data in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName ?? user.displayName,
        'email': user.email,
        'lastSignInTime': FieldValue.serverTimestamp(),
        'provider': user.providerData.first.providerId,
      }, SetOptions(merge: true));

      // Update state with new user data
      emit(AuthState.authenticated(
        uid: user.uid,
        displayName: displayName ?? user.displayName,
        email: user.email,
      ));
    } catch (e) {
      developer.log('Error updating profile: $e');
      emit(AuthState.error(e.toString()));
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    emit(const AuthState.loading());
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userId = user.uid;
        // Get the provider data before deleting
        final providers = user.providerData.map((e) => e.providerId).toList();

        // First, delete all user data from Firestore
        try {
          await _deleteAllUserData(userId);
          developer.log('Successfully deleted all user data from Firestore');
        } catch (e) {
          developer.log('Error deleting Firestore data: $e');
          // Continue with account deletion even if Firestore deletion fails
        }

        // Then try to delete the auth account
        try {
          await user.delete();
        } catch (e) {
          if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
            // Handle different providers
            if (providers.contains('apple.com')) {
              // Reauthenticate with Apple
              final appleCredential =
                  await SignInWithApple.getAppleIDCredential(
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
            } else if (providers.contains('google.com')) {
              // Reauthenticate with Google
              final googleUser = await _googleSignIn.signIn();
              if (googleUser == null)
                throw Exception('Google sign in was cancelled');

              final googleAuth = await googleUser.authentication;
              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );

              await user.reauthenticateWithCredential(credential);
            }

            // Try deleting all data again after reauthentication
            await _deleteAllUserData(userId);
            // Try deleting account again after reauthentication
            await user.delete();
          } else {
            rethrow;
          }
        }

        // Sign out and clean up after successful deletion
        await _googleSignIn.signOut();
        await _auth.signOut();

        // Emit unauthenticated state for proper redirection
        emit(const AuthState.unauthenticated());
      } else {
        emit(const AuthState.error('No user found to delete'));
      }
    } catch (e) {
      developer.log('Error deleting account: $e');
      emit(AuthState.error(e.toString()));
      rethrow;
    }
  }

  // Helper method to delete all user data
  Future<void> _deleteAllUserData(String userId) async {
    final batch = _firestore.batch();

    // Delete user document
    batch.delete(_firestore.collection('users').doc(userId));

    // Delete user's chats
    final userChats = await _firestore
        .collection('chats')
        .where('senderId', isEqualTo: userId)
        .get();
    for (var doc in userChats.docs) {
      batch.delete(doc.reference);
    }

    // Delete user's chat metadata
    final userChatMetadata = await _firestore
        .collection('chat_metadata')
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in userChatMetadata.docs) {
      batch.delete(doc.reference);
    }

    // Commit all deletions
    await batch.commit();
  }
}
