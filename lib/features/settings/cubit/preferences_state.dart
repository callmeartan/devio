import 'package:flutter/material.dart';

// Simple implementation without Freezed
class PreferencesState {
  final ThemeMode themeMode;
  final bool isNotificationsEnabled;
  final bool isPushNotificationsEnabled;
  final bool isEmailNotificationsEnabled;
  final bool isLoading;
  final String? error;

  const PreferencesState({
    this.themeMode = ThemeMode.dark,
    this.isNotificationsEnabled = true,
    this.isPushNotificationsEnabled = true,
    this.isEmailNotificationsEnabled = true,
    this.isLoading = false,
    this.error,
  });

  // Copy with method
  PreferencesState copyWith({
    ThemeMode? themeMode,
    bool? isNotificationsEnabled,
    bool? isPushNotificationsEnabled,
    bool? isEmailNotificationsEnabled,
    bool? isLoading,
    String? error,
  }) {
    return PreferencesState(
      themeMode: themeMode ?? this.themeMode,
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
      isPushNotificationsEnabled:
          isPushNotificationsEnabled ?? this.isPushNotificationsEnabled,
      isEmailNotificationsEnabled:
          isEmailNotificationsEnabled ?? this.isEmailNotificationsEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Factory method to create from JSON
  factory PreferencesState.fromJson(Map<String, dynamic> json) {
    return PreferencesState(
      themeMode:
          ThemeMode.values[json['theme_mode'] as int? ?? 2], // Default to dark
      isNotificationsEnabled: json['is_notifications_enabled'] as bool? ?? true,
      isPushNotificationsEnabled:
          json['is_push_notifications_enabled'] as bool? ?? true,
      isEmailNotificationsEnabled:
          json['is_email_notifications_enabled'] as bool? ?? true,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode.index,
      'is_notifications_enabled': isNotificationsEnabled,
      'is_push_notifications_enabled': isPushNotificationsEnabled,
      'is_email_notifications_enabled': isEmailNotificationsEnabled,
    };
  }
}
