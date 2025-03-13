import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/chat_message.dart';
import '../../repositories/chat_repository.dart';
import 'chat_state.dart';
import 'package:devio/features/storage/models/storage_mode.dart';
import 'package:devio/features/storage/repositories/local_chat_repository.dart';
import 'package:devio/features/storage/repositories/repository_factory.dart';

class ChatCubit extends Cubit<ChatState> {
  final dynamic _repository;
  final StorageMode _storageMode;
  StreamSubscription<List<ChatMessage>>? _chatSubscription;
  final Map<String, List<ChatMessage>> _localMessages = {};

  ChatCubit({
    required dynamic repository,
    required StorageMode storageMode,
  })  : _repository = repository,
        _storageMode = storageMode,
        super(const ChatState()) {
    _loadChatHistories();
  }

  /// Factory constructor that creates a ChatCubit with the appropriate repository
  /// based on the storage mode
  factory ChatCubit.fromStorageMode(StorageMode storageMode) {
    final repository = RepositoryFactory.getChatRepository(storageMode);
    return ChatCubit(repository: repository, storageMode: storageMode);
  }

  bool get isLocalMode => _storageMode == StorageMode.local;
  bool get isCloudMode => _storageMode == StorageMode.cloud;

  Future<void> _loadChatHistories() async {
    try {
      developer.log('Loading chat histories in ${_storageMode.displayName}...');
      emit(state.copyWith(isLoading: true));

      if (isCloudMode) {
        final cloudRepository = _repository as ChatRepository;
        final histories = await cloudRepository.getChatHistories();
        developer.log('Loaded ${histories.length} chat histories from cloud');

        // Update pinned chat IDs based on loaded histories
        final pinnedChatIds = histories
            .where((chat) => chat['isPinned'] == true)
            .map((chat) => chat['id'] as String)
            .toList();

        emit(state.copyWith(
          chatHistories: histories,
          pinnedChatIds: pinnedChatIds,
          isLoading: false,
        ));
      } else if (isLocalMode) {
        final localRepository = _repository as LocalChatRepository;
        final chats = await localRepository.getChats();
        developer
            .log('Loaded ${chats.length} chat histories from local database');

        // Convert to the same format as cloud histories
        final histories = chats.map((chat) {
          return {
            'id': chat['id'],
            'title': chat['title'],
            'createdAt':
                DateTime.fromMillisecondsSinceEpoch(chat['created_at'] as int),
            'updatedAt':
                DateTime.fromMillisecondsSinceEpoch(chat['updated_at'] as int),
            'isPinned': chat['is_pinned'] == 1,
          };
        }).toList();

        // Update pinned chat IDs
        final pinnedChatIds = chats
            .where((chat) => chat['is_pinned'] == 1)
            .map((chat) => chat['id'] as String)
            .toList();

        emit(state.copyWith(
          chatHistories: histories,
          pinnedChatIds: pinnedChatIds,
          isLoading: false,
        ));
      }
    } catch (e) {
      developer.log('Error loading chat histories: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load chat histories: $e',
      ));
    }
  }

  void selectChat(String chatId) {
    developer.log('Selecting chat: $chatId');
    emit(state.copyWith(currentChatId: chatId));
    _initializeChatStream();
  }

  void startNewChat() {
    developer.log('Starting new chat');

    // Generate a new chat ID
    final newChatId = DateTime.now().millisecondsSinceEpoch.toString();
    developer.log('New chat ID: $newChatId');

    // Cancel any existing subscription
    _chatSubscription?.cancel();
    _chatSubscription = null;

    // Clear local messages for the current chat
    if (state.currentChatId != null) {
      _localMessages.remove(state.currentChatId);
    }

    // Initialize new chat state with the new chat ID
    emit(ChatState(currentChatId: newChatId));

    // Initialize stream for the new chat
    _initializeChatStream();

    developer.log('New chat started with ID: $newChatId');
  }

  void _initializeChatStream() {
    _chatSubscription?.cancel();

    if (state.currentChatId != null) {
      developer
          .log('Initializing chat stream for chat: ${state.currentChatId}');

      // Keep existing messages while waiting for stream
      final existingMessages = _localMessages[state.currentChatId!] ?? [];
      emit(state.copyWith(messages: existingMessages));

      if (isCloudMode) {
        // For cloud mode, use the stream-based approach
        final cloudRepository = _repository as ChatRepository;
        _chatSubscription =
            cloudRepository.getChatMessagesForId(state.currentChatId!).listen(
          (messages) {
            developer.log(
                'Received ${messages.length} messages from Firestore stream');

            // Merge new messages with existing ones
            final chatId = state.currentChatId!;
            final existingMessages = _localMessages[chatId] ?? [];
            final mergedMessages =
                {...existingMessages, ...messages}.toList().cast<ChatMessage>();

            _localMessages[chatId] = mergedMessages;
            _updateMessagesState(chatId);
          },
          onError: (error) {
            developer.log('Error in chat stream: $error');
            // Keep existing messages on error
            final existingMessages = _localMessages[state.currentChatId!] ?? [];
            emit(state.copyWith(
              messages: existingMessages,
              error: 'Failed to load messages: $error',
            ));
          },
        );
      } else if (isLocalMode) {
        // For local mode, fetch messages directly
        _loadLocalMessages(state.currentChatId!);
      }
    } else {
      developer.log('No current chat ID, clearing messages');
      emit(state.copyWith(messages: []));
    }
  }

  Future<void> _loadLocalMessages(String chatId) async {
    try {
      developer.log('Loading local messages for chatId: $chatId');
      emit(state.copyWith(isLoading: true));

      final localRepository = _repository as LocalChatRepository;
      final messages = await localRepository.getMessages(chatId);

      developer.log('Loaded ${messages.length} local messages');

      // Update local messages cache
      _localMessages[chatId] = messages;

      // Update state with messages
      emit(state.copyWith(messages: messages, isLoading: false));
    } catch (e) {
      developer.log('Error loading local messages: $e');
      emit(state.copyWith(
        error: 'Failed to load messages: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String content,
    required bool isAI,
    String? senderName,
    double? totalDuration,
    double? loadDuration,
    int? promptEvalCount,
    double? promptEvalDuration,
    double? promptEvalRate,
    int? evalCount,
    double? evalDuration,
    double? evalRate,
  }) async {
    try {
      developer.log('Sending message for chat: ${state.currentChatId}');

      // Ensure we have a valid chat ID
      final chatId = state.currentChatId ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Create the message
      final message = ChatMessage.create(
        chatId: chatId,
        senderId: senderId,
        content: content,
        isAI: isAI,
        senderName: senderName,
        totalDuration: totalDuration,
        loadDuration: loadDuration,
        promptEvalCount: promptEvalCount,
        promptEvalDuration: promptEvalDuration,
        promptEvalRate: promptEvalRate,
        evalCount: evalCount,
        evalDuration: evalDuration,
        evalRate: evalRate,
      );

      // Update current chat ID if needed
      if (state.currentChatId == null || state.currentChatId != chatId) {
        developer.log('Updating current chat ID to: $chatId');
        emit(state.copyWith(currentChatId: chatId));
      }

      // Add message to local state immediately
      final currentMessages = _localMessages[chatId] ?? [];
      _localMessages[chatId] = [...currentMessages, message];

      // Update state with new message
      _updateMessagesState(chatId);

      // Send message to Firestore
      await _repository.sendMessage(message);
      developer.log('Message sent successfully to Firestore, chatId: $chatId');

      // Initialize stream if needed
      if (_chatSubscription == null) {
        _initializeChatStream();
      }

      // Refresh chat histories after sending a message
      await _loadChatHistories();
    } catch (e) {
      developer.log('Error sending message: $e');
      emit(state.copyWith(error: 'Failed to send message: $e'));
      rethrow;
    }
  }

  void _updateMessagesState(String? chatId) {
    if (chatId == null) return;

    // Get messages for the chat
    final messages = _localMessages[chatId] ?? [];

    // Remove duplicates by message ID
    final uniqueMessages = <String, ChatMessage>{};
    for (var message in messages) {
      uniqueMessages[message.id] = message;
    }

    // Sort messages by timestamp
    final sortedMessages = uniqueMessages.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Update state with sorted unique messages
    emit(state.copyWith(
      messages: sortedMessages,
      currentChatId: chatId,
    ));

    developer.log('Updated messages state - count: ${sortedMessages.length}');
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      developer.log('Deleting message: $messageId');
      await _repository.deleteMessage(messageId);
      await _loadChatHistories(); // Refresh chat histories after deletion
    } catch (e) {
      developer.log('Error deleting message: $e');
      emit(state.copyWith(error: 'Failed to delete message: $e'));
    }
  }

  Future<void> forceDeleteChat(String chatId) async {
    try {
      developer.log('Force deleting chat: $chatId');

      // Cancel subscription if it's the current chat
      if (state.currentChatId == chatId) {
        _chatSubscription?.cancel();
      }

      // Delete from repository
      await _repository.deleteChat(chatId);

      // Clean up local state
      _localMessages.remove(chatId);

      // Update state
      if (state.currentChatId == chatId) {
        emit(state.copyWith(currentChatId: null, messages: []));
      }

      // Remove from pinned chats if needed
      if (state.pinnedChatIds.contains(chatId)) {
        final updatedPinnedChats = List<String>.from(state.pinnedChatIds)
          ..remove(chatId);
        emit(state.copyWith(pinnedChatIds: updatedPinnedChats));
      }

      // Reload histories
      await _loadChatHistories();

      developer.log('Successfully force deleted chat: $chatId');
    } catch (e) {
      developer.log('Error force deleting chat: $e');
      emit(state.copyWith(error: 'Failed to force delete chat: $e'));
    }
  }

  Future<void> clearChat() async {
    try {
      developer.log('Starting chat clear process in cubit');
      emit(state.copyWith(isLoading: true, error: null));

      // Cancel existing chat subscription
      _chatSubscription?.cancel();
      _chatSubscription = null;

      // Clear local state immediately to reflect in UI
      _localMessages.clear();
      emit(const ChatState(isLoading: true));

      // Clear chats in repository
      await _repository.clearChat();
      developer.log('Repository clear operation completed');

      // Reset state completely
      emit(const ChatState());

      // Force a reload of chat histories to verify clearing worked
      await _loadChatHistories();

      // Start a new chat
      startNewChat();

      developer.log('Chat clear process completed in cubit');
    } catch (e) {
      developer.log('Error clearing chat in cubit: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to clear chat: $e',
      ));
      rethrow;
    }
  }

  Future<void> pinChat(String chatId) async {
    try {
      developer.log('Pinning chat: $chatId');
      if (!state.pinnedChatIds.contains(chatId)) {
        final updatedPinnedChats = List<String>.from(state.pinnedChatIds)
          ..add(chatId);
        emit(state.copyWith(pinnedChatIds: updatedPinnedChats));
        await _repository.updateChatPin(chatId, true);
      }
    } catch (e) {
      developer.log('Error pinning chat: $e');
      emit(state.copyWith(error: 'Failed to pin chat: $e'));
    }
  }

  Future<void> unpinChat(String chatId) async {
    try {
      developer.log('Unpinning chat: $chatId');
      if (state.pinnedChatIds.contains(chatId)) {
        final updatedPinnedChats = List<String>.from(state.pinnedChatIds)
          ..remove(chatId);
        emit(state.copyWith(pinnedChatIds: updatedPinnedChats));
        await _repository.updateChatPin(chatId, false);
      }
    } catch (e) {
      developer.log('Error unpinning chat: $e');
      emit(state.copyWith(error: 'Failed to unpin chat: $e'));
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      developer.log('Deleting chat: $chatId');
      await _repository.deleteChat(chatId);

      // Remove from pinned chats if it was pinned
      if (state.pinnedChatIds.contains(chatId)) {
        final updatedPinnedChats = List<String>.from(state.pinnedChatIds)
          ..remove(chatId);
        emit(state.copyWith(pinnedChatIds: updatedPinnedChats));
      }

      // If the deleted chat was the current chat, clear it
      if (state.currentChatId == chatId) {
        emit(state.copyWith(currentChatId: null, messages: []));
      }

      await _loadChatHistories();
    } catch (e) {
      developer.log('Error deleting chat: $e');
      emit(state.copyWith(error: 'Failed to delete chat: $e'));
    }
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    try {
      developer.log('Renaming chat: $chatId to: $newTitle');
      await _repository.updateChatTitle(chatId, newTitle);
      await _loadChatHistories();
    } catch (e) {
      developer.log('Error renaming chat: $e');
      emit(state.copyWith(error: 'Failed to rename chat: $e'));
    }
  }

  // Add a method to add a placeholder message
  void addPlaceholderMessage({
    required String id,
    required String senderId,
    required bool isAI,
    String? senderName,
  }) {
    developer.log('Adding placeholder message with ID: $id');

    // Create a placeholder message
    final message = ChatMessage(
      id: id,
      chatId: state.currentChatId ?? 'new-chat',
      senderId: senderId,
      content: '', // Empty content for placeholder
      isAI: isAI,
      senderName: senderName,
      timestamp: DateTime.now(),
      isPlaceholder: true, // Mark as placeholder
    );

    // Add to local messages
    final chatId = message.chatId;
    _localMessages[chatId] = [...(_localMessages[chatId] ?? []), message];
    _updateMessagesState(chatId);
  }

  // Add a method to remove a placeholder message
  void removePlaceholderMessage(String placeholderId) {
    developer.log('Removing placeholder message with ID: $placeholderId');

    if (state.currentChatId == null) return;

    // Remove the placeholder from local messages
    final chatId = state.currentChatId!;
    final messages = _localMessages[chatId] ?? [];
    _localMessages[chatId] =
        messages.where((m) => m.id != placeholderId).toList();
    _updateMessagesState(chatId);
  }

  // Add a method to search chats
  void searchChats(String query) {
    developer.log('Searching chats with query: $query');
    emit(state.copyWith(searchQuery: query));
  }

  // Get filtered chat histories based on search query
  List<Map<String, dynamic>> getFilteredChatHistories() {
    if (state.searchQuery.isEmpty) {
      return state.chatHistories;
    }

    final query = state.searchQuery.toLowerCase();
    return state.chatHistories.where((chat) {
      final title = (chat['title'] as String).toLowerCase();
      return title.contains(query);
    }).toList();
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
