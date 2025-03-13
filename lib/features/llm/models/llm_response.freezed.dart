// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'llm_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LlmResponse _$LlmResponseFromJson(Map<String, dynamic> json) {
  return _LlmResponse.fromJson(json);
}

/// @nodoc
mixin _$LlmResponse {
  String get text => throw _privateConstructorUsedError;
  bool get isError => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  @JsonKey(name: 'model_name')
  String? get modelName => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_duration')
  double? get totalDuration => throw _privateConstructorUsedError;
  @JsonKey(name: 'load_duration')
  double? get loadDuration => throw _privateConstructorUsedError;
  @JsonKey(name: 'prompt_eval_count')
  int? get promptEvalCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'prompt_eval_duration')
  double? get promptEvalDuration => throw _privateConstructorUsedError;
  @JsonKey(name: 'prompt_eval_rate')
  double? get promptEvalRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'eval_count')
  int? get evalCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'eval_duration')
  double? get evalDuration => throw _privateConstructorUsedError;
  @JsonKey(name: 'eval_rate')
  double? get evalRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'completion_tokens')
  int? get completionTokens => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_tokens')
  int? get totalTokens => throw _privateConstructorUsedError;

  /// Serializes this LlmResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LlmResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LlmResponseCopyWith<LlmResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LlmResponseCopyWith<$Res> {
  factory $LlmResponseCopyWith(
          LlmResponse value, $Res Function(LlmResponse) then) =
      _$LlmResponseCopyWithImpl<$Res, LlmResponse>;
  @useResult
  $Res call(
      {String text,
      bool isError,
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
      @JsonKey(name: 'total_tokens') int? totalTokens});
}

/// @nodoc
class _$LlmResponseCopyWithImpl<$Res, $Val extends LlmResponse>
    implements $LlmResponseCopyWith<$Res> {
  _$LlmResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LlmResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? isError = null,
    Object? errorMessage = freezed,
    Object? modelName = freezed,
    Object? totalDuration = freezed,
    Object? loadDuration = freezed,
    Object? promptEvalCount = freezed,
    Object? promptEvalDuration = freezed,
    Object? promptEvalRate = freezed,
    Object? evalCount = freezed,
    Object? evalDuration = freezed,
    Object? evalRate = freezed,
    Object? completionTokens = freezed,
    Object? totalTokens = freezed,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      isError: null == isError
          ? _value.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      modelName: freezed == modelName
          ? _value.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDuration: freezed == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      loadDuration: freezed == loadDuration
          ? _value.loadDuration
          : loadDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalCount: freezed == promptEvalCount
          ? _value.promptEvalCount
          : promptEvalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      promptEvalDuration: freezed == promptEvalDuration
          ? _value.promptEvalDuration
          : promptEvalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalRate: freezed == promptEvalRate
          ? _value.promptEvalRate
          : promptEvalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      evalCount: freezed == evalCount
          ? _value.evalCount
          : evalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      evalDuration: freezed == evalDuration
          ? _value.evalDuration
          : evalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      evalRate: freezed == evalRate
          ? _value.evalRate
          : evalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      completionTokens: freezed == completionTokens
          ? _value.completionTokens
          : completionTokens // ignore: cast_nullable_to_non_nullable
              as int?,
      totalTokens: freezed == totalTokens
          ? _value.totalTokens
          : totalTokens // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LlmResponseImplCopyWith<$Res>
    implements $LlmResponseCopyWith<$Res> {
  factory _$$LlmResponseImplCopyWith(
          _$LlmResponseImpl value, $Res Function(_$LlmResponseImpl) then) =
      __$$LlmResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String text,
      bool isError,
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
      @JsonKey(name: 'total_tokens') int? totalTokens});
}

/// @nodoc
class __$$LlmResponseImplCopyWithImpl<$Res>
    extends _$LlmResponseCopyWithImpl<$Res, _$LlmResponseImpl>
    implements _$$LlmResponseImplCopyWith<$Res> {
  __$$LlmResponseImplCopyWithImpl(
      _$LlmResponseImpl _value, $Res Function(_$LlmResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of LlmResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? isError = null,
    Object? errorMessage = freezed,
    Object? modelName = freezed,
    Object? totalDuration = freezed,
    Object? loadDuration = freezed,
    Object? promptEvalCount = freezed,
    Object? promptEvalDuration = freezed,
    Object? promptEvalRate = freezed,
    Object? evalCount = freezed,
    Object? evalDuration = freezed,
    Object? evalRate = freezed,
    Object? completionTokens = freezed,
    Object? totalTokens = freezed,
  }) {
    return _then(_$LlmResponseImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      isError: null == isError
          ? _value.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      modelName: freezed == modelName
          ? _value.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDuration: freezed == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      loadDuration: freezed == loadDuration
          ? _value.loadDuration
          : loadDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalCount: freezed == promptEvalCount
          ? _value.promptEvalCount
          : promptEvalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      promptEvalDuration: freezed == promptEvalDuration
          ? _value.promptEvalDuration
          : promptEvalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalRate: freezed == promptEvalRate
          ? _value.promptEvalRate
          : promptEvalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      evalCount: freezed == evalCount
          ? _value.evalCount
          : evalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      evalDuration: freezed == evalDuration
          ? _value.evalDuration
          : evalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      evalRate: freezed == evalRate
          ? _value.evalRate
          : evalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      completionTokens: freezed == completionTokens
          ? _value.completionTokens
          : completionTokens // ignore: cast_nullable_to_non_nullable
              as int?,
      totalTokens: freezed == totalTokens
          ? _value.totalTokens
          : totalTokens // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LlmResponseImpl implements _LlmResponse {
  const _$LlmResponseImpl(
      {required this.text,
      this.isError = false,
      this.errorMessage,
      @JsonKey(name: 'model_name') this.modelName,
      @JsonKey(name: 'total_duration') this.totalDuration,
      @JsonKey(name: 'load_duration') this.loadDuration,
      @JsonKey(name: 'prompt_eval_count') this.promptEvalCount,
      @JsonKey(name: 'prompt_eval_duration') this.promptEvalDuration,
      @JsonKey(name: 'prompt_eval_rate') this.promptEvalRate,
      @JsonKey(name: 'eval_count') this.evalCount,
      @JsonKey(name: 'eval_duration') this.evalDuration,
      @JsonKey(name: 'eval_rate') this.evalRate,
      @JsonKey(name: 'completion_tokens') this.completionTokens,
      @JsonKey(name: 'total_tokens') this.totalTokens});

  factory _$LlmResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LlmResponseImplFromJson(json);

  @override
  final String text;
  @override
  @JsonKey()
  final bool isError;
  @override
  final String? errorMessage;
  @override
  @JsonKey(name: 'model_name')
  final String? modelName;
  @override
  @JsonKey(name: 'total_duration')
  final double? totalDuration;
  @override
  @JsonKey(name: 'load_duration')
  final double? loadDuration;
  @override
  @JsonKey(name: 'prompt_eval_count')
  final int? promptEvalCount;
  @override
  @JsonKey(name: 'prompt_eval_duration')
  final double? promptEvalDuration;
  @override
  @JsonKey(name: 'prompt_eval_rate')
  final double? promptEvalRate;
  @override
  @JsonKey(name: 'eval_count')
  final int? evalCount;
  @override
  @JsonKey(name: 'eval_duration')
  final double? evalDuration;
  @override
  @JsonKey(name: 'eval_rate')
  final double? evalRate;
  @override
  @JsonKey(name: 'completion_tokens')
  final int? completionTokens;
  @override
  @JsonKey(name: 'total_tokens')
  final int? totalTokens;

  @override
  String toString() {
    return 'LlmResponse(text: $text, isError: $isError, errorMessage: $errorMessage, modelName: $modelName, totalDuration: $totalDuration, loadDuration: $loadDuration, promptEvalCount: $promptEvalCount, promptEvalDuration: $promptEvalDuration, promptEvalRate: $promptEvalRate, evalCount: $evalCount, evalDuration: $evalDuration, evalRate: $evalRate, completionTokens: $completionTokens, totalTokens: $totalTokens)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LlmResponseImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.isError, isError) || other.isError == isError) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.modelName, modelName) ||
                other.modelName == modelName) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration) &&
            (identical(other.loadDuration, loadDuration) ||
                other.loadDuration == loadDuration) &&
            (identical(other.promptEvalCount, promptEvalCount) ||
                other.promptEvalCount == promptEvalCount) &&
            (identical(other.promptEvalDuration, promptEvalDuration) ||
                other.promptEvalDuration == promptEvalDuration) &&
            (identical(other.promptEvalRate, promptEvalRate) ||
                other.promptEvalRate == promptEvalRate) &&
            (identical(other.evalCount, evalCount) ||
                other.evalCount == evalCount) &&
            (identical(other.evalDuration, evalDuration) ||
                other.evalDuration == evalDuration) &&
            (identical(other.evalRate, evalRate) ||
                other.evalRate == evalRate) &&
            (identical(other.completionTokens, completionTokens) ||
                other.completionTokens == completionTokens) &&
            (identical(other.totalTokens, totalTokens) ||
                other.totalTokens == totalTokens));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      text,
      isError,
      errorMessage,
      modelName,
      totalDuration,
      loadDuration,
      promptEvalCount,
      promptEvalDuration,
      promptEvalRate,
      evalCount,
      evalDuration,
      evalRate,
      completionTokens,
      totalTokens);

  /// Create a copy of LlmResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LlmResponseImplCopyWith<_$LlmResponseImpl> get copyWith =>
      __$$LlmResponseImplCopyWithImpl<_$LlmResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LlmResponseImplToJson(
      this,
    );
  }
}

abstract class _LlmResponse implements LlmResponse {
  const factory _LlmResponse(
      {required final String text,
      final bool isError,
      final String? errorMessage,
      @JsonKey(name: 'model_name') final String? modelName,
      @JsonKey(name: 'total_duration') final double? totalDuration,
      @JsonKey(name: 'load_duration') final double? loadDuration,
      @JsonKey(name: 'prompt_eval_count') final int? promptEvalCount,
      @JsonKey(name: 'prompt_eval_duration') final double? promptEvalDuration,
      @JsonKey(name: 'prompt_eval_rate') final double? promptEvalRate,
      @JsonKey(name: 'eval_count') final int? evalCount,
      @JsonKey(name: 'eval_duration') final double? evalDuration,
      @JsonKey(name: 'eval_rate') final double? evalRate,
      @JsonKey(name: 'completion_tokens') final int? completionTokens,
      @JsonKey(name: 'total_tokens')
      final int? totalTokens}) = _$LlmResponseImpl;

  factory _LlmResponse.fromJson(Map<String, dynamic> json) =
      _$LlmResponseImpl.fromJson;

  @override
  String get text;
  @override
  bool get isError;
  @override
  String? get errorMessage;
  @override
  @JsonKey(name: 'model_name')
  String? get modelName;
  @override
  @JsonKey(name: 'total_duration')
  double? get totalDuration;
  @override
  @JsonKey(name: 'load_duration')
  double? get loadDuration;
  @override
  @JsonKey(name: 'prompt_eval_count')
  int? get promptEvalCount;
  @override
  @JsonKey(name: 'prompt_eval_duration')
  double? get promptEvalDuration;
  @override
  @JsonKey(name: 'prompt_eval_rate')
  double? get promptEvalRate;
  @override
  @JsonKey(name: 'eval_count')
  int? get evalCount;
  @override
  @JsonKey(name: 'eval_duration')
  double? get evalDuration;
  @override
  @JsonKey(name: 'eval_rate')
  double? get evalRate;
  @override
  @JsonKey(name: 'completion_tokens')
  int? get completionTokens;
  @override
  @JsonKey(name: 'total_tokens')
  int? get totalTokens;

  /// Create a copy of LlmResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LlmResponseImplCopyWith<_$LlmResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
