// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LlmResponse _$LlmResponseFromJson(Map<String, dynamic> json) => _LlmResponse(
      text: json['text'] as String,
      isError: json['isError'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      modelName: json['model_name'] as String?,
      totalDuration: (json['total_duration'] as num?)?.toDouble(),
      loadDuration: (json['load_duration'] as num?)?.toDouble(),
      promptEvalCount: (json['prompt_eval_count'] as num?)?.toInt(),
      promptEvalDuration: (json['prompt_eval_duration'] as num?)?.toDouble(),
      promptEvalRate: (json['prompt_eval_rate'] as num?)?.toDouble(),
      evalCount: (json['eval_count'] as num?)?.toInt(),
      evalDuration: (json['eval_duration'] as num?)?.toDouble(),
      evalRate: (json['eval_rate'] as num?)?.toDouble(),
      completionTokens: (json['completion_tokens'] as num?)?.toInt(),
      totalTokens: (json['total_tokens'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LlmResponseToJson(_LlmResponse instance) =>
    <String, dynamic>{
      'text': instance.text,
      'isError': instance.isError,
      'errorMessage': instance.errorMessage,
      'model_name': instance.modelName,
      'total_duration': instance.totalDuration,
      'load_duration': instance.loadDuration,
      'prompt_eval_count': instance.promptEvalCount,
      'prompt_eval_duration': instance.promptEvalDuration,
      'prompt_eval_rate': instance.promptEvalRate,
      'eval_count': instance.evalCount,
      'eval_duration': instance.evalDuration,
      'eval_rate': instance.evalRate,
      'completion_tokens': instance.completionTokens,
      'total_tokens': instance.totalTokens,
    };
