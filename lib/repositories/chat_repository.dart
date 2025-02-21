import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'chats';

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ChatMessage>> getChatMessages() {
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
    return _firestore
        .collection(_collectionPath)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()))
            .toList());
  }

  Future<List<Map<String, dynamic>>> getChatHistories() async {
    try {
      developer.log('Getting chat histories');
      
      // Get all messages ordered by timestamp
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionPath)
          .orderBy('timestamp', descending: true)
          .get();

      developer.log('Retrieved ${snapshot.docs.length} messages');

      // Convert to ChatMessage objects
      final List<ChatMessage> messages = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          messages.add(ChatMessage.fromJson(data));
        } catch (e) {
          developer.log('Error parsing message: $e');
        }
      }

      developer.log('Parsed ${messages.length} valid messages');

      // Group messages by chatId
      final Map<String, ChatMessage> chatHistories = {};
      for (var message in messages) {
        if (!chatHistories.containsKey(message.chatId) ||
            message.timestamp.isAfter(chatHistories[message.chatId]!.timestamp)) {
          chatHistories[message.chatId] = message;
        }
      }

      developer.log('Found ${chatHistories.length} unique chats');

      // Convert to list and sort by timestamp
      final result = chatHistories.values
          .map((message) => {
                'id': message.chatId,
                'title': _generateChatTitle(message.content),
                'timestamp': message.timestamp,
              })
          .toList()
        ..sort((a, b) => (b['timestamp'] as DateTime)
            .compareTo(a['timestamp'] as DateTime));

      developer.log('Returning ${result.length} chat histories');
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
      developer.log('Sending message: ${message.id} for chat: ${message.chatId}');
      final data = message.toJson();
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
      await _firestore.collection(_collectionPath).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> clearChat() async {
    try {
      final batch = _firestore.batch();
      final messages = await _firestore.collection(_collectionPath).get();
      
      for (var message in messages.docs) {
        batch.delete(message.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear chat: $e');
    }
  }
} 