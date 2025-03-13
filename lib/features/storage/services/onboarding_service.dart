import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// Service for managing onboarding tooltips for Local Mode
class OnboardingService {
  static const String _hasSeenLocalModeIntroKey = 'has_seen_local_mode_intro';
  static const String _hasSeenDataExportKey = 'has_seen_data_export_intro';
  static const String _hasSeenOfflineModeKey = 'has_seen_offline_mode_intro';

  /// Check if the user has seen the Local Mode introduction
  Future<bool> hasSeenLocalModeIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenLocalModeIntroKey) ?? false;
    } catch (e) {
      developer.log('Error checking if user has seen Local Mode intro: $e');
      return false;
    }
  }

  /// Mark the Local Mode introduction as seen
  Future<void> markLocalModeIntroAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenLocalModeIntroKey, true);
    } catch (e) {
      developer.log('Error marking Local Mode intro as seen: $e');
    }
  }

  /// Check if the user has seen the Data Export introduction
  Future<bool> hasSeenDataExportIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenDataExportKey) ?? false;
    } catch (e) {
      developer.log('Error checking if user has seen Data Export intro: $e');
      return false;
    }
  }

  /// Mark the Data Export introduction as seen
  Future<void> markDataExportIntroAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenDataExportKey, true);
    } catch (e) {
      developer.log('Error marking Data Export intro as seen: $e');
    }
  }

  /// Check if the user has seen the Offline Mode introduction
  Future<bool> hasSeenOfflineModeIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenOfflineModeKey) ?? false;
    } catch (e) {
      developer.log('Error checking if user has seen Offline Mode intro: $e');
      return false;
    }
  }

  /// Mark the Offline Mode introduction as seen
  Future<void> markOfflineModeIntroAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenOfflineModeKey, true);
    } catch (e) {
      developer.log('Error marking Offline Mode intro as seen: $e');
    }
  }

  /// Reset all onboarding flags (for testing)
  Future<void> resetAllOnboardingFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenLocalModeIntroKey, false);
      await prefs.setBool(_hasSeenDataExportKey, false);
      await prefs.setBool(_hasSeenOfflineModeKey, false);
    } catch (e) {
      developer.log('Error resetting onboarding flags: $e');
    }
  }
}
