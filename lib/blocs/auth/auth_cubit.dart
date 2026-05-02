import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_cubit.freezed.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  static const String localUserId = 'local-user';
  static const String localDisplayName = 'Local User';

  String _displayName = localDisplayName;
  String? _email;

  AuthCubit()
      : super(const AuthState.authenticated(
          uid: localUserId,
          displayName: localDisplayName,
          email: null,
        ));

  Future<void> signInAnonymously() async {
    _emitLocalSession();
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _email = email;
    _emitLocalSession();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _email = email;
    _emitLocalSession();
  }

  Future<void> signInWithGoogle() async {
    developer.log('Google sign-in is disabled in local-first mode.');
    _emitLocalSession();
  }

  Future<void> signInWithApple() async {
    developer.log('Apple sign-in is disabled in local-first mode.');
    _emitLocalSession();
  }

  Future<void> signOut() async {
    developer.log('Sign-out requested in local-first mode; keeping session.');
    _emitLocalSession();
  }

  Future<void> updateProfile({String? displayName}) async {
    if (displayName != null && displayName.trim().isNotEmpty) {
      _displayName = displayName.trim();
    }
    _emitLocalSession();
  }

  Future<void> deleteAccount() async {
    developer
        .log('Local profile reset requested; clearing profile details only.');
    _displayName = localDisplayName;
    _email = null;
    _emitLocalSession();
  }

  void _emitLocalSession() {
    emit(AuthState.authenticated(
      uid: localUserId,
      displayName: _displayName,
      email: _email,
    ));
  }
}
