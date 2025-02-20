import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/llm_response.dart';

part 'llm_state.freezed.dart';

@freezed
class LlmState with _$LlmState {
  const factory LlmState.initial() = _Initial;
  const factory LlmState.loading() = _Loading;
  const factory LlmState.success(LlmResponse response) = _Success;
  const factory LlmState.error(String message) = _Error;
} 