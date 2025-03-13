import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:devio/features/storage/repositories/local_chat_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Service for exporting local data to files
class DataExportService {
  final LocalChatRepository _localChatRepository;

  DataExportService({LocalChatRepository? localChatRepository})
      : _localChatRepository = localChatRepository ?? LocalChatRepository();

  /// Exports a chat to a JSON file and returns the file path
  Future<String> exportChatToFile(String chatId,
      {String? customFileName}) async {
    try {
      developer.log('Exporting chat with ID: $chatId');

      // Get chat data
      final chatData = await _localChatRepository.exportChatData(chatId);

      // Convert to JSON
      final jsonData = jsonEncode(chatData);

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create export directory if it doesn't exist
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Generate file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 'chat_export_$timestamp.json';
      final filePath = '${exportDir.path}/$fileName';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonData);

      developer.log('Chat exported successfully to: $filePath');
      return filePath;
    } catch (e) {
      developer.log('Error exporting chat: $e');
      rethrow;
    }
  }

  /// Exports all chats to a JSON file and returns the file path
  Future<String> exportAllChatsToFile() async {
    try {
      developer.log('Exporting all chats');

      // Get all chats
      final chats = await _localChatRepository.getChats();

      // Create a list to store all chat data
      final allChatData = [];

      // Export each chat
      for (final chat in chats) {
        final chatId = chat['id'] as String;
        final chatData = await _localChatRepository.exportChatData(chatId);
        allChatData.add(chatData);
      }

      // Convert to JSON
      final jsonData = jsonEncode({
        'chats': allChatData,
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0',
      });

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create export directory if it doesn't exist
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Generate file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'all_chats_export_$timestamp.json';
      final filePath = '${exportDir.path}/$fileName';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonData);

      developer.log('All chats exported successfully to: $filePath');
      return filePath;
    } catch (e) {
      developer.log('Error exporting all chats: $e');
      rethrow;
    }
  }

  /// Shares a chat export file
  Future<void> shareChatExport(String chatId, {String? customFileName}) async {
    try {
      developer.log('Sharing chat export for chat ID: $chatId');

      // Export chat to file
      final filePath =
          await exportChatToFile(chatId, customFileName: customFileName);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'DevIO Chat Export',
        text: 'Here is my exported chat from DevIO',
      );

      developer.log('Chat export shared successfully');
    } catch (e) {
      developer.log('Error sharing chat export: $e');
      rethrow;
    }
  }

  /// Shares all chats export file
  Future<void> shareAllChatsExport() async {
    try {
      developer.log('Sharing all chats export');

      // Export all chats to file
      final filePath = await exportAllChatsToFile();

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'DevIO All Chats Export',
        text: 'Here are all my exported chats from DevIO',
      );

      developer.log('All chats export shared successfully');
    } catch (e) {
      developer.log('Error sharing all chats export: $e');
      rethrow;
    }
  }
}
