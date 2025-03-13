part of 'auth_cubit.dart';

// Simple implementation without Freezed
abstract class AuthState {
  const AuthState();

  // Factory constructors
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({
    required String uid,
    String? displayName,
    String? email,
  }) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;

  // Helper method to replace Freezed's maybeWhen
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String uid, String? displayName, String? email)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is _Initial && initial != null) {
      return initial();
    } else if (this is _Loading && loading != null) {
      return loading();
    } else if (this is _Authenticated && authenticated != null) {
      final state = this as _Authenticated;
      return authenticated(state.uid, state.displayName, state.email);
    } else if (this is _Unauthenticated && unauthenticated != null) {
      return unauthenticated();
    } else if (this is _Error && error != null) {
      return error((this as _Error).message);
    } else {
      return orElse();
    }
  }

  // Helper method to replace Freezed's whenOrNull
  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String uid, String? displayName, String? email)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
  }) {
    if (this is _Initial && initial != null) {
      return initial();
    } else if (this is _Loading && loading != null) {
      return loading();
    } else if (this is _Authenticated && authenticated != null) {
      final state = this as _Authenticated;
      return authenticated(state.uid, state.displayName, state.email);
    } else if (this is _Unauthenticated && unauthenticated != null) {
      return unauthenticated();
    } else if (this is _Error && error != null) {
      return error((this as _Error).message);
    } else {
      return null;
    }
  }
}

// State implementations
class _Initial extends AuthState {
  const _Initial();
}

class _Loading extends AuthState {
  const _Loading();
}

class _Authenticated extends AuthState {
  final String uid;
  final String? displayName;
  final String? email;

  const _Authenticated({
    required this.uid,
    this.displayName,
    this.email,
  });
}

class _Unauthenticated extends AuthState {
  const _Unauthenticated();
}

class _Error extends AuthState {
  final String message;

  const _Error(this.message);
}
