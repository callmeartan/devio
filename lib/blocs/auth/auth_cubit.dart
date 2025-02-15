import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

part 'auth_cubit.freezed.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;

  AuthCubit({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        super(const AuthState.initial());

  Future<void> signInAnonymously() async {
    emit(const AuthState.loading());
    try {
      developer.log('Attempting anonymous sign in through AuthCubit...');
      final userCredential = await _auth.signInAnonymously();
      developer.log('Anonymous sign in successful: ${userCredential.user?.uid}');
      emit(const AuthState.authenticated());
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
      emit(const AuthState.authenticated());
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
      emit(const AuthState.authenticated());
    } on FirebaseAuthException catch (e) {
      emit(AuthState.error(e.message ?? 'An error occurred'));
    }
  }

  Future<void> signOut() async {
    emit(const AuthState.loading());
    try {
      await _auth.signOut();
      emit(const AuthState.unauthenticated());
    } on FirebaseAuthException catch (e) {
      emit(AuthState.error(e.message ?? 'An error occurred'));
    }
  }

  void checkAuthStatus() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        emit(const AuthState.authenticated());
      } else {
        emit(const AuthState.unauthenticated());
      }
    });
  }
} 