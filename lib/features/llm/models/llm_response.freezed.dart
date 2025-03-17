// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'llm_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LlmResponse {
  String get text;
  bool get isError;
  String? get errorMessage;
  @JsonKey(name: 'model_name')
  String? get modelName;
  @JsonKey(name: 'total_duration')
  double? get totalDuration;
  @JsonKey(name: 'load_duration')
  double? get loadDuration;
  @JsonKey(name: 'prompt_eval_count')
  int? get promptEvalCount;
  @JsonKey(name: 'prompt_eval_duration')
  double? get promptEvalDuration;
  @JsonKey(name: 'prompt_eval_rate')
  double? get promptEvalRate;
  @JsonKey(name: 'eval_count')
  int? get evalCount;
  @JsonKey(name: 'eval_duration')
  double? get evalDuration;
  @JsonKey(name: 'eval_rate')
  double? get evalRate;
  @JsonKey(name: 'completion_tokens')
  int? get completionTokens;
  @JsonKey(name: 'total_tokens')
  int? get totalTokens;

  /// Create a copy of LlmResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LlmResponseCopyWith<LlmResponse> get copyWith =>
      _$LlmResponseCopyWithImpl<LlmResponse>(this as LlmResponse, _$identity);

  /// Serializes this LlmResponse to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LlmResponse &&
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

  @override
  String toString() {
    return 'LlmResponse(text: $text, isError: $isError, errorMessage: $errorMessage, modelName: $modelName, totalDuration: $totalDuration, loadDuration: $loadDuration, promptEvalCount: $promptEvalCount, promptEvalDuration: $promptEvalDuration, promptEvalRate: $promptEvalRate, evalCount: $evalCount, evalDuration: $evalDuration, evalRate: $evalRate, completionTokens: $completionTokens, totalTokens: $totalTokens)';
  }
}

/// @nodoc
abstract mixin class $LlmResponseCopyWith<$Res> {
  factory $LlmResponseCopyWith(
          LlmResponse value, $Res Function(LlmResponse) _then) =
      _$LlmResponseCopyWithImpl;
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
class _$LlmResponseCopyWithImpl<$Res> implements $LlmResponseCopyWith<$Res> {
  _$LlmResponseCopyWithImpl(this._self, this._then);

  final LlmResponse _self;
  final $Res Function(LlmResponse) _then;

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
    return _then(_self.copyWith(
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      isError: null == isError
          ? _self.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      modelName: freezed == modelName
          ? _self.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDuration: freezed == totalDuration
          ? _self.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      loadDuration: freezed == loadDuration
          ? _self.loadDuration
          : loadDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalCount: freezed == promptEvalCount
          ? _self.promptEvalCount
          : promptEvalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      promptEvalDuration: freezed == promptEvalDuration
          ? _self.promptEvalDuration
          : promptEvalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalRate: freezed == promptEvalRate
          ? _self.promptEvalRate
          : promptEvalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      evalCount: freezed == evalCount
          ? _self.evalCount
          : evalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      evalDuration: freezed == evalDuration
          ? _self.evalDuration
          : evalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      evalRate: freezed == evalRate
          ? _self.evalRate
          : evalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      completionTokens: freezed == completionTokens
          ? _self.completionTokens
          : completionTokens // ignore: cast_nullable_to_non_nullable
              as int?,
      totalTokens: freezed == totalTokens
          ? _self.totalTokens
          : totalTokens // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _LlmResponse implements LlmResponse {
  const _LlmResponse(
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
  factory _LlmResponse.fromJson(Map<String, dynamic> json) =>
      _$LlmResponseFromJson(json);

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

  /// Create a copy of LlmResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LlmResponseCopyWith<_LlmResponse> get copyWith =>
      __$LlmResponseCopyWithImpl<_LlmResponse>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LlmResponseToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LlmResponse &&
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

  @override
  String toString() {
    return 'LlmResponse(text: $text, isError: $isError, errorMessage: $errorMessage, modelName: $modelName, totalDuration: $totalDuration, loadDuration: $loadDuration, promptEvalCount: $promptEvalCount, promptEvalDuration: $promptEvalDuration, promptEvalRate: $promptEvalRate, evalCount: $evalCount, evalDuration: $evalDuration, evalRate: $evalRate, completionTokens: $completionTokens, totalTokens: $totalTokens)';
  }
}

/// @nodoc
abstract mixin class _$LlmResponseCopyWith<$Res>
    implements $LlmResponseCopyWith<$Res> {
  factory _$LlmResponseCopyWith(
          _LlmResponse value, $Res Function(_LlmResponse) _then) =
      __$LlmResponseCopyWithImpl;
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
class __$LlmResponseCopyWithImpl<$Res> implements _$LlmResponseCopyWith<$Res> {
  __$LlmResponseCopyWithImpl(this._self, this._then);

  final _LlmResponse _self;
  final $Res Function(_LlmResponse) _then;

  /// Create a copy of LlmResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_LlmResponse(
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      isError: null == isError
          ? _self.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      modelName: freezed == modelName
          ? _self.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDuration: freezed == totalDuration
          ? _self.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      loadDuration: freezed == loadDuration
          ? _self.loadDuration
          : loadDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalCount: freezed == promptEvalCount
          ? _self.promptEvalCount
          : promptEvalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      promptEvalDuration: freezed == promptEvalDuration
          ? _self.promptEvalDuration
          : promptEvalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalRate: freezed == promptEvalRate
          ? _self.promptEvalRate
          : promptEvalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      evalCount: freezed == evalCount
          ? _self.evalCount
          : evalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      evalDuration: freezed == evalDuration
          ? _self.evalDuration
          : evalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      evalRate: freezed == evalRate
          ? _self.evalRate
          : evalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      completionTokens: freezed == completionTokens
          ? _self.completionTokens
          : completionTokens // ignore: cast_nullable_to_non_nullable
              as int?,
      totalTokens: freezed == totalTokens
          ? _self.totalTokens
          : totalTokens // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
