import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/llm_response.dart';

part 'llm_state.freezed.dart';

@freezed
abstract class LlmState with _$LlmState {
  const factory LlmState.initial() = _Initial;
  const factory LlmState.loading() = _Loading;
  const factory LlmState.success(LlmResponse response) = _Success;
  const factory LlmState.streaming({required LlmResponse response}) =
      _StreamingResponse;
  const factory LlmState.loaded({required LlmResponse response}) =
      _LoadedResponse;
  const factory LlmState.error(String message) = _Error;
  const factory LlmState.modelSwitching({
    required String fromModel,
    required String toModel,
    required int attempt,
  }) = _ModelSwitching;
}
