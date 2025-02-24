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
          })
          .handleError((error) {
            developer.log('Error in getChatMessagesForId: $error');
            throw error;
          });
    } catch (e) {
      developer.log('Error setting up chat stream: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistories() async {
    try {
      _checkAuth();
      developer.log('Getting chat histories');
      
      // Get all metadata in a single query
      final metadataSnapshot = await _firestore
          .collection(_chatMetadataPath)
          .get();
      
      final metadataMap = Map.fromEntries(
        metadataSnapshot.docs.map((doc) => MapEntry(doc.id, doc.data()))
      );

      // Get latest messages for each chat
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionPath)
          .orderBy('timestamp', descending: true)
          .limit(100) // Limit to latest 100 messages
          .get();

      developer.log('Retrieved ${snapshot.docs.length} messages');

      final Map<String, ChatMessage> chatHistories = {};
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final message = ChatMessage.fromJson(data);
          
          if (!chatHistories.containsKey(message.chatId) ||
              message.timestamp.isAfter(chatHistories[message.chatId]!.timestamp)) {
            chatHistories[message.chatId] = message;
          }
        } catch (e) {
          developer.log('Error parsing message: $e');
        }
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

      // Sort by pinned status first, then by timestamp
      result.sort((a, b) {
        if (a['isPinned'] == b['isPinned']) {
          return (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime);
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
      developer.log('Sending message: ${message.id} for chat: ${message.chatId}');
      final data = message.toJson();
      
      // Convert timestamp to Firestore Timestamp
      data['timestamp'] = Timestamp.fromDate(message.timestamp);
      
      await _firestore
          .collection(_collectionPath)
          .doc(message.id)
          .set(data);
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
      developer.log('Starting chat clear process...');
      
      // Clear chat metadata first
      developer.log('Clearing chat metadata...');
      final metadataBatch = _firestore.batch();
      final allMetadata = await _firestore
          .collection(_chatMetadataPath)
          .get();
      
      for (var doc in allMetadata.docs) {
        metadataBatch.delete(doc.reference);
      }
      await metadataBatch.commit();
      developer.log('Cleared ${allMetadata.docs.length} metadata entries');
      
      // Then clear messages
      developer.log('Clearing chat messages...');
      final messageBatch = _firestore.batch();
      final allMessages = await _firestore
          .collection(_collectionPath)
          .get();
      
      for (var doc in allMessages.docs) {
        messageBatch.delete(doc.reference);
      }
      await messageBatch.commit();
      developer.log('Cleared ${allMessages.docs.length} messages');
      
      // Create empty collections if they don't exist
      await _firestore.collection(_collectionPath).doc('placeholder').set({
        'id': 'placeholder',
        'content': 'placeholder',
        'timestamp': Timestamp.now(),
        'isAI': false,
        'senderId': 'system',
        'chatId': 'placeholder'
      });
      await _firestore.collection(_chatMetadataPath).doc('placeholder').set({
        'title': 'placeholder',
        'isPinned': false
      });
      
      // Delete the placeholders
      await _firestore.collection(_collectionPath).doc('placeholder').delete();
      await _firestore.collection(_chatMetadataPath).doc('placeholder').delete();
      
      developer.log('Chat clear process completed successfully');
    } catch (e) {
      developer.log('Error clearing chat: $e');
      throw Exception('Failed to clear chat: $e');
    }
  }

  Future<void> updateChatMetadata(String chatId, Map<String, dynamic> updates) async {
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
      final doc = await _firestore
          .collection(_chatMetadataPath)
          .doc(chatId)
          .get();
      
      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to get chat metadata: $e');
    }
  }

  Future<void> batchUpdateMetadata(Map<String, Map<String, dynamic>> updates) async {
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