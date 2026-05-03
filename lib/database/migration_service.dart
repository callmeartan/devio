import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import 'app_database.dart';

class MigrationService {
  static const String _messagesKey = 'devio.local.chat.messages.v1';
  static const String _metadataKey = 'devio.local.chat.metadata.v1';
  static const String _migrationDoneKey = 'drift_migration_done_v1';

  static Future<void> runIfNeeded(
    SharedPreferences prefs,
    AppDatabase database,
  ) async {
    if (prefs.getBool(_migrationDoneKey) == true) {
      return;
    }

    try {
      final messages = _readMessages(prefs);
      final metadata = _readMetadata(prefs);
      final chatIds = <String>{
        ...messages.map((message) => message.chatId),
        ...metadata.keys,
      };

      await database.transaction(() async {
        for (final chatId in chatIds) {
          final chatMessages = messages
              .where((message) => message.chatId == chatId)
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          final chatMetadata = metadata[chatId] ?? {};
          final now = DateTime.now();
          final createdAt =
              chatMessages.isEmpty ? now : chatMessages.first.timestamp;
          final latestMessageAt =
              chatMessages.isEmpty ? now : chatMessages.last.timestamp;
          final metadataUpdatedAt =
              _parseDateTime(chatMetadata['lastMessageTime']);
          final updatedAt = metadataUpdatedAt ?? latestMessageAt;
          final title = (chatMetadata['title'] as String?)?.trim();

          await database.insertOrUpdateConversation(ConversationsCompanion(
            id: Value(chatId),
            title: Value(
              title == null || title.isEmpty
                  ? _titleForChat(chatMessages)
                  : title,
            ),
            isPinned: Value(chatMetadata['isPinned'] == true),
            provider: Value(chatMetadata['provider'] as String? ?? 'ollama'),
            modelName: Value(chatMetadata['modelName'] as String?),
            systemPrompt: Value(chatMetadata['systemPrompt'] as String?),
            settingsJson: Value(_settingsJsonFromMetadata(chatMetadata)),
            createdAt: Value(createdAt),
            updatedAt: Value(updatedAt),
          ));

          for (final message in chatMessages) {
            await database.insertOrUpdateMessage(MessagesCompanion(
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
            ));
          }
        }
      });

      await prefs.setBool(_migrationDoneKey, true);
    } catch (e) {
      assert(() {
        debugPrint('Drift chat migration failed: $e');
        return true;
      }());
    }
  }

  static List<ChatMessage> _readMessages(SharedPreferences prefs) {
    final rawMessages = prefs.getString(_messagesKey);
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
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      assert(() {
        debugPrint('Failed to read legacy chat messages: $e');
        return true;
      }());
      return [];
    }
  }

  static Map<String, Map<String, dynamic>> _readMetadata(
    SharedPreferences prefs,
  ) {
    final rawMetadata = prefs.getString(_metadataKey);
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
    } catch (e) {
      assert(() {
        debugPrint('Failed to read legacy chat metadata: $e');
        return true;
      }());
      return {};
    }
  }

  static String? _metricsJsonFromMessage(ChatMessage message) {
    final metrics = {
      'totalDuration': message.totalDuration,
      'loadDuration': message.loadDuration,
      'promptEvalCount': message.promptEvalCount,
      'promptEvalDuration': message.promptEvalDuration,
      'promptEvalRate': message.promptEvalRate,
      'evalCount': message.evalCount,
      'evalDuration': message.evalDuration,
      'evalRate': message.evalRate,
    }..removeWhere((_, value) => value == null);

    return metrics.isEmpty ? null : jsonEncode(metrics);
  }

  static String? _settingsJsonFromMetadata(Map<String, dynamic> metadata) {
    final settings = Map<String, dynamic>.from(metadata)
      ..remove('title')
      ..remove('isPinned')
      ..remove('lastMessageTime')
      ..remove('provider')
      ..remove('modelName')
      ..remove('systemPrompt');
    return settings.isEmpty ? null : jsonEncode(settings);
  }

  static String _titleForChat(List<ChatMessage> messages) {
    final firstUserMessage = messages.cast<ChatMessage?>().firstWhere(
          (message) => message?.isAI == false && message?.content.trim() != '',
          orElse: () => null,
        );

    return _generateChatTitle(
      firstUserMessage?.content ??
          (messages.isNotEmpty ? messages.first.content : 'New chat'),
    );
  }

  static String _generateChatTitle(String content) {
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
