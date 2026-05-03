import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final AppDatabase _database;

  ChatRepository({
    required AppDatabase database,
    SharedPreferences? prefs,
  }) : _database = database;

  void dispose() {}

  Stream<List<ChatMessage>> getChatMessages() {
    return _database.watchLatestMessages().map(
          (rows) => rows.map(_messageFromRow).toList(),
        );
  }

  Stream<List<ChatMessage>> getChatMessagesForId(String chatId) {
    return _database.watchMessagesByConversationId(chatId).map(
          (rows) => rows.map(_messageFromRow).toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getChatHistories() async {
    final conversations = await _database.getAllConversationSummaries();
    return conversations.map(_historyFromConversation).toList();
  }

  Future<void> sendMessage(ChatMessage message) async {
    final existingConversation =
        await _database.getConversationById(message.chatId);
    final messages =
        await _database.getMessagesByConversationId(message.chatId);
    final now = DateTime.now();
    final isFirstMessage = messages.isEmpty;
    final title = existingConversation?.title ??
        _titleForChat([...messages.map(_messageFromRow), message]);

    await _database.transaction(() async {
      await _database.insertOrUpdateConversation(ConversationsCompanion(
        id: Value(message.chatId),
        title: Value(title),
        isPinned: Value(existingConversation?.isPinned ?? false),
        provider: Value(existingConversation?.provider ?? 'ollama'),
        modelName: Value(existingConversation?.modelName),
        systemPrompt: Value(existingConversation?.systemPrompt),
        settingsJson: Value(existingConversation?.settingsJson),
        createdAt: Value(
          existingConversation?.createdAt ??
              (isFirstMessage ? message.timestamp : now),
        ),
        updatedAt: Value(message.timestamp),
      ));
      await _database.insertOrUpdateMessage(_messageToCompanion(message));
    });
  }

  Future<void> deleteMessage(String messageId) async {
    final message = await _database.getMessageById(messageId);
    if (message == null) {
      _debugLog('Message not found for delete: $messageId');
      return;
    }

    await _database.deleteMessageById(messageId);
    await _refreshConversationAfterMessageChange(message.conversationId);
  }

  Future<void> updateMessageContent(String messageId, String newContent) async {
    final message = await _database.getMessageById(messageId);
    if (message == null) {
      _debugLog('Message not found for content update: $messageId');
      return;
    }

    await _database.updateMessageContent(messageId, newContent);
    await _refreshConversationAfterMessageChange(message.conversationId);
  }

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
    final metrics = _encodeMetrics({
      'totalDuration': totalDuration,
      'loadDuration': loadDuration,
      'promptEvalCount': promptEvalCount,
      'promptEvalDuration': promptEvalDuration,
      'promptEvalRate': promptEvalRate,
      'evalCount': evalCount,
      'evalDuration': evalDuration,
      'evalRate': evalRate,
    });
    final updated = await _database.updateMessageMetricsJson(
      messageId,
      metrics,
    );
    if (updated == 0) {
      _debugLog('Message not found for metrics update: $messageId');
    }
  }

  Future<void> clearChat() async {
    await _database.clearAllConversationsAndMessages();
  }

  Future<void> updateChatMetadata(
    String chatId,
    Map<String, dynamic> updates,
  ) async {
    final conversation = await _ensureConversation(chatId, updates: updates);
    final serialized = _serializeMetadata(updates);

    await _database.insertOrUpdateConversation(ConversationsCompanion(
      id: Value(chatId),
      title: Value(
        serialized['title'] as String? ?? conversation.title,
      ),
      isPinned: Value(
        serialized['isPinned'] as bool? ?? conversation.isPinned,
      ),
      provider: Value(
        serialized['provider'] as String? ?? conversation.provider,
      ),
      modelName: Value(
        serialized.containsKey('modelName')
            ? serialized['modelName'] as String?
            : conversation.modelName,
      ),
      systemPrompt: Value(
        serialized.containsKey('systemPrompt')
            ? serialized['systemPrompt'] as String?
            : conversation.systemPrompt,
      ),
      settingsJson: Value(
        serialized['settingsJson'] as String? ??
            _mergedSettingsJson(conversation.settingsJson, serialized),
      ),
      createdAt: Value(conversation.createdAt),
      updatedAt: Value(
        _dateTimeFromMetadata(serialized['lastMessageTime']) ?? DateTime.now(),
      ),
    ));
  }

  Future<void> updateChatPin(String chatId, bool isPinned) async {
    await updateChatMetadata(chatId, {'isPinned': isPinned});
  }

  Future<void> updateChatTitle(String chatId, String newTitle) async {
    await updateChatMetadata(chatId, {'title': newTitle});
  }

  Future<void> deleteChat(String chatId) async {
    await _database.deleteConversationById(chatId);
  }

  Future<Map<String, dynamic>> getChatMetadata(String chatId) async {
    final conversation = await _database.getConversationById(chatId);
    if (conversation == null) {
      return {};
    }

    return {
      'title': conversation.title,
      'isPinned': conversation.isPinned,
      'lastMessageTime': conversation.updatedAt.toIso8601String(),
      'provider': conversation.provider,
      if (conversation.modelName != null) 'modelName': conversation.modelName,
      if (conversation.systemPrompt != null)
        'systemPrompt': conversation.systemPrompt,
      if (conversation.settingsJson != null)
        ..._decodeSettingsJson(conversation.settingsJson),
    };
  }

  Future<void> batchUpdateMetadata(
    Map<String, Map<String, dynamic>> updates,
  ) async {
    for (final entry in updates.entries) {
      await updateChatMetadata(entry.key, entry.value);
    }
  }

  Future<Conversation> _ensureConversation(
    String chatId, {
    Map<String, dynamic>? updates,
  }) async {
    final existing = await _database.getConversationById(chatId);
    if (existing != null) {
      return existing;
    }

    final messages = await _database.getMessagesByConversationId(chatId);
    final now = DateTime.now();
    final createdAt = messages.isEmpty ? now : messages.first.createdAt;
    final updatedAt = messages.isEmpty ? now : messages.last.createdAt;
    final title = updates?['title'] as String? ??
        _titleForChat(messages.map(_messageFromRow).toList());
    final conversation = Conversation(
      id: chatId,
      title: title,
      isPinned: updates?['isPinned'] == true,
      provider: updates?['provider'] as String? ?? 'ollama',
      modelName: updates?['modelName'] as String?,
      systemPrompt: updates?['systemPrompt'] as String?,
      settingsJson: updates?['settingsJson'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    await _database.insertOrUpdateConversation(ConversationsCompanion(
      id: Value(conversation.id),
      title: Value(conversation.title),
      isPinned: Value(conversation.isPinned),
      provider: Value(conversation.provider),
      modelName: Value(conversation.modelName),
      systemPrompt: Value(conversation.systemPrompt),
      settingsJson: Value(conversation.settingsJson),
      createdAt: Value(conversation.createdAt),
      updatedAt: Value(conversation.updatedAt),
    ));
    return conversation;
  }

  Future<void> _refreshConversationAfterMessageChange(String chatId) async {
    final conversation = await _database.getConversationById(chatId);
    final messages = await _database.getMessagesByConversationId(chatId);
    if (messages.isEmpty) {
      await _database.deleteConversationById(chatId);
      return;
    }

    final chatMessages = messages.map(_messageFromRow).toList();
    await _database.insertOrUpdateConversation(ConversationsCompanion(
      id: Value(chatId),
      title: Value(conversation?.title ?? _titleForChat(chatMessages)),
      isPinned: Value(conversation?.isPinned ?? false),
      provider: Value(conversation?.provider ?? 'ollama'),
      modelName: Value(conversation?.modelName),
      systemPrompt: Value(conversation?.systemPrompt),
      settingsJson: Value(conversation?.settingsJson),
      createdAt: Value(conversation?.createdAt ?? messages.first.createdAt),
      updatedAt: Value(messages.last.createdAt),
    ));
  }

  MessagesCompanion _messageToCompanion(ChatMessage message) {
    return MessagesCompanion(
      id: Value(message.id),
      conversationId: Value(message.chatId),
      senderId: Value(message.senderId),
      senderName: Value(message.senderName),
      role: Value(message.isAI ? 'assistant' : 'user'),
      content: Value(message.content),
      isStreaming: const Value(false),
      isPlaceholder: Value(message.isPlaceholder),
      metricsJson: Value(_metricsJsonFromMessage(message)),
      createdAt: Value(message.timestamp),
    );
  }

  ChatMessage _messageFromRow(Message row) {
    final metrics = _decodeMetrics(row.metricsJson);
    return ChatMessage(
      id: row.id,
      chatId: row.conversationId,
      senderId: row.senderId,
      senderName: row.senderName,
      content: row.content,
      timestamp: row.createdAt,
      isAI: row.role == 'assistant',
      isPlaceholder: row.isPlaceholder,
      totalDuration: metrics['totalDuration'] as double?,
      loadDuration: metrics['loadDuration'] as double?,
      promptEvalCount: metrics['promptEvalCount'] as int?,
      promptEvalDuration: metrics['promptEvalDuration'] as double?,
      promptEvalRate: metrics['promptEvalRate'] as double?,
      evalCount: metrics['evalCount'] as int?,
      evalDuration: metrics['evalDuration'] as double?,
      evalRate: metrics['evalRate'] as double?,
    );
  }

  Map<String, dynamic> _historyFromConversation(Conversation conversation) {
    return {
      'id': conversation.id,
      'title': conversation.title,
      'timestamp': conversation.updatedAt,
      'isPinned': conversation.isPinned,
    };
  }

  String? _metricsJsonFromMessage(ChatMessage message) {
    return _encodeMetrics({
      'totalDuration': message.totalDuration,
      'loadDuration': message.loadDuration,
      'promptEvalCount': message.promptEvalCount,
      'promptEvalDuration': message.promptEvalDuration,
      'promptEvalRate': message.promptEvalRate,
      'evalCount': message.evalCount,
      'evalDuration': message.evalDuration,
      'evalRate': message.evalRate,
    });
  }

  String? _encodeMetrics(Map<String, dynamic> metrics) {
    final filtered = Map<String, dynamic>.from(metrics)
      ..removeWhere((_, value) => value == null);
    if (filtered.isEmpty) {
      return null;
    }
    return jsonEncode(filtered);
  }

  Map<String, dynamic> _decodeMetrics(String? metricsJson) {
    if (metricsJson == null || metricsJson.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(metricsJson);
      if (decoded is! Map) {
        return {};
      }
      return decoded.map((key, value) {
        if (value is int && key.toString().endsWith('Duration')) {
          return MapEntry(key.toString(), value.toDouble());
        }
        if (value is int && key.toString().endsWith('Rate')) {
          return MapEntry(key.toString(), value.toDouble());
        }
        return MapEntry(key.toString(), value);
      });
    } catch (e) {
      _debugLog('Failed to decode message metrics: $e');
      return {};
    }
  }

  Map<String, dynamic> _decodeSettingsJson(String? settingsJson) {
    if (settingsJson == null || settingsJson.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(settingsJson);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (e) {
      _debugLog('Failed to decode chat settings: $e');
      return {};
    }
  }

  String? _mergedSettingsJson(
    String? currentSettingsJson,
    Map<String, dynamic> updates,
  ) {
    final settings = _decodeSettingsJson(currentSettingsJson);
    const nonSettingsKeys = {
      'title',
      'isPinned',
      'lastMessageTime',
      'provider',
      'modelName',
      'systemPrompt',
      'settingsJson',
    };
    for (final entry in updates.entries) {
      if (!nonSettingsKeys.contains(entry.key)) {
        settings[entry.key] = entry.value;
      }
    }
    if (settings.isEmpty) {
      return currentSettingsJson;
    }
    return jsonEncode(settings);
  }

  String _titleForChat(List<ChatMessage> messages) {
    final firstUserMessage = messages.cast<ChatMessage?>().firstWhere(
          (message) => message?.isAI == false && message?.content.trim() != '',
          orElse: () => null,
        );

    return _generateChatTitle(
      firstUserMessage?.content ??
          (messages.isNotEmpty ? messages.first.content : 'New chat'),
    );
  }

  String _generateChatTitle(String content) {
    final normalized = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return 'New chat';
    }

    final words = normalized.split(' ');
    if (words.length <= 3) {
      return normalized;
    }
    return '${words.take(3).join(' ')}...';
  }

  Map<String, dynamic> _serializeMetadata(Map<String, dynamic> metadata) {
    return metadata.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      }
      return MapEntry(key, value);
    });
  }

  DateTime? _dateTimeFromMetadata(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }
}
