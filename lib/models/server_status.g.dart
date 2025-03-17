// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerStatusInfo _$ServerStatusInfoFromJson(Map<String, dynamic> json) =>
    _ServerStatusInfo(
      status: $enumDecode(_$ServerStatusEnumMap, json['status']),
      message: json['message'] as String?,
      version: json['version'] as String?,
      hasModels: json['hasModels'] as bool? ?? false,
      availableModels: (json['availableModels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ServerStatusInfoToJson(_ServerStatusInfo instance) =>
    <String, dynamic>{
      'status': _$ServerStatusEnumMap[instance.status]!,
      'message': instance.message,
      'version': instance.version,
      'hasModels': instance.hasModels,
      'availableModels': instance.availableModels,
    };

const _$ServerStatusEnumMap = {
  ServerStatus.disconnected: 0,
  ServerStatus.connecting: 1,
  ServerStatus.connected: 2,
  ServerStatus.error: 3,
};
