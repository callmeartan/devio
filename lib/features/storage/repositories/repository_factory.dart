import 'package:devio/features/storage/models/storage_mode.dart';
import 'package:devio/features/storage/repositories/local_chat_repository.dart';
import 'package:devio/repositories/chat_repository.dart';
import 'dart:developer' as developer;

/// Factory class for creating repositories based on the current storage mode
class RepositoryFactory {
  /// Creates a chat repository based on the storage mode
  static dynamic getChatRepository(StorageMode storageMode) {
    developer.log(
        'Creating chat repository for storage mode: ${storageMode.displayName}');

    switch (storageMode) {
      case StorageMode.local:
        return LocalChatRepository();
      case StorageMode.cloud:
        return ChatRepository();
      default:
        developer
            .log('Unknown storage mode: $storageMode, defaulting to cloud');
        return ChatRepository();
    }
  }

  /// Creates other repositories based on storage mode
  /// Add more repository factory methods here as needed
}
