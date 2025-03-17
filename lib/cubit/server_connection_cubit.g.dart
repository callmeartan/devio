// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_connection_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerConnectionState _$ServerConnectionStateFromJson(
        Map<String, dynamic> json) =>
    _ServerConnectionState(
      status: ServerStatusInfo.fromJson(json['status'] as Map<String, dynamic>),
      serverUrl: json['serverUrl'] as String,
      isCheckingStatus: json['isCheckingStatus'] as bool? ?? false,
    );

Map<String, dynamic> _$ServerConnectionStateToJson(
        _ServerConnectionState instance) =>
    <String, dynamic>{
      'status': instance.status,
      'serverUrl': instance.serverUrl,
      'isCheckingStatus': instance.isCheckingStatus,
    };
