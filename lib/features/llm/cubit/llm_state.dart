import '../models/llm_response.dart';

// Simple implementation without Freezed
abstract class LlmState {
  const LlmState();

  // Factory constructors
  const factory LlmState.initial() = _Initial;
  const factory LlmState.loading() = _Loading;
  const factory LlmState.success(LlmResponse response) = _Success;
  const factory LlmState.error(String message) = _Error;
  const factory LlmState.modelSwitching({
    required String fromModel,
    required String toModel,
    required int attempt,
  }) = _ModelSwitching;

  // Helper method to replace Freezed's maybeWhen
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(LlmResponse response)? success,
    T Function(String message)? error,
    T Function(String fromModel, String toModel, int attempt)? modelSwitching,
    required T Function() orElse,
  }) {
    if (this is _Initial && initial != null) {
      return initial();
    } else if (this is _Loading && loading != null) {
      return loading();
    } else if (this is _Success && success != null) {
      return success((this as _Success).response);
    } else if (this is _Error && error != null) {
      return error((this as _Error).message);
    } else if (this is _ModelSwitching && modelSwitching != null) {
      final state = this as _ModelSwitching;
      return modelSwitching(state.fromModel, state.toModel, state.attempt);
    } else {
      return orElse();
    }
  }
}

// State implementations
class _Initial extends LlmState {
  const _Initial();
}

class _Loading extends LlmState {
  const _Loading();
}

class _Success extends LlmState {
  final LlmResponse response;

  const _Success(this.response);
}

class _Error extends LlmState {
  final String message;

  const _Error(this.message);
}

class _ModelSwitching extends LlmState {
  final String fromModel;
  final String toModel;
  final int attempt;

  const _ModelSwitching({
    required this.fromModel,
    required this.toModel,
    required this.attempt,
  });
}
