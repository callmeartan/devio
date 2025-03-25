import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'preferences_state.freezed.dart';
part 'preferences_state.g.dart';

@freezed
abstract class PreferencesState with _$PreferencesState {
  const factory PreferencesState({
    @Default(ThemeMode.dark) ThemeMode themeMode,
    @Default(true) bool isNotificationsEnabled,
    @Default(true) bool isPushNotificationsEnabled,
    @Default(true) bool isEmailNotificationsEnabled,
    @Default(false) bool isLoading,
    String? error,
  }) = _PreferencesState;

  factory PreferencesState.fromJson(Map<String, dynamic> json) =>
      _$PreferencesStateFromJson(json);
}
