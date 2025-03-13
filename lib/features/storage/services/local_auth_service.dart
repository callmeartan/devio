import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

/// Service for handling authentication in Local Mode
class LocalAuthService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  static const String _localUserKey = 'local_user';
  static const String _localUserIdKey = 'local_user_id';

  LocalAuthService({
    required SharedPreferences prefs,
    FlutterSecureStorage? secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Checks if a local user exists
  Future<bool> hasLocalUser() async {
    return _prefs.containsKey(_localUserKey);
  }

  /// Creates a new local user
  ///
  /// Returns the user ID of the created user
  Future<String> createLocalUser({
    String? displayName,
  }) async {
    try {
      // Generate a unique ID for the local user
      final userId = const Uuid().v4();

      // Create the user data
      final userData = {
        'uid': userId,
        'displayName': displayName ?? 'Local User',
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save the user data
      await _prefs.setString(_localUserKey, jsonEncode(userData));
      await _secureStorage.write(key: _localUserIdKey, value: userId);

      developer.log('Created local user with ID: $userId');
      return userId;
    } catch (e) {
      developer.log('Error creating local user: $e');
      rethrow;
    }
  }

  /// Gets the current local user
  ///
  /// Returns a map containing the user data, or null if no user exists
  Future<Map<String, dynamic>?> getLocalUser() async {
    try {
      final userJson = _prefs.getString(_localUserKey);
      if (userJson == null) return null;

      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (e) {
      developer.log('Error getting local user: $e');
      return null;
    }
  }

  /// Updates the local user's profile
  Future<void> updateLocalUser({
    String? displayName,
  }) async {
    try {
      final userData = await getLocalUser();
      if (userData == null) {
        throw Exception('No local user found');
      }

      // Update the user data
      if (displayName != null) {
        userData['displayName'] = displayName;
      }

      userData['updatedAt'] = DateTime.now().toIso8601String();

      // Save the updated user data
      await _prefs.setString(_localUserKey, jsonEncode(userData));

      developer.log('Updated local user: ${userData['uid']}');
    } catch (e) {
      developer.log('Error updating local user: $e');
      rethrow;
    }
  }

  /// Deletes the local user
  Future<void> deleteLocalUser() async {
    try {
      await _prefs.remove(_localUserKey);
      await _secureStorage.delete(key: _localUserIdKey);

      developer.log('Deleted local user');
    } catch (e) {
      developer.log('Error deleting local user: $e');
      rethrow;
    }
  }

  /// Gets the local user ID
  Future<String?> getLocalUserId() async {
    try {
      return await _secureStorage.read(key: _localUserIdKey);
    } catch (e) {
      developer.log('Error getting local user ID: $e');
      return null;
    }
  }
}
