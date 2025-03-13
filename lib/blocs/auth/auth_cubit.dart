import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:devio/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devio/features/storage/models/storage_mode.dart';
import 'package:devio/features/storage/services/local_auth_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final SharedPreferences _prefs;
  final LocalAuthService _localAuthService;
  final StorageMode _storageMode;

  AuthCubit({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    SharedPreferences? prefs,
    LocalAuthService? localAuthService,
    StorageMode? storageMode,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              clientId: defaultTargetPlatform == TargetPlatform.iOS
                  ? DefaultFirebaseOptions.currentPlatform.iosClientId
                  : null,
            ),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _prefs = prefs ?? SharedPreferences.getInstance() as SharedPreferences,
        _localAuthService = localAuthService ??
            LocalAuthService(
                prefs: prefs ??
                    SharedPreferences.getInstance() as SharedPreferences),
        _storageMode = storageMode ?? StorageMode.cloud,
        super(const AuthState.initial()) {
    // If in cloud mode, listen to Firebase auth state changes
    if (_storageMode == StorageMode.cloud) {
      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          emit(AuthState.authenticated(
            uid: user.uid,
            displayName: user.displayName,
            email: user.email,
          ));
        } else {
          emit(const AuthState.unauthenticated());
        }
      });
    } else {
      // In local mode, check if a local user exists
      _checkLocalUser();
    }
  }

  // Check if a local user exists and emit the appropriate state
  Future<void> _checkLocalUser() async {
    try {
      final hasUser = await _localAuthService.hasLocalUser();
      if (hasUser) {
        final userData = await _localAuthService.getLocalUser();
        if (userData != null) {
          emit(AuthState.authenticated(
            uid: userData['uid'] as String,
            displayName: userData['displayName'] as String?,
            email: null, // Local users don't have emails
          ));
        } else {
          emit(const AuthState.unauthenticated());
        }
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      developer.log('Error checking local user: $e');
      emit(const AuthState.unauthenticated());
    }
  }

  // Sign in with local mode (create a local user)
  Future<void> signInWithLocalMode({String? displayName}) async {
    emit(const AuthState.loading());
    try {
      developer.log('Signing in with Local Mode...');

      // Check if a local user already exists
      final hasUser = await _localAuthService.hasLocalUser();
      String userId;

      if (hasUser) {
        // Get the existing user
        final userData = await _localAuthService.getLocalUser();
        userId = userData?['uid'] as String;
      } else {
        // Create a new local user
        userId = await _localAuthService.createLocalUser(
          displayName: displayName,
        );
      }

      // Get the user data
      final userData = await _localAuthService.getLocalUser();

      emit(AuthState.authenticated(
        uid: userId,
        displayName: userData?['displayName'] as String?,
        email: null, // Local users don't have emails
      ));

      developer.log('Successfully signed in with Local Mode');
    } catch (e) {
      developer.log('Error signing in with Local Mode: $e');
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signInAnonymously() async {
    emit(const AuthState.loading());
    try {
      developer.log('Attempting anonymous sign in through AuthCubit...');
      final userCredential = await _auth.signInAnonymously();
      developer
          .log('Anonymous sign in successful: ${userCredential.user?.uid}');
      emit(AuthState.authenticated(
        uid: userCredential.user?.uid ?? '',
        displayName: userCredential.user?.displayName,
        email: userCredential.user?.email,
      ));
    } on FirebaseAuthException catch (e) {
      developer
          .log('Firebase Auth Error in AuthCubit: ${e.code} - ${e.message}');
      emit(AuthState.error(e.message ?? 'Anonymous sign in failed'));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _auth.currentUser;
      emit(AuthState.authenticated(
        uid: user?.uid ?? '',
        displayName: user?.displayName,
        email: user?.email,
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthState.error(e.message ?? 'An error occurred'));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _auth.currentUser;
      emit(AuthState.authenticated(
        uid: user?.uid ?? '',
        displayName: user?.displayName,
        email: user?.email,
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthState.error(e.message ?? 'An error occurred'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());
    try {
      developer.log('Starting Google Sign In process...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log('Google Sign In was cancelled by user');
        emit(const AuthState.error('Sign in cancelled'));
        return;
      }

      developer.log('Getting Google Auth tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        developer.log('Failed to get Google Auth tokens');
        emit(const AuthState.error('Failed to get authentication tokens'));
        return;
      }

      developer.log('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      developer.log('Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        developer.log('Successfully signed in with Google: ${user.email}');
        if (user.displayName?.isEmpty ?? true) {
          await user.updateDisplayName(googleUser.displayName);
        }

        emit(AuthState.authenticated(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
        ));
      } else {
        emit(const AuthState.error('Failed to get user information'));
      }
    } on FirebaseAuthException catch (e) {
      developer.log('Firebase Auth Error: ${e.code} - ${e.message}');
      emit(AuthState.error(e.message ?? 'Firebase authentication failed'));
    } catch (e) {
      developer.log('Google sign in error: $e');
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signInWithApple() async {
    emit(const AuthState.loading());
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        // Store name from Apple Sign In if it's the first time (when name is provided)
        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          final displayName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();

          // Store in Firebase Auth
          await user.updateDisplayName(displayName);

          // Store in Firestore for future reference
          await _firestore.collection('users').doc(user.uid).set({
            'displayName': displayName,
            'email': user.email,
            'lastSignInTime': FieldValue.serverTimestamp(),
            'provider': 'apple.com',
          }, SetOptions(merge: true));
        } else {
          // Try to get the stored name from Firestore if not provided by Apple
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists && userDoc.data()?['displayName'] != null) {
            final storedDisplayName = userDoc.data()?['displayName'] as String;
            if (user.displayName == null || user.displayName!.isEmpty) {
              await user.updateDisplayName(storedDisplayName);
            }
          }
        }

        emit(AuthState.authenticated(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
        ));
      }
    } catch (e) {
      developer.log('Apple sign in error: $e');
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      if (_storageMode == StorageMode.cloud) {
        await _auth.signOut();
        await _googleSignIn.signOut();
      } else {
        // In local mode, we don't delete the user data, just sign out
        // This allows the user to sign back in without losing data
      }
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> updateProfile({String? displayName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user found');
      }

      // Update display name in Firebase Auth if provided
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      // Update user data in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName ?? user.displayName,
        'email': user.email,
        'lastSignInTime': FieldValue.serverTimestamp(),
        'provider': user.providerData.first.providerId,
      }, SetOptions(merge: true));

      // Update state with new user data
      emit(AuthState.authenticated(
        uid: user.uid,
        displayName: displayName ?? user.displayName,
        email: user.email,
      ));
    } catch (e) {
      developer.log('Error updating profile: $e');
      emit(AuthState.error(e.toString()));
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    emit(const AuthState.loading());
    try {
      if (_storageMode == StorageMode.cloud) {
        final user = _auth.currentUser;
        if (user != null) {
          final userId = user.uid;
          // Get the provider data before deleting
          final providers = user.providerData.map((e) => e.providerId).toList();

          developer.log('Starting account deletion process for user: $userId');

          // First, delete all user data from Firestore
          try {
            await _deleteAllUserData(userId);
            developer.log('Successfully deleted all user data from Firestore');
          } catch (e) {
            developer.log('Error deleting Firestore data: $e');
            // Continue with account deletion even if Firestore deletion fails
            // But rethrow if this is the only error
            final firestoreError = e;

            // Then try to delete the auth account
            try {
              await user.delete();
            } catch (authError) {
              if (authError is FirebaseAuthException &&
                  authError.code == 'requires-recent-login') {
                // Handle reauthentication
                await _handleReauthentication(user, providers);

                // Try deleting all data again after reauthentication
                await _deleteAllUserData(userId);

                // Try deleting account again after reauthentication
                await user.delete();
              } else {
                // If there's an auth error that's not about reauthentication, throw it
                throw authError;
              }
            }

            // If we got here, the auth account was deleted successfully
            // but there was an error with Firestore deletion
            developer.log(
                'Auth account deleted but there were Firestore errors: $firestoreError');
          }

          // Sign out and clean up after successful deletion
          await _googleSignIn.signOut();
          await _auth.signOut();
        } else {
          emit(const AuthState.error('No user found to delete'));
          return;
        }
      } else {
        // In local mode, delete the local user
        await _localAuthService.deleteLocalUser();
        developer.log('Local user deleted');
      }

      // Emit unauthenticated state for proper redirection
      emit(const AuthState.unauthenticated());
      developer.log('Account deletion completed successfully');
    } catch (e) {
      developer.log('Error deleting account: $e');
      emit(AuthState.error(e.toString()));
      rethrow;
    }
  }

  // Helper method to handle reauthentication
  Future<void> _handleReauthentication(
      User user, List<String> providers) async {
    developer.log('Reauthentication required for account deletion');

    if (providers.contains('apple.com')) {
      // Reauthenticate with Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await user.reauthenticateWithCredential(oauthCredential);
      developer.log('Reauthenticated with Apple successfully');
    } else if (providers.contains('google.com')) {
      // Reauthenticate with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
      developer.log('Reauthenticated with Google successfully');
    } else if (providers.contains('password')) {
      // For email/password, we would need to prompt the user for their password
      // This would typically be handled in the UI layer
      throw Exception(
          'Reauthentication required with password. Please sign in again before deleting your account.');
    } else {
      throw Exception(
          'Reauthentication required but no supported provider found');
    }
  }

  // Helper method to delete all user data
  Future<void> _deleteAllUserData(String userId) async {
    try {
      developer.log('Starting deletion of all user data for user: $userId');

      // Create a batch for efficient writes
      final batch = _firestore.batch();

      // 1. Delete user document
      batch.delete(_firestore.collection('users').doc(userId));

      // 2. Delete user's chats - all messages sent by this user
      final userChats = await _firestore
          .collection('chats')
          .where('senderId', isEqualTo: userId)
          .get();

      for (var doc in userChats.docs) {
        batch.delete(doc.reference);
      }

      // 3. Delete user's chat metadata
      final userChatMetadata = await _firestore
          .collection('chat_metadata')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in userChatMetadata.docs) {
        batch.delete(doc.reference);
      }

      // 4. Get all chat IDs where the user participated
      final chatIds = userChats.docs
          .map((doc) => doc.data()['chatId'] as String?)
          .where((id) => id != null)
          .toSet()
          .cast<String>();

      // 5. Delete chat metadata for those chats
      for (var chatId in chatIds) {
        final chatMetadata =
            await _firestore.collection('chat_metadata').doc(chatId).get();

        if (chatMetadata.exists) {
          batch.delete(chatMetadata.reference);
        }
      }

      // 6. Delete any other collections that might contain user data
      // If you add more collections in the future, add deletion logic here

      // 7. Commit all Firestore deletions
      await batch.commit();
      developer
          .log('Successfully deleted all Firestore data for user: $userId');

      // 8. Delete user files from Firebase Storage
      await _deleteUserStorageFiles(userId);

      developer.log('Successfully deleted all user data for user: $userId');
    } catch (e) {
      developer.log('Error in _deleteAllUserData: $e');
      rethrow;
    }
  }

  // Helper method to delete all user files from Firebase Storage
  Future<void> _deleteUserStorageFiles(String userId) async {
    try {
      developer.log(
          'Starting deletion of user files from Firebase Storage for user: $userId');

      // Main user folder - typically where user-specific files are stored
      final userStorageRef = _storage.ref().child('users/$userId');

      // List all items in the user's directory
      try {
        final ListResult result = await userStorageRef.listAll();

        // Delete all files in the user's directory
        for (var item in result.items) {
          await item.delete();
          developer.log('Deleted file: ${item.fullPath}');
        }

        // Recursively delete all subdirectories and their contents
        for (var prefix in result.prefixes) {
          await _deleteStorageDirectory(prefix);
        }

        developer.log(
            'Successfully deleted all user files from Storage for user: $userId');
      } catch (e) {
        // If the directory doesn't exist, this is fine - just log and continue
        if (e.toString().contains('object-not-found')) {
          developer.log('No user files found in Storage for user: $userId');
        } else {
          // For other errors, we should log but not fail the entire deletion process
          developer.log('Error listing user files in Storage: $e');
        }
      }

      // Check for user uploads in other potential directories
      // For example, if uploads are stored by chat ID but with user prefixes
      final chatUploadsRef = _storage.ref().child('chat_uploads');
      try {
        final ListResult chatUploads = await chatUploadsRef.listAll();

        // Delete files that contain the user ID in their path
        for (var item in chatUploads.items) {
          if (item.fullPath.contains(userId)) {
            await item.delete();
            developer.log('Deleted chat upload: ${item.fullPath}');
          }
        }

        // Process prefixes that might contain user data
        for (var prefix in chatUploads.prefixes) {
          if (prefix.fullPath.contains(userId)) {
            await _deleteStorageDirectory(prefix);
          }
        }
      } catch (e) {
        // If the directory doesn't exist, this is fine
        if (e.toString().contains('object-not-found')) {
          developer.log('No chat uploads directory found');
        } else {
          developer.log('Error checking chat uploads: $e');
        }
      }

      // 9. Delete user's profile picture if it exists
      try {
        final profilePicRef =
            _storage.ref().child('profile_pictures/$userId.jpg');
        await profilePicRef.delete();
        developer.log('Deleted user profile picture');
      } catch (e) {
        // If the file doesn't exist, this is fine
        if (e.toString().contains('object-not-found')) {
          developer.log('No profile picture found for user: $userId');
        } else {
          developer.log('Error deleting profile picture: $e');
        }
      }
    } catch (e) {
      developer.log('Error in _deleteUserStorageFiles: $e');
      // We don't rethrow here to ensure the account deletion continues
      // even if there's an issue with Storage deletion
    }
  }

  // Helper method to recursively delete a directory in Firebase Storage
  Future<void> _deleteStorageDirectory(Reference directoryRef) async {
    try {
      final ListResult contents = await directoryRef.listAll();

      // Delete all files in this directory
      for (var item in contents.items) {
        await item.delete();
        developer.log('Deleted file: ${item.fullPath}');
      }

      // Recursively delete all subdirectories
      for (var prefix in contents.prefixes) {
        await _deleteStorageDirectory(prefix);
      }

      // Note: Firebase Storage doesn't allow deleting empty directories,
      // they are automatically removed when all contained files are deleted
    } catch (e) {
      developer.log('Error deleting directory ${directoryRef.fullPath}: $e');
    }
  }
}
