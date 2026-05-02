import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';

class ChatRepository {
  static const String _messagesKey = 'devio.local.chat.messages.v1';
  static const String _metadataKey = 'devio.local.chat.metadata.v1';

  final SharedPreferences _prefs;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  ChatRepository({required SharedPreferences prefs}) : _prefs = prefs;

  void dispose() {
    _changes.close();
  }

  Stream<List<ChatMessage>> getChatMessages() async* {
    yield _latestMessages();
    await for (final _ in _changes.stream) {
      yield _latestMessages();
    }
  }

  Stream<List<ChatMessage>> getChatMessagesForId(String chatId) async* {
    yield _messagesForChat(chatId);
    await for (final _ in _changes.stream) {
      yield _messagesForChat(chatId);
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistories() async {
    final messages = _readMessages();
    final metadata = _readMetadata();

    if (messages.isEmpty) {
      if (metadata.isNotEmpty) {
        await _writeMetadata({});
      }
      return [];
    }

    final latestByChat = <String, ChatMessage>{};
    for (final message in messages) {
      final latest = latestByChat[message.chatId];
      if (latest == null || message.timestamp.isAfter(latest.timestamp)) {
        latestByChat[message.chatId] = message;
      }
    }

    final validChatIds = latestByChat.keys.toSet();
    final orphanedMetadata = metadata.keys
        .where((chatId) => !validChatIds.contains(chatId))
        .toList();
    if (orphanedMetadata.isNotEmpty) {
      for (final chatId in orphanedMetadata) {
        metadata.remove(chatId);
      }
      await _writeMetadata(metadata);
    }

    final result = latestByChat.entries.map((entry) {
      final chatId = entry.key;
      final chatMessages = _messagesForChat(chatId, source: messages);
      final chatMetadata = metadata[chatId] ?? {};

      return {
        'id': chatId,
        'title':
            chatMetadata['title'] as String? ?? _titleForChat(chatMessages),
        'timestamp': entry.value.timestamp,
        'isPinned': chatMetadata['isPinned'] == true,
      };
    }).toList();

    result.sort((a, b) {
      if (a['isPinned'] == b['isPinned']) {
        return (b['timestamp'] as DateTime)
            .compareTo(a['timestamp'] as DateTime);
      }
      return (b['isPinned'] as bool) ? 1 : -1;
    });

    return result;
  }

  Future<void> sendMessage(ChatMessage message) async {
    final messages = _readMessages();
    final existingIndex = messages.indexWhere((item) => item.id == message.id);

    if (existingIndex >= 0) {
      messages[existingIndex] = message;
    } else {
      messages.add(message);
    }

    final metadata = _readMetadata();
    final existingMetadata = metadata[message.chatId] ?? {};
    final shouldSetTitle = existingMetadata['title'] == null ||
        (existingMetadata['title'] as String?)?.trim().isEmpty == true ||
        !message.isAI;

    metadata[message.chatId] = {
      ...existingMetadata,
      'lastMessageTime': message.timestamp.toIso8601String(),
      'title': shouldSetTitle
          ? _generateChatTitle(message.content)
          : existingMetadata['title'],
      'isPinned': existingMetadata['isPinned'] == true,
    };

    await _writeMessages(messages);
    await _writeMetadata(metadata);
    _notify();
  }

  Future<void> deleteMessage(String messageId) async {
    final messages = _readMessages();
    final message = messages.cast<ChatMessage?>().firstWhere(
          (item) => item?.id == messageId,
          orElse: () => null,
        );

    if (message == null) {
      return;
    }

    messages.removeWhere((item) => item.id == messageId);
    final metadata = _readMetadata();
    _refreshMetadataForChat(message.chatId, messages, metadata);

    await _writeMessages(messages);
    await _writeMetadata(metadata);
    _notify();
  }

  Future<void> updateMessageContent(String messageId, String newContent) async {
    final messages = _readMessages();
    final messageIndex = messages.indexWhere((item) => item.id == messageId);

    if (messageIndex == -1) {
      developer.log('Message not found for content update: $messageId');
      return;
    }

    messages[messageIndex] = messages[messageIndex].copyWith(
      content: newContent,
    );

    final metadata = _readMetadata();
    _refreshMetadataForChat(
      messages[messageIndex].chatId,
      messages,
      metadata,
      titleOverride:
          messages[messageIndex].isAI ? null : _generateChatTitle(newContent),
    );

    await _writeMessages(messages);
    await _writeMetadata(metadata);
    _notify();
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
    final messages = _readMessages();
    final messageIndex = messages.indexWhere((item) => item.id == messageId);

    if (messageIndex == -1) {
      developer.log('Message not found for metrics update: $messageId');
      return;
    }

    messages[messageIndex] = messages[messageIndex].copyWith(
      totalDuration: totalDuration,
      loadDuration: loadDuration,
      promptEvalCount: promptEvalCount,
      promptEvalDuration: promptEvalDuration,
      promptEvalRate: promptEvalRate,
      evalCount: evalCount,
      evalDuration: evalDuration,
      evalRate: evalRate,
    );

    await _writeMessages(messages);
    _notify();
  }

  Future<void> clearChat() async {
    await _prefs.remove(_messagesKey);
    await _prefs.remove(_metadataKey);
    _notify();
  }

  Future<void> updateChatMetadata(
    String chatId,
    Map<String, dynamic> updates,
  ) async {
    final metadata = _readMetadata();
    metadata[chatId] = {
      ...(metadata[chatId] ?? {}),
      ..._serializeMetadata(updates),
    };

    await _writeMetadata(metadata);
    _notify();
  }

  Future<void> updateChatPin(String chatId, bool isPinned) async {
    await updateChatMetadata(chatId, {'isPinned': isPinned});
  }

  Future<void> updateChatTitle(String chatId, String newTitle) async {
    await updateChatMetadata(chatId, {'title': newTitle});
  }

  Future<void> deleteChat(String chatId) async {
    final messages =
        _readMessages().where((message) => message.chatId != chatId).toList();
    final metadata = _readMetadata()..remove(chatId);

    await _writeMessages(messages);
    await _writeMetadata(metadata);
    _notify();
  }

  Future<Map<String, dynamic>> getChatMetadata(String chatId) async {
    return _readMetadata()[chatId] ?? {};
  }

  Future<void> batchUpdateMetadata(
    Map<String, Map<String, dynamic>> updates,
  ) async {
    final metadata = _readMetadata();

    updates.forEach((chatId, data) {
      metadata[chatId] = {
        ...(metadata[chatId] ?? {}),
        ..._serializeMetadata(data),
      };
    });

    await _writeMetadata(metadata);
    _notify();
  }

  List<ChatMessage> _readMessages() {
    final rawMessages = _prefs.getString(_messagesKey);
    if (rawMessages == null || rawMessages.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawMessages);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => ChatMessage.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to read local chat messages',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<void> _writeMessages(List<ChatMessage> messages) {
    final encoded = jsonEncode(
      messages.map((message) => message.toJson()).toList(),
    );
    return _prefs.setString(_messagesKey, encoded);
  }

  Map<String, Map<String, dynamic>> _readMetadata() {
    final rawMetadata = _prefs.getString(_metadataKey);
    if (rawMetadata == null || rawMetadata.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(rawMetadata);
      if (decoded is! Map) {
        return {};
      }

      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{},
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to read local chat metadata',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  Future<void> _writeMetadata(Map<String, Map<String, dynamic>> metadata) {
    return _prefs.setString(_metadataKey, jsonEncode(metadata));
  }

  List<ChatMessage> _messagesForChat(
    String chatId, {
    List<ChatMessage>? source,
  }) {
    final messages = (source ?? _readMessages())
        .where((message) => message.chatId == chatId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return messages;
  }

  List<ChatMessage> _latestMessages() {
    final messages = _readMessages()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return messages.take(100).toList();
  }

  void _refreshMetadataForChat(
    String chatId,
    List<ChatMessage> messages,
    Map<String, Map<String, dynamic>> metadata, {
    String? titleOverride,
  }) {
    final chatMessages = _messagesForChat(chatId, source: messages);
    if (chatMessages.isEmpty) {
      metadata.remove(chatId);
      return;
    }

    final latestMessage = chatMessages.reduce(
      (latest, message) =>
          message.timestamp.isAfter(latest.timestamp) ? message : latest,
    );
    final existingMetadata = metadata[chatId] ?? {};

    metadata[chatId] = {
      ...existingMetadata,
      'lastMessageTime': latestMessage.timestamp.toIso8601String(),
      'title': titleOverride ??
          (existingMetadata['title'] as String?) ??
          _titleForChat(chatMessages),
      'isPinned': existingMetadata['isPinned'] == true,
    };
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

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
