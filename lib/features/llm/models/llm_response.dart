// Simple implementation without Freezed
class LlmResponse {
  final String text;
  final bool isError;
  final String? errorMessage;
  final String? modelName;
  final double? totalDuration;
  final double? loadDuration;
  final int? promptEvalCount;
  final double? promptEvalDuration;
  final double? promptEvalRate;
  final int? evalCount;
  final double? evalDuration;
  final double? evalRate;
  final int? completionTokens;
  final int? totalTokens;

  const LlmResponse({
    required this.text,
    this.isError = false,
    this.errorMessage,
    this.modelName,
    this.totalDuration,
    this.loadDuration,
    this.promptEvalCount,
    this.promptEvalDuration,
    this.promptEvalRate,
    this.evalCount,
    this.evalDuration,
    this.evalRate,
    this.completionTokens,
    this.totalTokens,
  });

  // Factory constructor for error responses
  factory LlmResponse.error(String message) {
    return LlmResponse(
      text: '',
      isError: true,
      errorMessage: message,
    );
  }

  // Copy with method
  LlmResponse copyWith({
    String? text,
    bool? isError,
    String? errorMessage,
    String? modelName,
    double? totalDuration,
    double? loadDuration,
    int? promptEvalCount,
    double? promptEvalDuration,
    double? promptEvalRate,
    int? evalCount,
    double? evalDuration,
    double? evalRate,
    int? completionTokens,
    int? totalTokens,
  }) {
    return LlmResponse(
      text: text ?? this.text,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      modelName: modelName ?? this.modelName,
      totalDuration: totalDuration ?? this.totalDuration,
      loadDuration: loadDuration ?? this.loadDuration,
      promptEvalCount: promptEvalCount ?? this.promptEvalCount,
      promptEvalDuration: promptEvalDuration ?? this.promptEvalDuration,
      promptEvalRate: promptEvalRate ?? this.promptEvalRate,
      evalCount: evalCount ?? this.evalCount,
      evalDuration: evalDuration ?? this.evalDuration,
      evalRate: evalRate ?? this.evalRate,
      completionTokens: completionTokens ?? this.completionTokens,
      totalTokens: totalTokens ?? this.totalTokens,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'is_error': isError,
      'error_message': errorMessage,
      'model_name': modelName,
      'total_duration': totalDuration,
      'load_duration': loadDuration,
      'prompt_eval_count': promptEvalCount,
      'prompt_eval_duration': promptEvalDuration,
      'prompt_eval_rate': promptEvalRate,
      'eval_count': evalCount,
      'eval_duration': evalDuration,
      'eval_rate': evalRate,
      'completion_tokens': completionTokens,
      'total_tokens': totalTokens,
    };
  }

  // Factory method to create from JSON
  factory LlmResponse.fromJson(Map<String, dynamic> json) {
    return LlmResponse(
      text: json['text'] as String,
      isError: json['is_error'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
      modelName: json['model_name'] as String?,
      totalDuration: json['total_duration'] as double?,
      loadDuration: json['load_duration'] as double?,
      promptEvalCount: json['prompt_eval_count'] as int?,
      promptEvalDuration: json['prompt_eval_duration'] as double?,
      promptEvalRate: json['prompt_eval_rate'] as double?,
      evalCount: json['eval_count'] as int?,
      evalDuration: json['eval_duration'] as double?,
      evalRate: json['eval_rate'] as double?,
      completionTokens: json['completion_tokens'] as int?,
      totalTokens: json['total_tokens'] as int?,
    );
  }
}
