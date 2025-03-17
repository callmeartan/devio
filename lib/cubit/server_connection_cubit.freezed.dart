// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_connection_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServerConnectionState {
  ServerStatusInfo get status;
  String get serverUrl;
  bool get isCheckingStatus;

  /// Create a copy of ServerConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ServerConnectionStateCopyWith<ServerConnectionState> get copyWith =>
      _$ServerConnectionStateCopyWithImpl<ServerConnectionState>(
          this as ServerConnectionState, _$identity);

  /// Serializes this ServerConnectionState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ServerConnectionState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.serverUrl, serverUrl) ||
                other.serverUrl == serverUrl) &&
            (identical(other.isCheckingStatus, isCheckingStatus) ||
                other.isCheckingStatus == isCheckingStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, status, serverUrl, isCheckingStatus);

  @override
  String toString() {
    return 'ServerConnectionState(status: $status, serverUrl: $serverUrl, isCheckingStatus: $isCheckingStatus)';
  }
}

/// @nodoc
abstract mixin class $ServerConnectionStateCopyWith<$Res> {
  factory $ServerConnectionStateCopyWith(ServerConnectionState value,
          $Res Function(ServerConnectionState) _then) =
      _$ServerConnectionStateCopyWithImpl;
  @useResult
  $Res call({ServerStatusInfo status, String serverUrl, bool isCheckingStatus});

  $ServerStatusInfoCopyWith<$Res> get status;
}

/// @nodoc
class _$ServerConnectionStateCopyWithImpl<$Res>
    implements $ServerConnectionStateCopyWith<$Res> {
  _$ServerConnectionStateCopyWithImpl(this._self, this._then);

  final ServerConnectionState _self;
  final $Res Function(ServerConnectionState) _then;

  /// Create a copy of ServerConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? serverUrl = null,
    Object? isCheckingStatus = null,
  }) {
    return _then(_self.copyWith(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ServerStatusInfo,
      serverUrl: null == serverUrl
          ? _self.serverUrl
          : serverUrl // ignore: cast_nullable_to_non_nullable
              as String,
      isCheckingStatus: null == isCheckingStatus
          ? _self.isCheckingStatus
          : isCheckingStatus // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of ServerConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ServerStatusInfoCopyWith<$Res> get status {
    return $ServerStatusInfoCopyWith<$Res>(_self.status, (value) {
      return _then(_self.copyWith(status: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _ServerConnectionState implements ServerConnectionState {
  const _ServerConnectionState(
      {required this.status,
      required this.serverUrl,
      this.isCheckingStatus = false});
  factory _ServerConnectionState.fromJson(Map<String, dynamic> json) =>
      _$ServerConnectionStateFromJson(json);

  @override
  final ServerStatusInfo status;
  @override
  final String serverUrl;
  @override
  @JsonKey()
  final bool isCheckingStatus;

  /// Create a copy of ServerConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ServerConnectionStateCopyWith<_ServerConnectionState> get copyWith =>
      __$ServerConnectionStateCopyWithImpl<_ServerConnectionState>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ServerConnectionStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ServerConnectionState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.serverUrl, serverUrl) ||
                other.serverUrl == serverUrl) &&
            (identical(other.isCheckingStatus, isCheckingStatus) ||
                other.isCheckingStatus == isCheckingStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, status, serverUrl, isCheckingStatus);

  @override
  String toString() {
    return 'ServerConnectionState(status: $status, serverUrl: $serverUrl, isCheckingStatus: $isCheckingStatus)';
  }
}

/// @nodoc
abstract mixin class _$ServerConnectionStateCopyWith<$Res>
    implements $ServerConnectionStateCopyWith<$Res> {
  factory _$ServerConnectionStateCopyWith(_ServerConnectionState value,
          $Res Function(_ServerConnectionState) _then) =
      __$ServerConnectionStateCopyWithImpl;
  @override
  @useResult
  $Res call({ServerStatusInfo status, String serverUrl, bool isCheckingStatus});

  @override
  $ServerStatusInfoCopyWith<$Res> get status;
}

/// @nodoc
class __$ServerConnectionStateCopyWithImpl<$Res>
    implements _$ServerConnectionStateCopyWith<$Res> {
  __$ServerConnectionStateCopyWithImpl(this._self, this._then);

  final _ServerConnectionState _self;
  final $Res Function(_ServerConnectionState) _then;

  /// Create a copy of ServerConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? serverUrl = null,
    Object? isCheckingStatus = null,
  }) {
    return _then(_ServerConnectionState(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ServerStatusInfo,
      serverUrl: null == serverUrl
          ? _self.serverUrl
          : serverUrl // ignore: cast_nullable_to_non_nullable
              as String,
      isCheckingStatus: null == isCheckingStatus
          ? _self.isCheckingStatus
          : isCheckingStatus // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of ServerConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ServerStatusInfoCopyWith<$Res> get status {
    return $ServerStatusInfoCopyWith<$Res>(_self.status, (value) {
      return _then(_self.copyWith(status: value));
    });
  }
}

// dart format on
