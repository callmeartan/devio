// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preferences_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PreferencesState _$PreferencesStateFromJson(Map<String, dynamic> json) {
  return _PreferencesState.fromJson(json);
}

/// @nodoc
mixin _$PreferencesState {
  ThemeMode get themeMode => throw _privateConstructorUsedError;
  bool get isNotificationsEnabled => throw _privateConstructorUsedError;
  bool get isPushNotificationsEnabled => throw _privateConstructorUsedError;
  bool get isEmailNotificationsEnabled => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this PreferencesState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PreferencesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PreferencesStateCopyWith<PreferencesState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PreferencesStateCopyWith<$Res> {
  factory $PreferencesStateCopyWith(
          PreferencesState value, $Res Function(PreferencesState) then) =
      _$PreferencesStateCopyWithImpl<$Res, PreferencesState>;
  @useResult
  $Res call(
      {ThemeMode themeMode,
      bool isNotificationsEnabled,
      bool isPushNotificationsEnabled,
      bool isEmailNotificationsEnabled,
      bool isLoading,
      String? error});
}

/// @nodoc
class _$PreferencesStateCopyWithImpl<$Res, $Val extends PreferencesState>
    implements $PreferencesStateCopyWith<$Res> {
  _$PreferencesStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PreferencesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? isNotificationsEnabled = null,
    Object? isPushNotificationsEnabled = null,
    Object? isEmailNotificationsEnabled = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as ThemeMode,
      isNotificationsEnabled: null == isNotificationsEnabled
          ? _value.isNotificationsEnabled
          : isNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isPushNotificationsEnabled: null == isPushNotificationsEnabled
          ? _value.isPushNotificationsEnabled
          : isPushNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isEmailNotificationsEnabled: null == isEmailNotificationsEnabled
          ? _value.isEmailNotificationsEnabled
          : isEmailNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PreferencesStateImplCopyWith<$Res>
    implements $PreferencesStateCopyWith<$Res> {
  factory _$$PreferencesStateImplCopyWith(_$PreferencesStateImpl value,
          $Res Function(_$PreferencesStateImpl) then) =
      __$$PreferencesStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ThemeMode themeMode,
      bool isNotificationsEnabled,
      bool isPushNotificationsEnabled,
      bool isEmailNotificationsEnabled,
      bool isLoading,
      String? error});
}

/// @nodoc
class __$$PreferencesStateImplCopyWithImpl<$Res>
    extends _$PreferencesStateCopyWithImpl<$Res, _$PreferencesStateImpl>
    implements _$$PreferencesStateImplCopyWith<$Res> {
  __$$PreferencesStateImplCopyWithImpl(_$PreferencesStateImpl _value,
      $Res Function(_$PreferencesStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PreferencesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? isNotificationsEnabled = null,
    Object? isPushNotificationsEnabled = null,
    Object? isEmailNotificationsEnabled = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$PreferencesStateImpl(
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as ThemeMode,
      isNotificationsEnabled: null == isNotificationsEnabled
          ? _value.isNotificationsEnabled
          : isNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isPushNotificationsEnabled: null == isPushNotificationsEnabled
          ? _value.isPushNotificationsEnabled
          : isPushNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isEmailNotificationsEnabled: null == isEmailNotificationsEnabled
          ? _value.isEmailNotificationsEnabled
          : isEmailNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PreferencesStateImpl implements _PreferencesState {
  const _$PreferencesStateImpl(
      {this.themeMode = ThemeMode.system,
      this.isNotificationsEnabled = true,
      this.isPushNotificationsEnabled = true,
      this.isEmailNotificationsEnabled = true,
      this.isLoading = false,
      this.error});

  factory _$PreferencesStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PreferencesStateImplFromJson(json);

  @override
  @JsonKey()
  final ThemeMode themeMode;
  @override
  @JsonKey()
  final bool isNotificationsEnabled;
  @override
  @JsonKey()
  final bool isPushNotificationsEnabled;
  @override
  @JsonKey()
  final bool isEmailNotificationsEnabled;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'PreferencesState(themeMode: $themeMode, isNotificationsEnabled: $isNotificationsEnabled, isPushNotificationsEnabled: $isPushNotificationsEnabled, isEmailNotificationsEnabled: $isEmailNotificationsEnabled, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PreferencesStateImpl &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.isNotificationsEnabled, isNotificationsEnabled) ||
                other.isNotificationsEnabled == isNotificationsEnabled) &&
            (identical(other.isPushNotificationsEnabled,
                    isPushNotificationsEnabled) ||
                other.isPushNotificationsEnabled ==
                    isPushNotificationsEnabled) &&
            (identical(other.isEmailNotificationsEnabled,
                    isEmailNotificationsEnabled) ||
                other.isEmailNotificationsEnabled ==
                    isEmailNotificationsEnabled) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      themeMode,
      isNotificationsEnabled,
      isPushNotificationsEnabled,
      isEmailNotificationsEnabled,
      isLoading,
      error);

  /// Create a copy of PreferencesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PreferencesStateImplCopyWith<_$PreferencesStateImpl> get copyWith =>
      __$$PreferencesStateImplCopyWithImpl<_$PreferencesStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PreferencesStateImplToJson(
      this,
    );
  }
}

abstract class _PreferencesState implements PreferencesState {
  const factory _PreferencesState(
      {final ThemeMode themeMode,
      final bool isNotificationsEnabled,
      final bool isPushNotificationsEnabled,
      final bool isEmailNotificationsEnabled,
      final bool isLoading,
      final String? error}) = _$PreferencesStateImpl;

  factory _PreferencesState.fromJson(Map<String, dynamic> json) =
      _$PreferencesStateImpl.fromJson;

  @override
  ThemeMode get themeMode;
  @override
  bool get isNotificationsEnabled;
  @override
  bool get isPushNotificationsEnabled;
  @override
  bool get isEmailNotificationsEnabled;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of PreferencesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PreferencesStateImplCopyWith<_$PreferencesStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
