// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServerStatusInfo {
  ServerStatus get status;
  String? get message;
  String? get version;
  bool get hasModels;
  List<String>? get availableModels;

  /// Create a copy of ServerStatusInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ServerStatusInfoCopyWith<ServerStatusInfo> get copyWith =>
      _$ServerStatusInfoCopyWithImpl<ServerStatusInfo>(
          this as ServerStatusInfo, _$identity);

  /// Serializes this ServerStatusInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ServerStatusInfo &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.hasModels, hasModels) ||
                other.hasModels == hasModels) &&
            const DeepCollectionEquality()
                .equals(other.availableModels, availableModels));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, status, message, version,
      hasModels, const DeepCollectionEquality().hash(availableModels));

  @override
  String toString() {
    return 'ServerStatusInfo(status: $status, message: $message, version: $version, hasModels: $hasModels, availableModels: $availableModels)';
  }
}

/// @nodoc
abstract mixin class $ServerStatusInfoCopyWith<$Res> {
  factory $ServerStatusInfoCopyWith(
          ServerStatusInfo value, $Res Function(ServerStatusInfo) _then) =
      _$ServerStatusInfoCopyWithImpl;
  @useResult
  $Res call(
      {ServerStatus status,
      String? message,
      String? version,
      bool hasModels,
      List<String>? availableModels});
}

/// @nodoc
class _$ServerStatusInfoCopyWithImpl<$Res>
    implements $ServerStatusInfoCopyWith<$Res> {
  _$ServerStatusInfoCopyWithImpl(this._self, this._then);

  final ServerStatusInfo _self;
  final $Res Function(ServerStatusInfo) _then;

  /// Create a copy of ServerStatusInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? message = freezed,
    Object? version = freezed,
    Object? hasModels = null,
    Object? availableModels = freezed,
  }) {
    return _then(_self.copyWith(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ServerStatus,
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      hasModels: null == hasModels
          ? _self.hasModels
          : hasModels // ignore: cast_nullable_to_non_nullable
              as bool,
      availableModels: freezed == availableModels
          ? _self.availableModels
          : availableModels // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ServerStatusInfo implements ServerStatusInfo {
  const _ServerStatusInfo(
      {required this.status,
      this.message,
      this.version,
      this.hasModels = false,
      final List<String>? availableModels})
      : _availableModels = availableModels;
  factory _ServerStatusInfo.fromJson(Map<String, dynamic> json) =>
      _$ServerStatusInfoFromJson(json);

  @override
  final ServerStatus status;
  @override
  final String? message;
  @override
  final String? version;
  @override
  @JsonKey()
  final bool hasModels;
  final List<String>? _availableModels;
  @override
  List<String>? get availableModels {
    final value = _availableModels;
    if (value == null) return null;
    if (_availableModels is EqualUnmodifiableListView) return _availableModels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of ServerStatusInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ServerStatusInfoCopyWith<_ServerStatusInfo> get copyWith =>
      __$ServerStatusInfoCopyWithImpl<_ServerStatusInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ServerStatusInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ServerStatusInfo &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.hasModels, hasModels) ||
                other.hasModels == hasModels) &&
            const DeepCollectionEquality()
                .equals(other._availableModels, _availableModels));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, status, message, version,
      hasModels, const DeepCollectionEquality().hash(_availableModels));

  @override
  String toString() {
    return 'ServerStatusInfo(status: $status, message: $message, version: $version, hasModels: $hasModels, availableModels: $availableModels)';
  }
}

/// @nodoc
abstract mixin class _$ServerStatusInfoCopyWith<$Res>
    implements $ServerStatusInfoCopyWith<$Res> {
  factory _$ServerStatusInfoCopyWith(
          _ServerStatusInfo value, $Res Function(_ServerStatusInfo) _then) =
      __$ServerStatusInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {ServerStatus status,
      String? message,
      String? version,
      bool hasModels,
      List<String>? availableModels});
}

/// @nodoc
class __$ServerStatusInfoCopyWithImpl<$Res>
    implements _$ServerStatusInfoCopyWith<$Res> {
  __$ServerStatusInfoCopyWithImpl(this._self, this._then);

  final _ServerStatusInfo _self;
  final $Res Function(_ServerStatusInfo) _then;

  /// Create a copy of ServerStatusInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? message = freezed,
    Object? version = freezed,
    Object? hasModels = null,
    Object? availableModels = freezed,
  }) {
    return _then(_ServerStatusInfo(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ServerStatus,
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      hasModels: null == hasModels
          ? _self.hasModels
          : hasModels // ignore: cast_nullable_to_non_nullable
              as bool,
      availableModels: freezed == availableModels
          ? _self._availableModels
          : availableModels // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

// dart format on
