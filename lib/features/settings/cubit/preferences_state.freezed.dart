// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preferences_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PreferencesState {
  ThemeMode get themeMode;
  bool get isNotificationsEnabled;
  bool get isPushNotificationsEnabled;
  bool get isEmailNotificationsEnabled;
  bool get isLoading;
  String? get error;

  /// Create a copy of PreferencesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PreferencesStateCopyWith<PreferencesState> get copyWith =>
      _$PreferencesStateCopyWithImpl<PreferencesState>(
          this as PreferencesState, _$identity);

  /// Serializes this PreferencesState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PreferencesState &&
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

  @override
  String toString() {
    return 'PreferencesState(themeMode: $themeMode, isNotificationsEnabled: $isNotificationsEnabled, isPushNotificationsEnabled: $isPushNotificationsEnabled, isEmailNotificationsEnabled: $isEmailNotificationsEnabled, isLoading: $isLoading, error: $error)';
  }
}

/// @nodoc
abstract mixin class $PreferencesStateCopyWith<$Res> {
  factory $PreferencesStateCopyWith(
          PreferencesState value, $Res Function(PreferencesState) _then) =
      _$PreferencesStateCopyWithImpl;
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
class _$PreferencesStateCopyWithImpl<$Res>
    implements $PreferencesStateCopyWith<$Res> {
  _$PreferencesStateCopyWithImpl(this._self, this._then);

  final PreferencesState _self;
  final $Res Function(PreferencesState) _then;

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
    return _then(_self.copyWith(
      themeMode: null == themeMode
          ? _self.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as ThemeMode,
      isNotificationsEnabled: null == isNotificationsEnabled
          ? _self.isNotificationsEnabled
          : isNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isPushNotificationsEnabled: null == isPushNotificationsEnabled
          ? _self.isPushNotificationsEnabled
          : isPushNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isEmailNotificationsEnabled: null == isEmailNotificationsEnabled
          ? _self.isEmailNotificationsEnabled
          : isEmailNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PreferencesState implements PreferencesState {
  const _PreferencesState(
      {this.themeMode = ThemeMode.dark,
      this.isNotificationsEnabled = true,
      this.isPushNotificationsEnabled = true,
      this.isEmailNotificationsEnabled = true,
      this.isLoading = false,
      this.error});
  factory _PreferencesState.fromJson(Map<String, dynamic> json) =>
      _$PreferencesStateFromJson(json);

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

  /// Create a copy of PreferencesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PreferencesStateCopyWith<_PreferencesState> get copyWith =>
      __$PreferencesStateCopyWithImpl<_PreferencesState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PreferencesStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PreferencesState &&
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

  @override
  String toString() {
    return 'PreferencesState(themeMode: $themeMode, isNotificationsEnabled: $isNotificationsEnabled, isPushNotificationsEnabled: $isPushNotificationsEnabled, isEmailNotificationsEnabled: $isEmailNotificationsEnabled, isLoading: $isLoading, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$PreferencesStateCopyWith<$Res>
    implements $PreferencesStateCopyWith<$Res> {
  factory _$PreferencesStateCopyWith(
          _PreferencesState value, $Res Function(_PreferencesState) _then) =
      __$PreferencesStateCopyWithImpl;
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
class __$PreferencesStateCopyWithImpl<$Res>
    implements _$PreferencesStateCopyWith<$Res> {
  __$PreferencesStateCopyWithImpl(this._self, this._then);

  final _PreferencesState _self;
  final $Res Function(_PreferencesState) _then;

  /// Create a copy of PreferencesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? themeMode = null,
    Object? isNotificationsEnabled = null,
    Object? isPushNotificationsEnabled = null,
    Object? isEmailNotificationsEnabled = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_PreferencesState(
      themeMode: null == themeMode
          ? _self.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as ThemeMode,
      isNotificationsEnabled: null == isNotificationsEnabled
          ? _self.isNotificationsEnabled
          : isNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isPushNotificationsEnabled: null == isPushNotificationsEnabled
          ? _self.isPushNotificationsEnabled
          : isPushNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isEmailNotificationsEnabled: null == isEmailNotificationsEnabled
          ? _self.isEmailNotificationsEnabled
          : isEmailNotificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
