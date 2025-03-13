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

  void _checkAuth() {
    final user = _auth.currentUser;
    developer.log('Current auth state - User: ${user?.uid ?? 'null'}');
    if (user == null) {
      throw Exception('User must be authenticated to access chat data');
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
          .orderBy('timestamp', descending: true)
          .limit(50) // Reduce limit for faster initial load
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()))
            .toList();
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
      _checkAuth();
      developer
          .log('Sending message: ${message.id} for chat: ${message.chatId}');
      final data = message.toJson();

      // Convert timestamp to Firestore Timestamp
      data['timestamp'] = Timestamp.fromDate(message.timestamp);

      await _firestore.collection(_collectionPath).doc(message.id).set(data);
      developer.log('Message sent successfully');
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

  Future<void> clearChat() async {
    try {
      _checkAuth();
      final userId = _auth.currentUser!.uid;
      developer.log('Starting chat clear process for user: $userId');

      // Step 1: Get all metadata first - this ensures we capture ALL chats
      final allMetadata = await _firestore.collection(_chatMetadataPath).get();
      developer.log('Found ${allMetadata.docs.length} total metadata records');

      // Step 2: Also search for chats where the user participated (as sender or recipient)
      final userSentMessages = await _firestore
          .collection(_collectionPath)
          .where('senderId', isEqualTo: userId)
          .get();

      // Get messages addressed to this user (AI responses) - if your schema supports this
      // If you don't store recipient info, you might need a different approach
      final messageChatIds = userSentMessages.docs
          .map((doc) => (doc.data()['chatId'] as String))
          .toSet()
          .toList();

      developer
          .log('Found ${messageChatIds.length} chats from message queries');

      // Step 3: Combine all chat IDs from metadata and messages
      final chatIds = [
        ...messageChatIds,
        ...allMetadata.docs.map((doc) => doc.id),
      ].toSet().toList(); // Use set to remove duplicates

      developer.log('Combined ${chatIds.length} unique chat IDs to process');

      if (chatIds.isEmpty) {
        developer.log('No chats to clear, operation completed successfully');
        return;
      }

      // Step 4: Delete ALL chat records from Firestore

      // Clear chat metadata first
      developer.log('Clearing chat metadata...');
      final metadataBatch = _firestore.batch();
      for (var chatId in chatIds) {
        metadataBatch
            .delete(_firestore.collection(_chatMetadataPath).doc(chatId));
      }
      await metadataBatch.commit();
      developer.log('Cleared metadata for ${chatIds.length} chats');

      // Step 5: Now delete ALL messages
      developer.log('Starting to clear chat messages...');
      int totalMessagesDeleted = 0;

      // Process in smaller batches to avoid transaction limits
      final batchSize = 20;
      for (var i = 0; i < chatIds.length; i += batchSize) {
        final currentBatchEnd =
            (i + batchSize < chatIds.length) ? i + batchSize : chatIds.length;
        final currentBatch = chatIds.sublist(i, currentBatchEnd);

        developer.log(
            'Processing batch ${i ~/ batchSize + 1} with ${currentBatch.length} chats');

        // For each chat in the current batch
        for (var chatId in currentBatch) {
          try {
            // Get all messages for this chat (including AI responses)
            final chatMessages = await _firestore
                .collection(_collectionPath)
                .where('chatId', isEqualTo: chatId)
                .get();

            if (chatMessages.docs.isEmpty) {
              developer.log('No messages found for chat $chatId');
              continue;
            }

            // Use batch to delete these messages
            // Split into smaller batches if needed (Firestore has a limit of 500 ops per batch)
            final maxBatchSize = 400; // Keep well below the 500 limit
            for (var j = 0; j < chatMessages.docs.length; j += maxBatchSize) {
              final end = (j + maxBatchSize < chatMessages.docs.length)
                  ? j + maxBatchSize
                  : chatMessages.docs.length;

              final messageBatch = _firestore.batch();
              for (var k = j; k < end; k++) {
                messageBatch.delete(chatMessages.docs[k].reference);
              }

              await messageBatch.commit();
              int batchCount = end - j;
              totalMessagesDeleted += batchCount;
              developer.log('Deleted $batchCount messages from chat $chatId');
            }
          } catch (e) {
            // Log but continue with other chats
            developer.log('Error clearing messages for chat $chatId: $e');
          }
        }
      }

      // Step 6: Verify deletion by checking for any remaining metadata
      final remainingMetadata =
          await _firestore.collection(_chatMetadataPath).get();
      if (remainingMetadata.docs.isNotEmpty) {
        developer.log(
            'WARNING: ${remainingMetadata.docs.length} metadata records remain after deletion');

        // Try one more time to delete any remaining metadata
        final finalCleanupBatch = _firestore.batch();
        for (var doc in remainingMetadata.docs) {
          finalCleanupBatch.delete(doc.reference);
        }
        await finalCleanupBatch.commit();
        developer.log('Performed final cleanup of remaining metadata');
      }

      developer.log(
          'Chat clear process completed successfully - Deleted $totalMessagesDeleted total messages');
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
