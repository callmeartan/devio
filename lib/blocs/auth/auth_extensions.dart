import 'package:devio/blocs/auth/auth_cubit.dart';

/// Extension to add maybeWhen and whenOrNull functionality to AuthState
extension AuthStateExtensions on AuthState {
  /// Executes the callback associated with current state type, or [orElse] if none match
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String uid, String? displayName, String? email)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    final stateString = toString();

    if (stateString.startsWith('AuthState.initial') && initial != null) {
      return initial();
    } else if (stateString.startsWith('AuthState.loading') && loading != null) {
      return loading();
    } else if (stateString.startsWith('AuthState.authenticated') &&
        authenticated != null) {
      // Access fields via dynamic
      final dynamic self = this;
      return authenticated(
        self.uid as String,
        self.displayName as String?,
        self.email as String?,
      );
    } else if (stateString.startsWith('AuthState.unauthenticated') &&
        unauthenticated != null) {
      return unauthenticated();
    } else if (stateString.startsWith('AuthState.error') && error != null) {
      // Access message via dynamic
      final dynamic self = this;
      return error(self.message as String);
    }

    return orElse();
  }

  /// Executes the callback associated with current state type, or returns null if no match
  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String uid, String? displayName, String? email)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
  }) {
    final stateString = toString();

    if (stateString.startsWith('AuthState.initial') && initial != null) {
      return initial();
    } else if (stateString.startsWith('AuthState.loading') && loading != null) {
      return loading();
    } else if (stateString.startsWith('AuthState.authenticated') &&
        authenticated != null) {
      // Access fields via dynamic
      final dynamic self = this;
      return authenticated(
        self.uid as String,
        self.displayName as String?,
        self.email as String?,
      );
    } else if (stateString.startsWith('AuthState.unauthenticated') &&
        unauthenticated != null) {
      return unauthenticated();
    } else if (stateString.startsWith('AuthState.error') && error != null) {
      // Access message via dynamic
      final dynamic self = this;
      return error(self.message as String);
    }

    return null;
  }
}
