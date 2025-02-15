import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:developer' as developer;

part 'auth_cubit.freezed.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthCubit({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(const AuthState.error('Google sign in was cancelled'));
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        // Update user profile if name is empty
        if (user.displayName?.isEmpty ?? true) {
          await user.updateDisplayName(googleUser.displayName);
        }
        
        emit(AuthState.authenticated(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
        ));
      }
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
} 