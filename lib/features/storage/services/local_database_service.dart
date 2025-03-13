import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;
import 'package:devio/models/chat_message.dart';

/// Service for handling local database operations in Local Mode
class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  static Database? _database;

  // Database name and version
  static const String _databaseName = 'devio_local.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableChats = 'chats';
  static const String tableMessages = 'messages';
  static const String tableSettings = 'settings';

  // Factory constructor
  factory LocalDatabaseService() {
    return _instance;
  }

  // Internal constructor
  LocalDatabaseService._internal();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);

      developer.log('Initializing local database at: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      developer.log('Error initializing database: $e');
      rethrow;
    }
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      developer.log('Creating database tables for version $version');

      // Create chats table
      await db.execute('''
        CREATE TABLE $tableChats (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          is_pinned INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // Create messages table
      await db.execute('''
        CREATE TABLE $tableMessages (
          id TEXT PRIMARY KEY,
          chat_id TEXT NOT NULL,
          sender_id TEXT NOT NULL,
          content TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          is_ai INTEGER DEFAULT 0,
          sender_name TEXT,
          total_duration REAL,
          load_duration REAL,
          prompt_eval_count INTEGER,
          prompt_eval_duration REAL,
          prompt_eval_rate REAL,
          eval_count INTEGER,
          eval_duration REAL,
          eval_rate REAL,
          is_placeholder INTEGER DEFAULT 0,
          FOREIGN KEY (chat_id) REFERENCES $tableChats (id) ON DELETE CASCADE
        )
      ''');

      // Create settings table
      await db.execute('''
        CREATE TABLE $tableSettings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      developer.log('Database tables created successfully');
    } catch (e) {
      developer.log('Error creating database tables: $e');
      rethrow;
    }
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      developer
          .log('Upgrading database from version $oldVersion to $newVersion');

      if (oldVersion < 2 && newVersion >= 2) {
        // Add future schema changes here when needed
      }
    } catch (e) {
      developer.log('Error upgrading database: $e');
      rethrow;
    }
  }

  // CHAT OPERATIONS

  /// Creates a new chat
  Future<String> createChat(String title) async {
    try {
      final db = await database;
      final chatId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        tableChats,
        {
          'id': chatId,
          'title': title,
          'created_at': now,
          'updated_at': now,
          'is_pinned': 0,
          'is_deleted': 0,
        },
      );

      developer.log('Created new chat with ID: $chatId');
      return chatId;
    } catch (e) {
      developer.log('Error creating chat: $e');
      rethrow;
    }
  }

  /// Gets all chats
  Future<List<Map<String, dynamic>>> getChats(
      {bool includePinned = true}) async {
    try {
      final db = await database;

      String query = 'SELECT * FROM $tableChats WHERE is_deleted = 0';
      if (!includePinned) {
        query += ' AND is_pinned = 0';
      }
      query += ' ORDER BY updated_at DESC';

      final result = await db.rawQuery(query);
      return result;
    } catch (e) {
      developer.log('Error getting chats: $e');
      rethrow;
    }
  }

  /// Gets pinned chats
  Future<List<Map<String, dynamic>>> getPinnedChats() async {
    try {
      final db = await database;

      final result = await db.query(
        tableChats,
        where: 'is_pinned = 1 AND is_deleted = 0',
        orderBy: 'updated_at DESC',
      );

      return result;
    } catch (e) {
      developer.log('Error getting pinned chats: $e');
      rethrow;
    }
  }

  /// Updates a chat
  Future<void> updateChat(String chatId,
      {String? title, bool? isPinned}) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final Map<String, dynamic> updates = {'updated_at': now};
      if (title != null) updates['title'] = title;
      if (isPinned != null) updates['is_pinned'] = isPinned ? 1 : 0;

      await db.update(
        tableChats,
        updates,
        where: 'id = ?',
        whereArgs: [chatId],
      );

      developer.log('Updated chat with ID: $chatId');
    } catch (e) {
      developer.log('Error updating chat: $e');
      rethrow;
    }
  }

  /// Soft deletes a chat
  Future<void> deleteChat(String chatId) async {
    try {
      final db = await database;

      await db.update(
        tableChats,
        {'is_deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [chatId],
      );

      developer.log('Soft deleted chat with ID: $chatId');
    } catch (e) {
      developer.log('Error deleting chat: $e');
      rethrow;
    }
  }

  /// Permanently deletes a chat and all its messages
  Future<void> permanentlyDeleteChat(String chatId) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        // Delete messages first
        await txn.delete(
          tableMessages,
          where: 'chat_id = ?',
          whereArgs: [chatId],
        );

        // Then delete the chat
        await txn.delete(
          tableChats,
          where: 'id = ?',
          whereArgs: [chatId],
        );
      });

      developer.log(
          'Permanently deleted chat with ID: $chatId and all its messages');
    } catch (e) {
      developer.log('Error permanently deleting chat: $e');
      rethrow;
    }
  }

  // MESSAGE OPERATIONS

  /// Adds a message to a chat
  Future<void> addMessage(ChatMessage message) async {
    try {
      final db = await database;

      // Update the chat's updated_at timestamp
      await db.update(
        tableChats,
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [message.chatId],
      );

      // Insert the message
      await db.insert(
        tableMessages,
        {
          'id': message.id,
          'chat_id': message.chatId,
          'sender_id': message.senderId,
          'content': message.content,
          'timestamp': message.timestamp.millisecondsSinceEpoch,
          'is_ai': message.isAI ? 1 : 0,
          'sender_name': message.senderName,
          'total_duration': message.totalDuration,
          'load_duration': message.loadDuration,
          'prompt_eval_count': message.promptEvalCount,
          'prompt_eval_duration': message.promptEvalDuration,
          'prompt_eval_rate': message.promptEvalRate,
          'eval_count': message.evalCount,
          'eval_duration': message.evalDuration,
          'eval_rate': message.evalRate,
          'is_placeholder': message.isPlaceholder ? 1 : 0,
        },
      );

      developer.log(
          'Added message with ID: ${message.id} to chat: ${message.chatId}');
    } catch (e) {
      developer.log('Error adding message: $e');
      rethrow;
    }
  }

  /// Gets messages for a chat
  Future<List<ChatMessage>> getMessages(String chatId,
      {int limit = 50, int offset = 0}) async {
    try {
      final db = await database;

      final result = await db.query(
        tableMessages,
        where: 'chat_id = ?',
        whereArgs: [chatId],
        orderBy: 'timestamp ASC',
        limit: limit,
        offset: offset,
      );

      return result.map((map) => _mapToMessage(map)).toList();
    } catch (e) {
      developer.log('Error getting messages: $e');
      rethrow;
    }
  }

  /// Updates a message
  Future<void> updateMessage(String messageId, {String? content}) async {
    try {
      final db = await database;

      final Map<String, dynamic> updates = {};
      if (content != null) updates['content'] = content;

      await db.update(
        tableMessages,
        updates,
        where: 'id = ?',
        whereArgs: [messageId],
      );

      developer.log('Updated message with ID: $messageId');
    } catch (e) {
      developer.log('Error updating message: $e');
      rethrow;
    }
  }

  /// Deletes a message
  Future<void> deleteMessage(String messageId) async {
    try {
      final db = await database;

      await db.delete(
        tableMessages,
        where: 'id = ?',
        whereArgs: [messageId],
      );

      developer.log('Deleted message with ID: $messageId');
    } catch (e) {
      developer.log('Error deleting message: $e');
      rethrow;
    }
  }

  // SETTINGS OPERATIONS

  /// Saves a setting
  Future<void> saveSetting(String key, String value) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        tableSettings,
        {
          'key': key,
          'value': value,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      developer.log('Saved setting: $key = $value');
    } catch (e) {
      developer.log('Error saving setting: $e');
      rethrow;
    }
  }

  /// Gets a setting
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;

      final result = await db.query(
        tableSettings,
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
      );

      if (result.isNotEmpty) {
        return result.first['value'] as String?;
      }

      return null;
    } catch (e) {
      developer.log('Error getting setting: $e');
      rethrow;
    }
  }

  /// Deletes a setting
  Future<void> deleteSetting(String key) async {
    try {
      final db = await database;

      await db.delete(
        tableSettings,
        where: 'key = ?',
        whereArgs: [key],
      );

      developer.log('Deleted setting: $key');
    } catch (e) {
      developer.log('Error deleting setting: $e');
      rethrow;
    }
  }

  // HELPER METHODS

  /// Converts a database map to a ChatMessage object
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

  /// Closes the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      developer.log('Database connection closed');
    }
  }
}
