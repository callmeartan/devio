import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  TextColumn get provider => text().withDefault(const Constant('ollama'))();
  TextColumn get modelName => text().nullable()();
  TextColumn get systemPrompt => text().nullable()();
  TextColumn get settingsJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get senderId => text()();
  TextColumn get senderName => text().nullable()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  BoolColumn get isStreaming => boolean().withDefault(const Constant(false))();
  BoolColumn get isPlaceholder =>
      boolean().withDefault(const Constant(false))();
  TextColumn get metricsJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Conversations, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  Stream<List<Message>> watchMessagesByConversationId(String conversationId) {
    final query = select(messages)
      ..where((message) => message.conversationId.equals(conversationId))
      ..orderBy([(message) => OrderingTerm.asc(message.createdAt)]);
    return query.watch();
  }

  Future<List<Message>> getMessagesByConversationId(String conversationId) {
    final query = select(messages)
      ..where((message) => message.conversationId.equals(conversationId))
      ..orderBy([(message) => OrderingTerm.asc(message.createdAt)]);
    return query.get();
  }

  Future<List<Message>> getLatestMessages({int limit = 100}) {
    final query = select(messages)
      ..orderBy([(message) => OrderingTerm.desc(message.createdAt)])
      ..limit(limit);
    return query.get();
  }

  Stream<List<Message>> watchLatestMessages({int limit = 100}) {
    final query = select(messages)
      ..orderBy([(message) => OrderingTerm.desc(message.createdAt)])
      ..limit(limit);
    return query.watch();
  }

  Future<List<Conversation>> getAllConversationSummaries() {
    final query = select(conversations)
      ..orderBy([
        (conversation) => OrderingTerm.desc(conversation.isPinned),
        (conversation) => OrderingTerm.desc(conversation.updatedAt),
      ]);
    return query.get();
  }

  Future<Conversation?> getConversationById(String conversationId) {
    return (select(conversations)
          ..where((conversation) => conversation.id.equals(conversationId)))
        .getSingleOrNull();
  }

  Future<Message?> getMessageById(String messageId) {
    return (select(messages)..where((message) => message.id.equals(messageId)))
        .getSingleOrNull();
  }

  Future<void> insertOrUpdateConversation(
    ConversationsCompanion conversation,
  ) {
    return into(conversations).insertOnConflictUpdate(conversation);
  }

  Future<void> insertOrUpdateMessage(MessagesCompanion message) {
    return into(messages).insertOnConflictUpdate(message);
  }

  Future<int> updateMessageContent(String messageId, String content) {
    return (update(messages)..where((message) => message.id.equals(messageId)))
        .write(MessagesCompanion(content: Value(content)));
  }

  Future<int> updateMessageMetricsJson(String messageId, String? metricsJson) {
    return (update(messages)..where((message) => message.id.equals(messageId)))
        .write(MessagesCompanion(metricsJson: Value(metricsJson)));
  }

  Future<int> deleteMessageById(String messageId) {
    return (delete(messages)..where((message) => message.id.equals(messageId)))
        .go();
  }

  Future<int> deleteConversationById(String conversationId) {
    return transaction(() async {
      await (delete(messages)
            ..where((message) => message.conversationId.equals(conversationId)))
          .go();
      return (delete(conversations)
            ..where((conversation) => conversation.id.equals(conversationId)))
          .go();
    });
  }

  Future<void> clearAllConversationsAndMessages() {
    return transaction(() async {
      await delete(messages).go();
      await delete(conversations).go();
    });
  }

  Future<int> updateConversationTitle(String conversationId, String title) {
    return (update(conversations)
          ..where((conversation) => conversation.id.equals(conversationId)))
        .write(ConversationsCompanion(
      title: Value(title),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<int> updateConversationPin(String conversationId, bool isPinned) {
    return (update(conversations)
          ..where((conversation) => conversation.id.equals(conversationId)))
        .write(ConversationsCompanion(
      isPinned: Value(isPinned),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<int> updateConversationMetadata(
    String conversationId, {
    String? title,
    String? provider,
    String? modelName,
    String? systemPrompt,
    String? settingsJson,
    DateTime? updatedAt,
  }) {
    return (update(conversations)
          ..where((conversation) => conversation.id.equals(conversationId)))
        .write(ConversationsCompanion(
      title: title == null ? const Value.absent() : Value(title),
      provider: provider == null ? const Value.absent() : Value(provider),
      modelName: modelName == null ? const Value.absent() : Value(modelName),
      systemPrompt:
          systemPrompt == null ? const Value.absent() : Value(systemPrompt),
      settingsJson:
          settingsJson == null ? const Value.absent() : Value(settingsJson),
      updatedAt: Value(updatedAt ?? DateTime.now()),
    ));
  }

  Future<List<Conversation>> searchConversationsByTitle(String queryText) {
    final escaped = queryText.replaceAll('%', r'\%').replaceAll('_', r'\_');
    final query = select(conversations)
      ..where((conversation) => conversation.title.like('%$escaped%'))
      ..orderBy([
        (conversation) => OrderingTerm.desc(conversation.isPinned),
        (conversation) => OrderingTerm.desc(conversation.updatedAt),
      ]);
    return query.get();
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'devio.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
