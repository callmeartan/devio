import 'package:freezed_annotation/freezed_annotation.dart';

part 'llm_response.freezed.dart';
part 'llm_response.g.dart';

@freezed
abstract class LlmResponse with _$LlmResponse {
  const factory LlmResponse({
    required String text,
    @Default(false) bool isError,
    String? errorMessage,
    @JsonKey(name: 'model_name') String? modelName,
    @JsonKey(name: 'total_duration') double? totalDuration,
    @JsonKey(name: 'load_duration') double? loadDuration,
    @JsonKey(name: 'prompt_eval_count') int? promptEvalCount,
    @JsonKey(name: 'prompt_eval_duration') double? promptEvalDuration,
    @JsonKey(name: 'prompt_eval_rate') double? promptEvalRate,
    @JsonKey(name: 'eval_count') int? evalCount,
    @JsonKey(name: 'eval_duration') double? evalDuration,
    @JsonKey(name: 'eval_rate') double? evalRate,
    @JsonKey(name: 'completion_tokens') int? completionTokens,
    @JsonKey(name: 'total_tokens') int? totalTokens,

    // New fields for streaming
    @Default(false) @JsonKey(name: 'is_final') bool isFinal,
    @JsonKey(name: 'full_text') String? fullText,
  }) = _LlmResponse;

  factory LlmResponse.fromJson(Map<String, dynamic> json) =>
      _$LlmResponseFromJson(json);
}
