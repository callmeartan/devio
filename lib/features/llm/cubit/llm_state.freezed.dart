// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'llm_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LlmState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LlmState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LlmState()';
  }
}

/// @nodoc
class $LlmStateCopyWith<$Res> {
  $LlmStateCopyWith(LlmState _, $Res Function(LlmState) __);
}

/// @nodoc

class _Initial implements LlmState {
  const _Initial();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _Initial);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LlmState.initial()';
  }
}

/// @nodoc

class _Loading implements LlmState {
  const _Loading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _Loading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LlmState.loading()';
  }
}

/// @nodoc

class _Success implements LlmState {
  const _Success(this.response);

  final LlmResponse response;

  /// Create a copy of LlmState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SuccessCopyWith<_Success> get copyWith =>
      __$SuccessCopyWithImpl<_Success>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Success &&
            (identical(other.response, response) ||
                other.response == response));
  }

  @override
  int get hashCode => Object.hash(runtimeType, response);

  @override
  String toString() {
    return 'LlmState.success(response: $response)';
  }
}

/// @nodoc
abstract mixin class _$SuccessCopyWith<$Res>
    implements $LlmStateCopyWith<$Res> {
  factory _$SuccessCopyWith(_Success value, $Res Function(_Success) _then) =
      __$SuccessCopyWithImpl;
  @useResult
  $Res call({LlmResponse response});

  $LlmResponseCopyWith<$Res> get response;
}

/// @nodoc
class __$SuccessCopyWithImpl<$Res> implements _$SuccessCopyWith<$Res> {
  __$SuccessCopyWithImpl(this._self, this._then);

  final _Success _self;
  final $Res Function(_Success) _then;

  /// Create a copy of LlmState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? response = null,
  }) {
    return _then(_Success(
      null == response
          ? _self.response
          : response // ignore: cast_nullable_to_non_nullable
              as LlmResponse,
    ));
  }

  /// Create a copy of LlmState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LlmResponseCopyWith<$Res> get response {
    return $LlmResponseCopyWith<$Res>(_self.response, (value) {
      return _then(_self.copyWith(response: value));
    });
  }
}

/// @nodoc

class _Error implements LlmState {
  const _Error(this.message);

  final String message;

  /// Create a copy of LlmState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ErrorCopyWith<_Error> get copyWith =>
      __$ErrorCopyWithImpl<_Error>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Error &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'LlmState.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $LlmStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) =
      __$ErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$ErrorCopyWithImpl<$Res> implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

  /// Create a copy of LlmState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(_Error(
      null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _ModelSwitching implements LlmState {
  const _ModelSwitching(
      {required this.fromModel, required this.toModel, required this.attempt});

  final String fromModel;
  final String toModel;
  final int attempt;

  /// Create a copy of LlmState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ModelSwitchingCopyWith<_ModelSwitching> get copyWith =>
      __$ModelSwitchingCopyWithImpl<_ModelSwitching>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ModelSwitching &&
            (identical(other.fromModel, fromModel) ||
                other.fromModel == fromModel) &&
            (identical(other.toModel, toModel) || other.toModel == toModel) &&
            (identical(other.attempt, attempt) || other.attempt == attempt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fromModel, toModel, attempt);

  @override
  String toString() {
    return 'LlmState.modelSwitching(fromModel: $fromModel, toModel: $toModel, attempt: $attempt)';
  }
}

/// @nodoc
abstract mixin class _$ModelSwitchingCopyWith<$Res>
    implements $LlmStateCopyWith<$Res> {
  factory _$ModelSwitchingCopyWith(
          _ModelSwitching value, $Res Function(_ModelSwitching) _then) =
      __$ModelSwitchingCopyWithImpl;
  @useResult
  $Res call({String fromModel, String toModel, int attempt});
}

/// @nodoc
class __$ModelSwitchingCopyWithImpl<$Res>
    implements _$ModelSwitchingCopyWith<$Res> {
  __$ModelSwitchingCopyWithImpl(this._self, this._then);

  final _ModelSwitching _self;
  final $Res Function(_ModelSwitching) _then;

  /// Create a copy of LlmState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fromModel = null,
    Object? toModel = null,
    Object? attempt = null,
  }) {
    return _then(_ModelSwitching(
      fromModel: null == fromModel
          ? _self.fromModel
          : fromModel // ignore: cast_nullable_to_non_nullable
              as String,
      toModel: null == toModel
          ? _self.toModel
          : toModel // ignore: cast_nullable_to_non_nullable
              as String,
      attempt: null == attempt
          ? _self.attempt
          : attempt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
