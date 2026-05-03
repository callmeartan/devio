import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devio/database/app_database.dart';
import 'package:devio/models/chat_message.dart';
import 'package:devio/repositories/chat_repository.dart';

void main() {
  const legacyMessagesKey = 'devio.local.chat.messages.v1';
  const legacyMetadataKey = 'devio.local.chat.metadata.v1';
  const migrationDoneKey = 'drift_migration_done_v1';

  late AppDatabase database;
  late ChatRepository repository;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ChatRepository(database: database, prefs: prefs);
  });

  tearDown(() async {
    repository.dispose();
    await database.close();
  });

  test('inserts messages and returns chat histories', () async {
    await repository.sendMessage(ChatMessage(
      id: 'message-1',
      chatId: 'chat-1',
      senderId: 'user',
      content: 'Build Flutter app',
      timestamp: DateTime(2026),
    ));

    final histories = await repository.getChatHistories();

    expect(histories, hasLength(1));
    expect(histories.single['id'], 'chat-1');
    expect(histories.single['title'], 'Build Flutter app');
    expect(histories.single['timestamp'], DateTime(2026));
    expect(histories.single['isPinned'], isFalse);
  });

  test('sorts pinned chats before unpinned chats', () async {
    await repository.sendMessage(ChatMessage(
      id: 'message-1',
      chatId: 'old-chat',
      senderId: 'user',
      content: 'Old chat',
      timestamp: DateTime(2026),
    ));
    await repository.sendMessage(ChatMessage(
      id: 'message-2',
      chatId: 'new-chat',
      senderId: 'user',
      content: 'New chat',
      timestamp: DateTime(2026, 1, 2),
    ));
    await repository.updateChatPin('old-chat', true);

    final histories = await repository.getChatHistories();

    expect(histories.map((chat) => chat['id']), ['old-chat', 'new-chat']);
  });

  test('renames chats', () async {
    await repository.sendMessage(ChatMessage(
      id: 'message-1',
      chatId: 'chat-1',
      senderId: 'user',
      content: 'Original title',
      timestamp: DateTime(2026),
    ));

    await repository.updateChatTitle('chat-1', 'Renamed');
    final histories = await repository.getChatHistories();

    expect(histories.single['title'], 'Renamed');
  });

  test('deletes chat and cascades messages', () async {
    await repository.sendMessage(ChatMessage(
      id: 'message-1',
      chatId: 'chat-1',
      senderId: 'user',
      content: 'Delete me',
      timestamp: DateTime(2026),
    ));

    await repository.deleteChat('chat-1');

    expect(await repository.getChatHistories(), isEmpty);
    expect(await database.getMessagesByConversationId('chat-1'), isEmpty);
  });

  test('clearChat removes drift data and legacy chat preferences', () async {
    await prefs.setString(legacyMessagesKey, '[]');
    await prefs.setString(legacyMetadataKey, '{}');
    await prefs.setBool(migrationDoneKey, false);
    await repository.sendMessage(ChatMessage(
      id: 'message-1',
      chatId: 'chat-1',
      senderId: 'user',
      content: 'Delete me',
      timestamp: DateTime(2026),
    ));

    await repository.clearChat();

    expect(await repository.getChatHistories(), isEmpty);
    expect(await database.getMessagesByConversationId('chat-1'), isEmpty);
    expect(prefs.getString(legacyMessagesKey), isNull);
    expect(prefs.getString(legacyMetadataKey), isNull);
    expect(prefs.getBool(migrationDoneKey), isTrue);
  });

  test('updates message content', () async {
    await repository.sendMessage(ChatMessage(
      id: 'message-1',
      chatId: 'chat-1',
      senderId: 'user',
      content: 'Before',
      timestamp: DateTime(2026),
    ));

    await repository.updateMessageContent('message-1', 'After');
    final messages = await repository.getChatMessagesForId('chat-1').first;

    expect(messages.single.content, 'After');
  });

  test('roundtrips message metrics through JSON storage', () async {
    await repository.sendMessage(ChatMessage(
      id: 'message-1',
      chatId: 'chat-1',
      senderId: 'assistant',
      content: 'Measured',
      timestamp: DateTime(2026),
      isAI: true,
    ));

    await repository.updateMessageMetrics(
      'message-1',
      totalDuration: 1.2,
      loadDuration: 0.2,
      promptEvalCount: 4,
      promptEvalDuration: 0.4,
      promptEvalRate: 10,
      evalCount: 8,
      evalDuration: 0.8,
      evalRate: 10,
    );
    final messages = await repository.getChatMessagesForId('chat-1').first;

    expect(messages.single.totalDuration, 1.2);
    expect(messages.single.loadDuration, 0.2);
    expect(messages.single.promptEvalCount, 4);
    expect(messages.single.promptEvalDuration, 0.4);
    expect(messages.single.promptEvalRate, 10);
    expect(messages.single.evalCount, 8);
    expect(messages.single.evalDuration, 0.8);
    expect(messages.single.evalRate, 10);
  });
}
