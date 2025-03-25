import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/chat_message.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<User?> _checkAuth() async {
    final user = _auth.currentUser;
    developer.log('Current auth state - User: ${user?.uid ?? 'null'}');

    if (user == null) {
      developer.log('User is null, attempting to refresh auth state');
      // Try to refresh the auth state
      try {
        await _auth.authStateChanges().first;
        final refreshedUser = _auth.currentUser;

        if (refreshedUser == null) {
          developer.log('Still no authenticated user after refresh');
          throw FirebaseException(
              plugin: 'firebase_auth',
              code: 'user-not-authenticated',
              message: 'User must be authenticated to access chat data');
        }

        return refreshedUser;
      } catch (e) {
        developer.log('Error refreshing auth state: $e');
        throw FirebaseException(
            plugin: 'firebase_auth',
            code: 'user-not-authenticated',
            message: 'User must be authenticated to access chat data');
      }
    }

    // Verify the token isn't expired by getting the ID token
    try {
      // Just check token without force refreshing to avoid token renewal issues
      await user.getIdToken();
      return user;
    } catch (e) {
      developer.log('Error getting token: $e');
      throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'token-expired',
          message: 'Authentication token expired, please sign in again');
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
      _checkAuth();
      developer.log('Getting messages for chat: $chatId');

      return _firestore
          .collection(_collectionPath)
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()))
            .toList();

        developer
            .log('Retrieved ${messages.length} messages for chat: $chatId');
        return messages;
      }).handleError((error) {
        developer.log('Error in getChatMessagesForId: $error');
        throw error;
      });
    } catch (e) {
      developer.log('Error setting up chat stream: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistories() async {
    try {
      _checkAuth();
      developer.log('Getting chat histories');

      // Get all metadata in a single query
      final metadataSnapshot =
          await _firestore.collection(_chatMetadataPath).get();

      developer
          .log('Retrieved ${metadataSnapshot.docs.length} metadata documents');

      // If we don't have any metadata, return an empty list early
      if (metadataSnapshot.docs.isEmpty) {
        developer.log('No chat metadata found, returning empty list');
        return [];
      }

      final metadataMap = Map.fromEntries(
          metadataSnapshot.docs.map((doc) => MapEntry(doc.id, doc.data())));

      // Get latest messages for each chat
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionPath)
          .orderBy('timestamp', descending: true)
          .limit(100) // Limit to latest 100 messages
          .get();

      developer.log('Retrieved ${snapshot.docs.length} messages');

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
      // Check authentication
      final user = await _checkAuth();

      // If this is an AI message, don't check the sender ID
      if (!message.isAI && user?.uid != message.senderId) {
        // Only verify sender ID for non-AI messages
        developer.log(
            'User auth mismatch: ${user?.uid} trying to send message as ${message.senderId}');
        throw FirebaseException(
            plugin: 'firebase_auth',
            code: 'permission-denied',
            message: 'User not authorized to send this message');
      }

      developer
          .log('Sending message: ${message.id} for chat: ${message.chatId}');

      // Convert message to JSON
      final data = message.toJson();

      // Convert timestamp to Firestore Timestamp
      data['timestamp'] = Timestamp.fromDate(message.timestamp);

      // Create a batch to update both message and metadata
      final batch = _firestore.batch();

      // Add message to chats collection
      final messageRef = _firestore.collection(_collectionPath).doc(message.id);
      batch.set(messageRef, data);

      // Update chat metadata
      final metadataRef =
          _firestore.collection(_chatMetadataPath).doc(message.chatId);
      batch.set(
          metadataRef,
          {
            'lastMessageTime': data['timestamp'],
            'title': _generateChatTitle(message.content),
            'userId': user?.uid, // Store the user ID who owns this chat
          },
          SetOptions(merge: true));

      // Commit the batch
      await batch.commit();
      developer.log('Message and metadata successfully saved to Firestore');
    } on FirebaseException catch (e) {
      developer.log('Firebase error sending message: ${e.code} - ${e.message}');

      // Don't sign out the user - just report the error
      // This allows the UI to handle the error appropriately
      throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      developer.log('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      _checkAuth();
      await _firestore.collection(_collectionPath).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Update message content
  Future<void> updateMessageContent(String messageId, String newContent) async {
    try {
      _checkAuth();
      developer.log('Updating message content for message: $messageId');

      // Get the message to update
      final messageRef = _firestore.collection(_collectionPath).doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        throw Exception('Message not found: $messageId');
      }

      // Update the message content
      await messageRef.update({
        'content': newContent,
      });

      // Get the updated message to update the chat metadata
      final updatedMessage = await messageRef.get();
      final messageData = updatedMessage.data() as Map<String, dynamic>;
      final chatId = messageData['chatId'] as String;

      // Update chat metadata with the potentially new title
      final metadataRef = _firestore.collection(_chatMetadataPath).doc(chatId);
      await metadataRef.update({
        'title': _generateChatTitle(newContent),
      });

      developer.log('Message content and metadata updated successfully');
    } catch (e) {
      developer.log('Error updating message content: $e');
      throw Exception('Failed to update message content: $e');
    }
  }

  // Update message metrics with better error handling
  Future<void> updateMessageMetrics(
    String messageId, {
    double? totalDuration,
    double? loadDuration,
    int? promptEvalCount,
    double? promptEvalDuration,
    double? promptEvalRate,
    int? evalCount,
    double? evalDuration,
    double? evalRate,
  }) async {
    try {
      final user = await _checkAuth();
      if (user == null) {
        developer.log('No authenticated user, skipping metrics update');
        return; // Silently skip updating metrics if not authenticated
      }

      developer.log('Updating metrics for message: $messageId');

      // First, check if message exists
      final messageRef = _firestore.collection(_collectionPath).doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        developer
            .log('Message does not exist, skipping metrics update: $messageId');
        return; // Silently skip if message doesn't exist
      }

      // Prepare the updates - only include non-null values
      final updates = <String, dynamic>{};

      if (totalDuration != null) updates['totalDuration'] = totalDuration;
      if (loadDuration != null) updates['loadDuration'] = loadDuration;
      if (promptEvalCount != null) updates['promptEvalCount'] = promptEvalCount;
      if (promptEvalDuration != null)
        updates['promptEvalDuration'] = promptEvalDuration;
      if (promptEvalRate != null) updates['promptEvalRate'] = promptEvalRate;
      if (evalCount != null) updates['evalCount'] = evalCount;
      if (evalDuration != null) updates['evalDuration'] = evalDuration;
      if (evalRate != null) updates['evalRate'] = evalRate;

      if (updates.isEmpty) {
        developer.log('No metrics to update');
        return;
      }

      // Update the message metrics
      await messageRef.update(updates);
      developer.log('Message metrics updated successfully');
    } on FirebaseException catch (e) {
      developer
          .log('Firebase error updating metrics: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        // Special handling for permission errors - log but don't throw
        developer.log(
            'Permission denied when updating metrics - this is expected for some message types');
        // We're intentionally not throwing here to avoid disrupting the user experience
      } else {
        // For other Firebase errors, we still throw
        throw Exception('Failed to update message metrics: ${e.message}');
      }
    } catch (e) {
      developer.log('Error updating message metrics: $e');
      // For general errors, we log but don't throw to avoid disrupting the user experience
      // This makes the metrics update "best-effort" rather than required
    }
  }

  Future<void> clearChat() async {
    try {
      _checkAuth();
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
      _checkAuth();
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
      _checkAuth();
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
      _checkAuth();
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
      _checkAuth();
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
}
