// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PreferencesStateImpl _$$PreferencesStateImplFromJson(
        Map<String, dynamic> json) =>
    _$PreferencesStateImpl(
      themeMode: $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
          ThemeMode.system,
      isNotificationsEnabled: json['isNotificationsEnabled'] as bool? ?? true,
      isPushNotificationsEnabled:
          json['isPushNotificationsEnabled'] as bool? ?? true,
      isEmailNotificationsEnabled:
          json['isEmailNotificationsEnabled'] as bool? ?? true,
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$PreferencesStateImplToJson(
        _$PreferencesStateImpl instance) =>
    <String, dynamic>{
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'isNotificationsEnabled': instance.isNotificationsEnabled,
      'isPushNotificationsEnabled': instance.isPushNotificationsEnabled,
      'isEmailNotificationsEnabled': instance.isEmailNotificationsEnabled,
      'isLoading': instance.isLoading,
      'error': instance.error,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
