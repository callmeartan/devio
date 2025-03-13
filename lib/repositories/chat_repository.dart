import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/chat_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collectionPath = 'chats';
  final String _chatMetadataPath = 'chat_metadata';

  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> _checkAuth() async {
    final user = _auth.currentUser;
    developer.log('Current auth state - User: ${user?.uid ?? 'null'}');

    if (user == null) {
      developer.log(
          'No authenticated user found in _checkAuth, attempting anonymous sign-in...');
      try {
        // Try to sign in anonymously
        final userCredential = await _auth.signInAnonymously();
        developer.log(
            'Anonymous sign-in successful in _checkAuth. User ID: ${userCredential.user?.uid}');
      } catch (e) {
        developer.log('Error during anonymous sign-in in _checkAuth: $e');
        throw Exception('User must be authenticated to access chat data: $e');
      }
    }
  }

  Stream<List<ChatMessage>> getChatMessages() {
    _checkAuth();
    return _firestore
        .collection(_collectionPath)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()))
            .toList());
  }

  Stream<List<ChatMessage>> getChatMessagesForId(String chatId) {
    try {
      // We can't await in a synchronous method, so we'll log and handle auth in the stream
      developer.log('Getting messages for chat: $chatId');

      // Check auth status
      final user = _auth.currentUser;
      if (user == null) {
        developer.log(
            'No authenticated user found in getChatMessagesForId, will attempt anonymous sign-in');
      } else {
        developer
            .log('User authenticated in getChatMessagesForId: ${user.uid}');
      }

      // Create a controller to handle the stream
      final controller = StreamController<List<ChatMessage>>();

      // Handle authentication and then set up the stream
      _handleAuthAndSetupStream(chatId, controller);

      // Return the stream from the controller
      return controller.stream;
    } catch (e) {
      developer.log('Error setting up chat stream: $e');
      rethrow;
    }
  }

  void _handleAuthAndSetupStream(
      String chatId, StreamController<List<ChatMessage>> controller) {
    // Try to authenticate if needed
    _checkAuth().then((_) {
      // Now set up the Firestore stream
      final subscription = _firestore
          .collection(_collectionPath)
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) {
        try {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromJson(doc.data()))
              .toList();

          developer
              .log('Retrieved ${messages.length} messages for chat: $chatId');

          // Add messages to the stream
          controller.add(messages);
        } catch (e) {
          developer.log('Error processing messages in stream: $e');
          controller.addError(e);
        }
      }, onError: (error) {
        developer.log('Error in Firestore stream: $error');
        controller.addError(error);
      });

      // Close the controller when the stream is done
      controller.onCancel = () {
        subscription.cancel();
      };
    }).catchError((error) {
      developer
          .log('Authentication error in _handleAuthAndSetupStream: $error');
      controller.addError(error);
      controller.close();
    });
  }

  Future<List<Map<String, dynamic>>> getChatHistories() async {
    try {
      await _checkAuth();
      developer.log('Getting chat histories');
      developer.log('Current user: ${_auth.currentUser?.uid ?? "null"}');

      // Get all metadata in a single query
      developer.log('Querying chat_metadata collection');
      final metadataSnapshot =
          await _firestore.collection(_chatMetadataPath).get();

      developer
          .log('Retrieved ${metadataSnapshot.docs.length} metadata documents');

      // Log the metadata documents for debugging
      for (var i = 0; i < metadataSnapshot.docs.length; i++) {
        final doc = metadataSnapshot.docs[i];
        developer.log('Metadata $i: ID=${doc.id}, Data=${doc.data()}');
      }

      // If we don't have any metadata, return an empty list early
      if (metadataSnapshot.docs.isEmpty) {
        developer.log('No chat metadata found, returning empty list');
        return [];
      }

      final metadataMap = Map.fromEntries(
          metadataSnapshot.docs.map((doc) => MapEntry(doc.id, doc.data())));

      developer.log('Metadata map created with ${metadataMap.length} entries');

      // Get latest messages for each chat
      developer.log('Querying chats collection for latest messages');
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionPath)
          .orderBy('timestamp', descending: true)
          .limit(100) // Limit to latest 100 messages
          .get();

      developer.log('Retrieved ${snapshot.docs.length} messages');

      // Log the message documents for debugging
      for (var i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        developer.log(
            'Message $i: ID=${doc.id}, ChatID=${data['chatId']}, Content=${data['content'].toString().substring(0, math.min(20, data['content'].toString().length))}...');
      }

      // If we don't have any messages, but still have metadata, clear the metadata
      if (snapshot.docs.isEmpty && metadataSnapshot.docs.isNotEmpty) {
        developer.log(
            'Found metadata but no messages - cleaning up orphaned metadata');

        // Batch delete all metadata since we have no messages
        final cleanupBatch = _firestore.batch();
        for (var doc in metadataSnapshot.docs) {
          cleanupBatch.delete(doc.reference);
        }
        await cleanupBatch.commit();

        developer.log(
            'Cleaned up ${metadataSnapshot.docs.length} orphaned metadata records');
        return [];
      }

      final Map<String, ChatMessage> chatHistories = {};
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final message = ChatMessage.fromJson(data);

          if (!chatHistories.containsKey(message.chatId) ||
              message.timestamp
                  .isAfter(chatHistories[message.chatId]!.timestamp)) {
            chatHistories[message.chatId] = message;
          }
        } catch (e) {
          developer.log('Error parsing message: $e');
        }
      }

      developer.log(
          'Processed messages into ${chatHistories.length} chat histories');

      // If we have no chat histories after processing messages, return empty list
      if (chatHistories.isEmpty) {
        developer
            .log('No valid chat histories found after processing messages');
        return [];
      }

      // Combine messages with metadata
      final result = chatHistories.entries.map((entry) {
        final metadata = metadataMap[entry.key] ?? {};
        return {
          'id': entry.key,
          'title': metadata['title'] ?? _generateChatTitle(entry.value.content),
          'timestamp': entry.value.timestamp,
          'isPinned': metadata['isPinned'] ?? false,
        };
      }).toList();

      developer.log('Created ${result.length} chat history entries');

      // Log the chat histories for debugging
      for (var i = 0; i < result.length; i++) {
        developer.log(
            'Chat $i: ID=${result[i]['id']}, Title=${result[i]['title']}, isPinned=${result[i]['isPinned']}');
      }

      // Detect and cleanup any orphaned metadata (metadata with no messages)
      final validChatIds = chatHistories.keys.toSet();
      final allMetadataIds = metadataMap.keys.toSet();
      final orphanedMetadataIds = allMetadataIds.difference(validChatIds);

      if (orphanedMetadataIds.isNotEmpty) {
        developer.log(
            'Found ${orphanedMetadataIds.length} orphaned metadata records - cleaning up');
        final cleanupBatch = _firestore.batch();
        for (var orphanId in orphanedMetadataIds) {
          cleanupBatch
              .delete(_firestore.collection(_chatMetadataPath).doc(orphanId));
        }
        await cleanupBatch.commit();
        developer.log('Cleaned up orphaned metadata records');
      }

      // Sort by pinned status first, then by timestamp
      result.sort((a, b) {
        if (a['isPinned'] == b['isPinned']) {
          return (b['timestamp'] as DateTime)
              .compareTo(a['timestamp'] as DateTime);
        }
        return (b['isPinned'] as bool) ? 1 : -1;
      });

      developer.log('Returning ${result.length} sorted chat histories');
      return result;
    } catch (e) {
      developer.log('Error getting chat histories: $e');
      throw Exception('Failed to get chat histories: $e');
    }
  }

  String _generateChatTitle(String content) {
    final words = content.split(' ');
    if (words.length <= 3) {
      return content;
    }
    return '${words.take(3).join(' ')}...';
  }

  Future<void> sendMessage(ChatMessage message) async {
    try {
      developer.log('=== SEND MESSAGE DEBUG START ===');
      developer.log('Checking authentication...');
      await _checkAuth();

      final user = _auth.currentUser;
      developer.log('Current Firebase user: ${user?.uid ?? "null"}');
      developer.log('Firebase app name: ${_firestore.app.name}');
      developer.log('Firebase project ID: ${_firestore.app.options.projectId}');

      developer
          .log('Sending message: ${message.id} for chat: ${message.chatId}');
      developer.log('Collection path: $_collectionPath');
      developer.log('Metadata path: $_chatMetadataPath');

      // Convert message to JSON
      final data = message.toJson();
      developer.log('Message data: $data');

      // Convert timestamp to Firestore Timestamp
      data['timestamp'] = Timestamp.fromDate(message.timestamp);

      // Create a batch to update both message and metadata
      final batch = _firestore.batch();
      developer.log('Created Firestore batch for message and metadata');

      // Add message to chats collection
      final messageRef = _firestore.collection(_collectionPath).doc(message.id);
      developer.log('Message document reference path: ${messageRef.path}');
      batch.set(messageRef, data);
      developer.log('Added message to batch: ${message.id}');

      // Update chat metadata
      final metadataRef =
          _firestore.collection(_chatMetadataPath).doc(message.chatId);
      developer.log('Metadata document reference path: ${metadataRef.path}');
      final metadataUpdate = {
        'lastMessageTime': data['timestamp'],
        'title': _generateChatTitle(message.content),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(metadataRef, metadataUpdate, SetOptions(merge: true));
      developer
          .log('Added metadata update to batch for chat: ${message.chatId}');

      // Commit the batch
      try {
        developer.log('Committing batch to Firestore...');
        await batch.commit();
        developer.log('Batch successfully committed to Firestore');

        // Verify the message was saved
        try {
          developer.log('Verifying message was saved...');
          final savedMessage = await _firestore
              .collection(_collectionPath)
              .doc(message.id)
              .get();
          developer.log('Message exists in Firestore: ${savedMessage.exists}');
          if (savedMessage.exists) {
            developer.log('Saved message data: ${savedMessage.data()}');
          }

          final savedMetadata = await _firestore
              .collection(_chatMetadataPath)
              .doc(message.chatId)
              .get();
          developer
              .log('Metadata exists in Firestore: ${savedMetadata.exists}');
          if (savedMetadata.exists) {
            developer.log('Saved metadata: ${savedMetadata.data()}');
          }
        } catch (verifyError) {
          developer.log('Error verifying saved data: $verifyError');
        }
      } catch (firestoreError) {
        developer.log('Firestore error during batch commit: $firestoreError');
        developer.log('Error details: ${firestoreError.toString()}');
        throw firestoreError;
      }

      developer.log('Message and metadata successfully saved to Firestore');
      developer.log('=== SEND MESSAGE DEBUG END ===');
    } catch (e) {
      developer.log('Error sending message: $e');
      developer.log('Error details: ${e.toString()}');
      developer.log('=== SEND MESSAGE DEBUG END WITH ERROR ===');
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _checkAuth();
      await _firestore.collection(_collectionPath).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> clearChat() async {
    try {
      await _checkAuth();
      final userId = _auth.currentUser!.uid;
      developer.log('Starting chat clear process for user: $userId');

      // Step 1: Get all messages for this user
      final userMessages = await _firestore
          .collection(_collectionPath)
          .where('senderId', isEqualTo: userId)
          .get();

      // Step 2: Get all metadata
      final allMetadata = await _firestore.collection(_chatMetadataPath).get();

      // Step 3: Get unique chat IDs from both messages and metadata
      final chatIds = {
        ...userMessages.docs.map((doc) => doc.data()['chatId'] as String),
        ...allMetadata.docs.map((doc) => doc.id),
      };

      if (chatIds.isEmpty) {
        developer.log('No chats found to clear');
        return;
      }

      developer.log('Found ${chatIds.length} chats to clear');

      // Step 4: Delete messages in batches
      for (final chatId in chatIds) {
        // Get all messages for this chat
        final messages = await _firestore
            .collection(_collectionPath)
            .where('chatId', isEqualTo: chatId)
            .get();

        // Delete messages in batches of 500 (Firestore limit)
        for (var i = 0; i < messages.docs.length; i += 500) {
          final batch = _firestore.batch();
          final end =
              (i + 500 < messages.docs.length) ? i + 500 : messages.docs.length;

          for (var j = i; j < end; j++) {
            batch.delete(messages.docs[j].reference);
          }

          await batch.commit();
          developer.log(
              'Deleted batch of messages for chat $chatId (${end - i} messages)');
        }

        // Delete chat metadata
        await _firestore.collection(_chatMetadataPath).doc(chatId).delete();
        developer.log('Deleted metadata for chat $chatId');
      }

      // Final verification
      final remainingMetadata =
          await _firestore.collection(_chatMetadataPath).get();
      final remainingMessages = await _firestore
          .collection(_collectionPath)
          .where('senderId', isEqualTo: userId)
          .get();

      if (remainingMetadata.docs.isNotEmpty ||
          remainingMessages.docs.isNotEmpty) {
        developer.log(
            'WARNING: Found remaining data after deletion. Cleaning up...');

        // Clean up any remaining metadata
        if (remainingMetadata.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in remainingMetadata.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }

        // Clean up any remaining messages
        if (remainingMessages.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in remainingMessages.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      }

      developer.log('Chat clear process completed successfully');
    } catch (e) {
      developer.log('Error clearing chat: $e');
      throw Exception('Failed to clear chat: $e');
    }
  }

  Future<void> updateChatMetadata(
      String chatId, Map<String, dynamic> updates) async {
    try {
      await _checkAuth();
      await _firestore
          .collection(_chatMetadataPath)
          .doc(chatId)
          .set(updates, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update chat metadata: $e');
    }
  }

  Future<void> updateChatPin(String chatId, bool isPinned) async {
    try {
      await updateChatMetadata(chatId, {'isPinned': isPinned});
    } catch (e) {
      throw Exception('Failed to update chat pin status: $e');
    }
  }

  Future<void> updateChatTitle(String chatId, String newTitle) async {
    try {
      await updateChatMetadata(chatId, {'title': newTitle});
    } catch (e) {
      throw Exception('Failed to update chat title: $e');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _checkAuth();
      // Delete all messages in the chat
      final messages = await _firestore
          .collection(_collectionPath)
          .where('chatId', isEqualTo: chatId)
          .get();

      final batch = _firestore.batch();

      for (var message in messages.docs) {
        batch.delete(message.reference);
      }

      // Delete chat metadata
      batch.delete(_firestore.collection(_chatMetadataPath).doc(chatId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  Future<Map<String, dynamic>> getChatMetadata(String chatId) async {
    try {
      await _checkAuth();
      final doc =
          await _firestore.collection(_chatMetadataPath).doc(chatId).get();

      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to get chat metadata: $e');
    }
  }

  Future<void> batchUpdateMetadata(
      Map<String, Map<String, dynamic>> updates) async {
    try {
      await _checkAuth();
      final batch = _firestore.batch();

      updates.forEach((chatId, data) {
        batch.set(
          _firestore.collection(_chatMetadataPath).doc(chatId),
          data,
          SetOptions(merge: true),
        );
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update metadata: $e');
    }
  }

  Future<String> createNewChat({String? title}) async {
    try {
      await _checkAuth();

      final userId = _auth.currentUser!.uid;
      developer.log('Creating new chat for user: $userId');

      final chatId = const Uuid().v4();
      developer.log('Generated new chat ID: $chatId');

      // Create the metadata object
      final metadata = {
        'title': title ?? 'New Chat',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': userId,
        'isPinned': false,
      };

      developer.log('Preparing to save chat metadata: $metadata');

      // Create chat metadata
      try {
        developer.log(
            'Saving metadata to Firestore path: $_chatMetadataPath/${chatId}');
        await _firestore
            .collection(_chatMetadataPath)
            .doc(chatId)
            .set(metadata);
        developer.log('Successfully saved chat metadata to Firestore');
      } catch (firestoreError) {
        developer.log('Firestore error while saving metadata: $firestoreError');
        throw firestoreError;
      }

      developer.log('Created new chat with ID: $chatId');
      return chatId;
    } catch (e) {
      developer.log('Error creating new chat: $e');
      throw Exception('Failed to create new chat: $e');
    }
  }

  // Test function to directly create a chat and send a message
  Future<void> testFirestoreConnection() async {
    try {
      developer.log('Starting Firestore connection test');

      // Check authentication
      await _checkAuth();
      final userId = _auth.currentUser?.uid;
      developer.log('Current user ID: $userId');

      if (userId == null) {
        developer.log('No authenticated user found, test failed');
        return;
      }

      // Test creating a chat
      final chatId = const Uuid().v4();
      developer.log('Test chat ID: $chatId');

      // Create test metadata
      final metadata = {
        'title': 'Test Chat',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': userId,
        'isPinned': false,
        'testField': 'This is a test',
      };

      // Save to Firestore
      developer.log('Saving test metadata to Firestore');
      await _firestore.collection(_chatMetadataPath).doc(chatId).set(metadata);
      developer.log('Test metadata saved successfully');

      // Create a test message
      final messageId = const Uuid().v4();
      final messageData = {
        'id': messageId,
        'chat_id': chatId,
        'sender_id': userId,
        'content': 'This is a test message',
        'timestamp': Timestamp.now(),
        'is_ai': false,
      };

      // Save message to Firestore
      developer.log('Saving test message to Firestore');
      await _firestore
          .collection(_collectionPath)
          .doc(messageId)
          .set(messageData);
      developer.log('Test message saved successfully');

      // Verify data was saved
      developer.log('Verifying data was saved');
      final savedMetadata =
          await _firestore.collection(_chatMetadataPath).doc(chatId).get();
      final savedMessage =
          await _firestore.collection(_collectionPath).doc(messageId).get();

      developer.log('Metadata exists: ${savedMetadata.exists}');
      if (savedMetadata.exists) {
        developer.log('Saved metadata: ${savedMetadata.data()}');
      }

      developer.log('Message exists: ${savedMessage.exists}');
      if (savedMessage.exists) {
        developer.log('Saved message: ${savedMessage.data()}');
      }

      developer.log('Firestore connection test completed successfully');
    } catch (e) {
      developer.log('Error in Firestore connection test: $e');
    }
  }

  // Function to check Firebase project status
  Future<Map<String, dynamic>> checkFirebaseStatus() async {
    try {
      developer.log('Checking Firebase project status');

      // Check Firebase Auth
      final authStatus =
          _auth.currentUser != null ? 'authenticated' : 'not authenticated';
      developer.log('Firebase Auth status: $authStatus');

      // Try to sign in anonymously if not authenticated
      if (_auth.currentUser == null) {
        try {
          developer
              .log('Attempting anonymous sign-in for Firebase status check');
          final userCredential = await _auth.signInAnonymously();
          developer
              .log('Anonymous sign-in successful: ${userCredential.user?.uid}');
        } catch (authError) {
          developer.log('Anonymous sign-in failed: $authError');
          return {
            'status': 'error',
            'auth': 'authentication failed',
            'error': 'Failed to authenticate: $authError',
          };
        }
      }

      // Try to get a document from Firestore to check connection
      try {
        developer.log('Testing Firestore read connection');
        final testDoc =
            await _firestore.collection('_test_connection').doc('test').get();
        developer.log(
            'Firestore read test: ${testDoc.exists ? 'document exists' : 'document does not exist'}');
      } catch (firestoreError) {
        developer.log('Firestore read error: $firestoreError');

        // Check if it's a network connectivity issue
        if (firestoreError.toString().contains('network') ||
            firestoreError.toString().contains('connection') ||
            firestoreError.toString().contains('socket')) {
          return {
            'status': 'error',
            'auth': authStatus,
            'firestore': 'network error',
            'error': 'Network connectivity issue: $firestoreError',
          };
        }

        // If it's a permission error, we can still try to write
        developer.log('Proceeding with write test despite read error');
      }

      // Check if we can write to Firestore
      try {
        developer.log('Testing Firestore write connection');
        final testId = DateTime.now().millisecondsSinceEpoch.toString();
        final testData = {
          'timestamp': FieldValue.serverTimestamp(),
          'test': true,
          'device': 'mobile',
          'testId': testId,
        };

        await _firestore
            .collection('_test_connection')
            .doc(testId)
            .set(testData);
        developer.log('Firestore write test: successful');

        // Verify the write was successful by reading it back
        final verifyDoc =
            await _firestore.collection('_test_connection').doc(testId).get();
        developer.log(
            'Firestore write verification: ${verifyDoc.exists ? 'successful' : 'failed'}');

        // Clean up test document
        await _firestore.collection('_test_connection').doc(testId).delete();
        developer.log('Firestore cleanup: successful');
      } catch (writeError) {
        developer.log('Firestore write error: $writeError');

        // Check if it's a network connectivity issue
        if (writeError.toString().contains('network') ||
            writeError.toString().contains('connection') ||
            writeError.toString().contains('socket')) {
          return {
            'status': 'error',
            'auth': authStatus,
            'firestore': 'network error',
            'error': 'Network connectivity issue: $writeError',
          };
        }

        // Check if it's a permission error
        if (writeError.toString().contains('permission') ||
            writeError.toString().contains('denied') ||
            writeError.toString().contains('unauthorized')) {
          return {
            'status': 'error',
            'auth': authStatus,
            'firestore': 'permission error',
            'error': 'Firestore permission denied: $writeError',
          };
        }

        return {
          'status': 'error',
          'auth': authStatus,
          'firestore': 'write error',
          'error': 'Failed to write to Firestore: $writeError',
        };
      }

      return {
        'status': 'ok',
        'auth': authStatus,
        'firestore': 'connected',
        'projectId': _firestore.app.options.projectId,
      };
    } catch (e) {
      developer.log('Error checking Firebase status: $e');
      return {
        'status': 'error',
        'error': 'General Firebase error: $e',
      };
    }
  }

  // Function to directly test Firestore collection creation
  Future<Map<String, dynamic>> testFirestoreCollectionCreation() async {
    try {
      developer.log('=== TESTING FIRESTORE COLLECTION CREATION ===');

      // Check authentication
      developer.log('Checking authentication...');
      final user = _auth.currentUser;
      developer.log('Current Firebase user: ${user?.uid ?? "null"}');

      if (user == null) {
        developer.log('No authenticated user, attempting anonymous sign-in...');
        try {
          final userCredential = await _auth.signInAnonymously();
          developer
              .log('Anonymous sign-in successful: ${userCredential.user?.uid}');
        } catch (authError) {
          developer.log('Anonymous sign-in failed: $authError');
          return {
            'success': false,
            'error': 'Authentication failed: $authError',
          };
        }
      }

      // Log Firebase configuration
      developer.log('Firebase app name: ${_firestore.app.name}');
      developer.log('Firebase project ID: ${_firestore.app.options.projectId}');
      developer.log('Collection path: $_collectionPath');
      developer.log('Metadata path: $_chatMetadataPath');

      // Create test document IDs
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final chatId = 'chat_$testId';
      final messageId = 'msg_$testId';

      developer.log('Test chat ID: $chatId');
      developer.log('Test message ID: $messageId');

      // Create test data
      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': _auth.currentUser?.uid ?? 'anonymous',
        'content': 'Test message for collection creation',
        'timestamp': Timestamp.now(),
        'isAI': false,
      };

      final metadataData = {
        'title': 'Test Chat',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid ?? 'anonymous',
        'isPinned': false,
      };

      // Try to write directly to collections
      developer.log(
          'Attempting to write test message to $_collectionPath collection...');
      try {
        await _firestore
            .collection(_collectionPath)
            .doc(messageId)
            .set(messageData);
        developer.log(
            'Successfully wrote test message to $_collectionPath collection');
      } catch (messageError) {
        developer.log('Error writing test message: $messageError');
        return {
          'success': false,
          'error': 'Failed to write message: $messageError',
        };
      }

      developer.log(
          'Attempting to write test metadata to $_chatMetadataPath collection...');
      try {
        await _firestore
            .collection(_chatMetadataPath)
            .doc(chatId)
            .set(metadataData);
        developer.log(
            'Successfully wrote test metadata to $_chatMetadataPath collection');
      } catch (metadataError) {
        developer.log('Error writing test metadata: $metadataError');
        return {
          'success': false,
          'error': 'Failed to write metadata: $metadataError',
        };
      }

      // Verify the documents were created
      developer.log('Verifying test documents were created...');
      try {
        final messageDoc =
            await _firestore.collection(_collectionPath).doc(messageId).get();
        final metadataDoc =
            await _firestore.collection(_chatMetadataPath).doc(chatId).get();

        developer.log('Message document exists: ${messageDoc.exists}');
        developer.log('Metadata document exists: ${metadataDoc.exists}');

        if (messageDoc.exists && metadataDoc.exists) {
          developer.log('Both test documents were successfully created!');

          // Clean up test documents
          developer.log('Cleaning up test documents...');
          await _firestore.collection(_collectionPath).doc(messageId).delete();
          await _firestore.collection(_chatMetadataPath).doc(chatId).delete();
          developer.log('Test documents deleted');

          return {
            'success': true,
            'message':
                'Successfully created and verified Firestore collections',
            'collections': [_collectionPath, _chatMetadataPath],
          };
        } else {
          developer.log('One or both test documents were not created');
          return {
            'success': false,
            'error': 'Documents were not created properly',
            'messageExists': messageDoc.exists,
            'metadataExists': metadataDoc.exists,
          };
        }
      } catch (verifyError) {
        developer.log('Error verifying test documents: $verifyError');
        return {
          'success': false,
          'error': 'Failed to verify documents: $verifyError',
        };
      }
    } catch (e) {
      developer.log('Error in testFirestoreCollectionCreation: $e');
      return {
        'success': false,
        'error': 'General error: $e',
      };
    } finally {
      developer.log('=== FIRESTORE COLLECTION CREATION TEST COMPLETE ===');
    }
  }

  // Check Firestore security rules by attempting to read from collections
  Future<Map<String, dynamic>> checkFirestoreSecurityRules() async {
    try {
      developer.log('Checking Firestore security rules...');

      // Check authentication first
      await _checkAuth();

      final Map<String, dynamic> result = {
        'success': true,
        'collections': <String, bool>{},
        'details': <String, String>{},
      };

      final Map<String, bool> collections =
          result['collections'] as Map<String, bool>;
      final Map<String, String> details =
          result['details'] as Map<String, String>;

      // Try to read from chat_metadata collection
      try {
        final metadataSnapshot =
            await _firestore.collection(_chatMetadataPath).limit(1).get();
        collections['chat_metadata'] = true;
        details['chat_metadata'] =
            'Read successful, found ${metadataSnapshot.docs.length} documents';
        developer.log('Successfully read from chat_metadata collection');
      } catch (e) {
        collections['chat_metadata'] = false;
        details['chat_metadata'] = 'Read failed: $e';
        result['success'] = false;
        developer.log('Failed to read from chat_metadata collection: $e');
      }

      // Try to read from chats collection
      try {
        final chatsSnapshot =
            await _firestore.collection(_collectionPath).limit(1).get();
        collections['chats'] = true;
        details['chats'] =
            'Read successful, found ${chatsSnapshot.docs.length} documents';
        developer.log('Successfully read from chats collection');
      } catch (e) {
        collections['chats'] = false;
        details['chats'] = 'Read failed: $e';
        result['success'] = false;
        developer.log('Failed to read from chats collection: $e');
      }

      // Try to write to chat_metadata collection
      try {
        final testDocId = 'test_${DateTime.now().millisecondsSinceEpoch}';
        final testData = {
          'title': 'Test Chat',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': _auth.currentUser?.uid ?? 'anonymous',
          'isPinned': false,
          'isTest': true,
        };

        await _firestore
            .collection(_chatMetadataPath)
            .doc(testDocId)
            .set(testData);
        collections['chat_metadata_write'] = true;
        details['chat_metadata_write'] = 'Write successful';
        developer.log('Successfully wrote to chat_metadata collection');

        // Clean up the test document
        await _firestore.collection(_chatMetadataPath).doc(testDocId).delete();
      } catch (e) {
        collections['chat_metadata_write'] = false;
        details['chat_metadata_write'] = 'Write failed: $e';
        result['success'] = false;
        developer.log('Failed to write to chat_metadata collection: $e');
      }

      return result;
    } catch (e) {
      developer.log('Error checking Firestore security rules: $e');
      return {
        'success': false,
        'error': 'Error checking Firestore security rules: $e',
      };
    }
  }
}
