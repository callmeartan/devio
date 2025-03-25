import 'dart:developer' as dev;
import 'package:devio/blocs/auth/auth_cubit.dart';
import 'package:devio/features/llm/cubit/llm_state.dart';
import 'package:devio/features/llm/models/llm_response.dart';

/// Extension methods for AuthState to provide pattern matching functionality
extension AuthStateHelpers on AuthState {
  /// Executes the callback associated with current state type, or [orElse] if none match
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String uid, String? displayName, String? email)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    try {
      final stateString = toString();

      if (stateString.startsWith('AuthState.initial()') && initial != null) {
        return initial();
      } else if (stateString.startsWith('AuthState.loading()') &&
          loading != null) {
        return loading();
      } else if (stateString.startsWith('AuthState.authenticated') &&
          authenticated != null) {
        // Extract parameters from toString() if possible, otherwise fallback to dynamic access
        final dynamic self = this;
        String uid = '';
        String? displayName;
        String? email;

        try {
          uid = self.uid as String;
          displayName = self.displayName as String?;
          email = self.email as String?;
        } catch (e) {
          dev.log('Error extracting AuthState.authenticated fields: $e');
        }

        return authenticated(uid, displayName, email);
      } else if (stateString.startsWith('AuthState.unauthenticated()') &&
          unauthenticated != null) {
        return unauthenticated();
      } else if (stateString.startsWith('AuthState.error') && error != null) {
        // Extract message from toString() if possible, otherwise fallback to dynamic access
        String message = 'Unknown error';
        try {
          final dynamic self = this;
          message = self.message as String;
        } catch (e) {
          // Try to extract from toString()
          final regex = RegExp(r'AuthState.error\(message: (.*)\)');
          final match = regex.firstMatch(stateString);
          if (match != null && match.groupCount >= 1) {
            message = match.group(1) ?? message;
          }
          dev.log('Error extracting AuthState.error message: $e');
        }

        return error(message);
      }

      return orElse();
    } catch (e) {
      dev.log('Error in AuthState.maybeWhen: $e');
      return orElse();
    }
  }

  /// Executes the callback associated with current state type, or returns null if no match
  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String uid, String? displayName, String? email)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
  }) {
    try {
      final stateString = toString();

      if (stateString.startsWith('AuthState.initial()') && initial != null) {
        return initial();
      } else if (stateString.startsWith('AuthState.loading()') &&
          loading != null) {
        return loading();
      } else if (stateString.startsWith('AuthState.authenticated') &&
          authenticated != null) {
        // Extract parameters from toString() if possible, otherwise fallback to dynamic access
        final dynamic self = this;
        String uid = '';
        String? displayName;
        String? email;

        try {
          uid = self.uid as String;
          displayName = self.displayName as String?;
          email = self.email as String?;
        } catch (e) {
          dev.log('Error extracting AuthState.authenticated fields: $e');
        }

        return authenticated(uid, displayName, email);
      } else if (stateString.startsWith('AuthState.unauthenticated()') &&
          unauthenticated != null) {
        return unauthenticated();
      } else if (stateString.startsWith('AuthState.error') && error != null) {
        // Extract message from toString() if possible, otherwise fallback to dynamic access
        String message = 'Unknown error';
        try {
          final dynamic self = this;
          message = self.message as String;
        } catch (e) {
          // Try to extract from toString()
          final regex = RegExp(r'AuthState.error\(message: (.*)\)');
          final match = regex.firstMatch(stateString);
          if (match != null && match.groupCount >= 1) {
            message = match.group(1) ?? message;
          }
          dev.log('Error extracting AuthState.error message: $e');
        }

        return error(message);
      }

      return null;
    } catch (e) {
      dev.log('Error in AuthState.whenOrNull: $e');
      return null;
    }
  }
}

/// Extension methods for LlmState to provide pattern matching functionality
extension LlmStateHelpers on LlmState {
  /// Executes the callback associated with current state type, or [orElse] if none match
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(LlmResponse response)? success,
    T Function({required LlmResponse response})? streaming,
    T Function({required LlmResponse response})? loaded,
    T Function(String message)? error,
    T Function(
            {required String fromModel,
            required String toModel,
            required int attempt})?
        modelSwitching,
    required T Function() orElse,
  }) {
    try {
      final stateString = toString();

      if (stateString.startsWith('LlmState.initial()') && initial != null) {
        return initial();
      } else if (stateString.startsWith('LlmState.loading()') &&
          loading != null) {
        return loading();
      } else if (stateString.startsWith('LlmState.success') &&
          success != null) {
        // Access the response field through dynamic
        final dynamic self = this;
        LlmResponse? response;

        try {
          response = self.response as LlmResponse;
          return success(response);
        } catch (e) {
          dev.log('Error extracting LlmState.success response: $e');
          return orElse();
        }
      } else if (stateString.startsWith('LlmState.streaming') &&
          streaming != null) {
        // Access the response field through dynamic
        final dynamic self = this;
        LlmResponse? response;

        try {
          response = self.response as LlmResponse;
          return streaming(response: response);
        } catch (e) {
          dev.log('Error extracting LlmState.streaming response: $e');
          return orElse();
        }
      } else if (stateString.startsWith('LlmState.loaded') && loaded != null) {
        // Access the response field through dynamic
        final dynamic self = this;
        LlmResponse? response;

        try {
          response = self.response as LlmResponse;
          return loaded(response: response);
        } catch (e) {
          dev.log('Error extracting LlmState.loaded response: $e');
          return orElse();
        }
      } else if (stateString.startsWith('LlmState.error') && error != null) {
        // Access the message field through dynamic
        final dynamic self = this;
        String message = 'Unknown error';

        try {
          message = self.message as String;
        } catch (e) {
          // Try to extract from toString()
          final regex = RegExp(r'LlmState.error\(message: (.*)\)');
          final match = regex.firstMatch(stateString);
          if (match != null && match.groupCount >= 1) {
            message = match.group(1) ?? message;
          }
          dev.log('Error extracting LlmState.error message: $e');
        }

        return error(message);
      } else if (stateString.startsWith('LlmState.modelSwitching') &&
          modelSwitching != null) {
        // Access fields through dynamic
        final dynamic self = this;
        String fromModel = '';
        String toModel = '';
        int attempt = 0;

        try {
          fromModel = self.fromModel as String;
          toModel = self.toModel as String;
          attempt = self.attempt as int;
        } catch (e) {
          // Try to extract from toString()
          final regex = RegExp(
              r'LlmState.modelSwitching\(fromModel: (.*), toModel: (.*), attempt: (\d+)\)');
          final match = regex.firstMatch(stateString);
          if (match != null && match.groupCount >= 3) {
            fromModel = match.group(1) ?? fromModel;
            toModel = match.group(2) ?? toModel;
            attempt = int.tryParse(match.group(3) ?? '') ?? attempt;
          }
          dev.log('Error extracting LlmState.modelSwitching fields: $e');
        }

        return modelSwitching(
            fromModel: fromModel, toModel: toModel, attempt: attempt);
      }

      return orElse();
    } catch (e) {
      dev.log('Error in LlmState.maybeWhen: $e');
      return orElse();
    }
  }

  /// Executes the callback associated with current state type, or returns null if no match
  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(LlmResponse response)? success,
    T Function({required LlmResponse response})? streaming,
    T Function({required LlmResponse response})? loaded,
    T Function(String message)? error,
    T Function(
            {required String fromModel,
            required String toModel,
            required int attempt})?
        modelSwitching,
  }) {
    try {
      final stateString = toString();

      if (stateString.startsWith('LlmState.initial()') && initial != null) {
        return initial();
      } else if (stateString.startsWith('LlmState.loading()') &&
          loading != null) {
        return loading();
      } else if (stateString.startsWith('LlmState.success') &&
          success != null) {
        // Access the response field through dynamic
        final dynamic self = this;
        LlmResponse? response;

        try {
          response = self.response as LlmResponse;
          return success(response);
        } catch (e) {
          dev.log('Error extracting LlmState.success response: $e');
          return null;
        }
      } else if (stateString.startsWith('LlmState.streaming') &&
          streaming != null) {
        // Access the response field through dynamic
        final dynamic self = this;
        LlmResponse? response;

        try {
          response = self.response as LlmResponse;
          return streaming(response: response);
        } catch (e) {
          dev.log('Error extracting LlmState.streaming response: $e');
          return null;
        }
      } else if (stateString.startsWith('LlmState.loaded') && loaded != null) {
        // Access the response field through dynamic
        final dynamic self = this;
        LlmResponse? response;

        try {
          response = self.response as LlmResponse;
          return loaded(response: response);
        } catch (e) {
          dev.log('Error extracting LlmState.loaded response: $e');
          return null;
        }
      } else if (stateString.startsWith('LlmState.error') && error != null) {
        // Access the message field through dynamic
        final dynamic self = this;
        String message = 'Unknown error';

        try {
          message = self.message as String;
        } catch (e) {
          // Try to extract from toString()
          final regex = RegExp(r'LlmState.error\(message: (.*)\)');
          final match = regex.firstMatch(stateString);
          if (match != null && match.groupCount >= 1) {
            message = match.group(1) ?? message;
          }
          dev.log('Error extracting LlmState.error message: $e');
        }

        return error(message);
      } else if (stateString.startsWith('LlmState.modelSwitching') &&
          modelSwitching != null) {
        // Access fields through dynamic
        final dynamic self = this;
        String fromModel = '';
        String toModel = '';
        int attempt = 0;

        try {
          fromModel = self.fromModel as String;
          toModel = self.toModel as String;
          attempt = self.attempt as int;
        } catch (e) {
          // Try to extract from toString()
          final regex = RegExp(
              r'LlmState.modelSwitching\(fromModel: (.*), toModel: (.*), attempt: (\d+)\)');
          final match = regex.firstMatch(stateString);
          if (match != null && match.groupCount >= 3) {
            fromModel = match.group(1) ?? fromModel;
            toModel = match.group(2) ?? toModel;
            attempt = int.tryParse(match.group(3) ?? '') ?? attempt;
          }
          dev.log('Error extracting LlmState.modelSwitching fields: $e');
        }

        return modelSwitching(
            fromModel: fromModel, toModel: toModel, attempt: attempt);
      }

      return null;
    } catch (e) {
      dev.log('Error in LlmState.whenOrNull: $e');
      return null;
    }
  }
}
