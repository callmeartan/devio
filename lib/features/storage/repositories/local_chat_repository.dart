import 'package:devio/features/storage/services/local_database_service.dart';
import 'package:devio/models/chat_message.dart';
import 'dart:developer' as developer;

/// Repository for handling chat operations in Local Mode
class LocalChatRepository {
  final LocalDatabaseService _databaseService;

  LocalChatRepository({LocalDatabaseService? databaseService})
      : _databaseService = databaseService ?? LocalDatabaseService();

  // CHAT OPERATIONS

  /// Creates a new chat
  Future<String> createChat(String title) async {
    try {
      return await _databaseService.createChat(title);
    } catch (e) {
      developer.log('Error in LocalChatRepository.createChat: $e');
      rethrow;
    }
  }

  /// Gets all chats
  Future<List<Map<String, dynamic>>> getChats(
      {bool includePinned = true}) async {
    try {
      return await _databaseService.getChats(includePinned: includePinned);
    } catch (e) {
      developer.log('Error in LocalChatRepository.getChats: $e');
      rethrow;
    }
  }

  /// Gets pinned chats
  Future<List<Map<String, dynamic>>> getPinnedChats() async {
    try {
      return await _databaseService.getPinnedChats();
    } catch (e) {
      developer.log('Error in LocalChatRepository.getPinnedChats: $e');
      rethrow;
    }
  }

  /// Updates a chat
  Future<void> updateChat(String chatId,
      {String? title, bool? isPinned}) async {
    try {
      await _databaseService.updateChat(chatId,
          title: title, isPinned: isPinned);
    } catch (e) {
      developer.log('Error in LocalChatRepository.updateChat: $e');
      rethrow;
    }
  }

  /// Deletes a chat (soft delete)
  Future<void> deleteChat(String chatId) async {
    try {
      await _databaseService.deleteChat(chatId);
    } catch (e) {
      developer.log('Error in LocalChatRepository.deleteChat: $e');
      rethrow;
    }
  }

  /// Permanently deletes a chat and all its messages
  Future<void> permanentlyDeleteChat(String chatId) async {
    try {
      await _databaseService.permanentlyDeleteChat(chatId);
    } catch (e) {
      developer.log('Error in LocalChatRepository.permanentlyDeleteChat: $e');
      rethrow;
    }
  }

  /// Clears all chats and messages
  Future<void> clearChat() async {
    try {
      developer.log('Clearing all chats and messages from local database');
      // Get all chats
      final chats = await getChats();

      // Delete each chat
      for (final chat in chats) {
        final chatId = chat['id'] as String;
        await permanentlyDeleteChat(chatId);
      }

      developer.log('All chats and messages cleared from local database');
    } catch (e) {
      developer.log('Error in LocalChatRepository.clearChat: $e');
      rethrow;
    }
  }

  /// Updates a chat's pin status
  Future<void> updateChatPin(String chatId, bool isPinned) async {
    try {
      developer.log('Updating chat pin status: $chatId, isPinned: $isPinned');
      await updateChat(chatId, isPinned: isPinned);
    } catch (e) {
      developer.log('Error in LocalChatRepository.updateChatPin: $e');
      rethrow;
    }
  }

  /// Updates a chat's title
  Future<void> updateChatTitle(String chatId, String title) async {
    try {
      developer.log('Updating chat title: $chatId, title: $title');
      await updateChat(chatId, title: title);
    } catch (e) {
      developer.log('Error in LocalChatRepository.updateChatTitle: $e');
      rethrow;
    }
  }

  // MESSAGE OPERATIONS

  /// Adds a message to a chat
  Future<void> addMessage(ChatMessage message) async {
    try {
      await _databaseService.addMessage(message);
    } catch (e) {
      developer.log('Error in LocalChatRepository.addMessage: $e');
      rethrow;
    }
  }

  /// Gets messages for a chat
  Future<List<ChatMessage>> getMessages(String chatId,
      {int limit = 50, int offset = 0}) async {
    try {
      return await _databaseService.getMessages(chatId,
          limit: limit, offset: offset);
    } catch (e) {
      developer.log('Error in LocalChatRepository.getMessages: $e');
      rethrow;
    }
  }

  /// Sends a message to a chat (alias for addMessage to match CloudRepository interface)
  Future<void> sendMessage(ChatMessage message) async {
    try {
      developer.log('Sending message to local database: ${message.id}');
      await addMessage(message);
    } catch (e) {
      developer.log('Error in LocalChatRepository.sendMessage: $e');
      rethrow;
    }
  }

  /// Updates a message
  Future<void> updateMessage(String messageId, {String? content}) async {
    try {
      await _databaseService.updateMessage(messageId, content: content);
    } catch (e) {
      developer.log('Error in LocalChatRepository.updateMessage: $e');
      rethrow;
    }
  }

  /// Deletes a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _databaseService.deleteMessage(messageId);
    } catch (e) {
      developer.log('Error in LocalChatRepository.deleteMessage: $e');
      rethrow;
    }
  }

  /// Adds a user message and an AI response to a chat
  Future<void> addConversation(String chatId, String userId, String userMessage,
      String aiResponse) async {
    try {
      // Create user message
      final userChatMessage = ChatMessage.user(
        chatId: chatId,
        content: userMessage,
        userId: userId,
      );

      // Create AI message
      final aiChatMessage = ChatMessage.ai(
        chatId: chatId,
        content: aiResponse,
        userId: 'ai',
      );

      // Add both messages
      await addMessage(userChatMessage);
      await addMessage(aiChatMessage);
    } catch (e) {
      developer.log('Error in LocalChatRepository.addConversation: $e');
      rethrow;
    }
  }

  /// Exports chat data as JSON
  Future<Map<String, dynamic>> exportChatData(String chatId) async {
    try {
      // Get chat details
      final chats = await _databaseService.getChats();
      final chat = chats.firstWhere((c) => c['id'] == chatId, orElse: () => {});

      if (chat.isEmpty) {
        throw Exception('Chat not found');
      }

      // Get messages
      final messages = await _databaseService.getMessages(chatId, limit: 1000);

      // Create export data
      final exportData = {
        'chat': chat,
        'messages': messages.map((m) => m.toJson()).toList(),
        'exported_at': DateTime.now().toIso8601String(),
      };

      return exportData;
    } catch (e) {
      developer.log('Error in LocalChatRepository.exportChatData: $e');
      rethrow;
    }
  }

  /// Searches for messages containing the query
  Future<List<ChatMessage>> searchMessages(String query) async {
    try {
      final db = await _databaseService.database;

      final result = await db.query(
        LocalDatabaseService.tableMessages,
        where: 'content LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'timestamp DESC',
      );

      return result.map((map) => _mapToMessage(map)).toList();
    } catch (e) {
      developer.log('Error in LocalChatRepository.searchMessages: $e');
      rethrow;
    }
  }

  /// Helper method to convert database map to ChatMessage
  ChatMessage _mapToMessage(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isAI: (map['is_ai'] as int) == 1,
      senderName: map['sender_name'] as String?,
      totalDuration: map['total_duration'] as double?,
      loadDuration: map['load_duration'] as double?,
      promptEvalCount: map['prompt_eval_count'] as int?,
      promptEvalDuration: map['prompt_eval_duration'] as double?,
      promptEvalRate: map['prompt_eval_rate'] as double?,
      evalCount: map['eval_count'] as int?,
      evalDuration: map['eval_duration'] as double?,
      evalRate: map['eval_rate'] as double?,
      isPlaceholder: (map['is_placeholder'] as int) == 1,
    );
  }
}
