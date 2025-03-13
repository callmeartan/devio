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
      _checkAuth();
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
          },
          SetOptions(merge: true));

      // Commit the batch
      await batch.commit();
      developer.log('Message and metadata successfully saved to Firestore');
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
