import 'package:devio/features/llm/cubit/llm_state.dart';
import 'package:devio/features/llm/models/llm_response.dart';

/// Extension to add maybeWhen and whenOrNull functionality to LlmState
extension LlmStateExtensions on LlmState {
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
    final stateString = toString();

    if (stateString.startsWith('LlmState.initial') && initial != null) {
      return initial();
    } else if (stateString.startsWith('LlmState.loading') && loading != null) {
      return loading();
    } else if (stateString.startsWith('LlmState.success') && success != null) {
      final dynamic self = this;
      return success(self.response as LlmResponse);
    } else if (stateString.startsWith('LlmState.streaming') &&
        streaming != null) {
      final dynamic self = this;
      return streaming(response: self.response as LlmResponse);
    } else if (stateString.startsWith('LlmState.loaded') && loaded != null) {
      final dynamic self = this;
      return loaded(response: self.response as LlmResponse);
    } else if (stateString.startsWith('LlmState.error') && error != null) {
      final dynamic self = this;
      return error(self.message as String);
    } else if (stateString.startsWith('LlmState.modelSwitching') &&
        modelSwitching != null) {
      final dynamic self = this;
      return modelSwitching(
        fromModel: self.fromModel as String,
        toModel: self.toModel as String,
        attempt: self.attempt as int,
      );
    }

    return orElse();
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
    final stateString = toString();

    if (stateString.startsWith('LlmState.initial') && initial != null) {
      return initial();
    } else if (stateString.startsWith('LlmState.loading') && loading != null) {
      return loading();
    } else if (stateString.startsWith('LlmState.success') && success != null) {
      final dynamic self = this;
      return success(self.response as LlmResponse);
    } else if (stateString.startsWith('LlmState.streaming') &&
        streaming != null) {
      final dynamic self = this;
      return streaming(response: self.response as LlmResponse);
    } else if (stateString.startsWith('LlmState.loaded') && loaded != null) {
      final dynamic self = this;
      return loaded(response: self.response as LlmResponse);
    } else if (stateString.startsWith('LlmState.error') && error != null) {
      final dynamic self = this;
      return error(self.message as String);
    } else if (stateString.startsWith('LlmState.modelSwitching') &&
        modelSwitching != null) {
      final dynamic self = this;
      return modelSwitching(
        fromModel: self.fromModel as String,
        toModel: self.toModel as String,
        attempt: self.attempt as int,
      );
    }

    return null;
  }
}
