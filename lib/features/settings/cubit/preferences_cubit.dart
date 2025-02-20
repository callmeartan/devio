import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _pushNotificationsKey = 'push_notifications_enabled';
  static const String _emailNotificationsKey = 'email_notifications_enabled';
  static const String _languageKey = 'language_code';

  PreferencesCubit(this._prefs) : super(const PreferencesState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      emit(state.copyWith(isLoading: true));
      
      final themeIndex = _prefs.getInt(_themeKey);
      final themeMode = themeIndex != null ? ThemeMode.values[themeIndex] : ThemeMode.system;
      
      final isNotificationsEnabled = _prefs.getBool(_notificationsKey) ?? true;
      final isPushNotificationsEnabled = _prefs.getBool(_pushNotificationsKey) ?? true;
      final isEmailNotificationsEnabled = _prefs.getBool(_emailNotificationsKey) ?? true;
      final languageCode = _prefs.getString(_languageKey) ?? 'en';

      emit(state.copyWith(
        themeMode: themeMode,
        isNotificationsEnabled: isNotificationsEnabled,
        isPushNotificationsEnabled: isPushNotificationsEnabled,
        isEmailNotificationsEnabled: isEmailNotificationsEnabled,
        languageCode: languageCode,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load preferences: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await _prefs.setInt(_themeKey, mode.index);
      emit(state.copyWith(
        themeMode: mode,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to save theme mode: $e',
      ));
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    try {
      await _prefs.setBool(_notificationsKey, enabled);
      
      // If notifications are disabled, also disable push and email notifications
      if (!enabled) {
        await _prefs.setBool(_pushNotificationsKey, false);
        await _prefs.setBool(_emailNotificationsKey, false);
      }
      
      emit(state.copyWith(
        isNotificationsEnabled: enabled,
        isPushNotificationsEnabled: enabled ? state.isPushNotificationsEnabled : false,
        isEmailNotificationsEnabled: enabled ? state.isEmailNotificationsEnabled : false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to toggle notifications: $e',
      ));
    }
  }

  Future<void> togglePushNotifications(bool enabled) async {
    try {
      await _prefs.setBool(_pushNotificationsKey, enabled);
      emit(state.copyWith(
        isPushNotificationsEnabled: enabled,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to toggle push notifications: $e',
      ));
    }
  }

  Future<void> toggleEmailNotifications(bool enabled) async {
    try {
      await _prefs.setBool(_emailNotificationsKey, enabled);
      emit(state.copyWith(
        isEmailNotificationsEnabled: enabled,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to toggle email notifications: $e',
      ));
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      await _prefs.setString(_languageKey, languageCode);
      emit(state.copyWith(
        languageCode: languageCode,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to save language: $e',
      ));
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }

  @override
  Future<void> close() {
    return super.close();
  }
} 