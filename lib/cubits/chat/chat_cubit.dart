import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/chat_message.dart';
import '../../repositories/chat_repository.dart';
import 'chat_state.dart';
import 'package:devio/features/storage/models/storage_mode.dart';
import 'package:devio/features/storage/repositories/local_chat_repository.dart';
import 'package:devio/features/storage/repositories/repository_factory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

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
        try {
          // Check if Firebase Auth user is available
          final firebaseAuth = FirebaseAuth.instance;
          final currentUser = firebaseAuth.currentUser;

          developer
              .log('Current Firebase Auth user: ${currentUser?.uid ?? 'null'}');

          if (currentUser == null) {
            // Try to sign in anonymously if no user is authenticated
            developer.log(
                'No authenticated user found for loading chat histories, attempting anonymous sign-in...');
            try {
              final userCredential = await firebaseAuth.signInAnonymously();
              developer.log(
                  'Anonymous sign-in successful for loading chat histories. User ID: ${userCredential.user?.uid}');
            } catch (authError) {
              developer.log(
                  'Anonymous sign-in failed for loading chat histories: $authError');

              // Show a user-friendly error message
              String errorMessage = 'Unable to authenticate with Firebase.';
              if (authError.toString().contains('network') ||
                  authError.toString().contains('connection')) {
                errorMessage =
                    'Network connection issue. Please check your internet connection.';
              }

              emit(state.copyWith(
                isLoading: false,
                error: errorMessage,
                chatHistories: [], // Ensure we have an empty list rather than null
              ));
              return;
            }
          }

          // Now load chat histories from the cloud repository
          try {
            final cloudRepository = _repository as ChatRepository;
            developer.log('Fetching chat histories from cloud repository...');
            final histories = await cloudRepository.getChatHistories();
            developer
                .log('Loaded ${histories.length} chat histories from cloud');

            // Log the chat histories for debugging
            for (var i = 0; i < histories.length; i++) {
              developer.log(
                  'Chat $i: ID=${histories[i]['id']}, Title=${histories[i]['title']}, isPinned=${histories[i]['isPinned']}');
            }

            // Update pinned chat IDs based on loaded histories
            final pinnedChatIds = histories
                .where((chat) => chat['isPinned'] == true)
                .map((chat) => chat['id'] as String)
                .toList();

            developer.log('Pinned chat IDs: $pinnedChatIds');

            emit(state.copyWith(
              chatHistories: histories,
              pinnedChatIds: pinnedChatIds,
              isLoading: false,
              error: null, // Clear any previous errors
            ));

            developer.log(
                'Chat histories state updated. Total: ${histories.length}');
          } catch (historyError) {
            developer
                .log('Error loading chat histories from cloud: $historyError');

            // Show a user-friendly error message
            String errorMessage = 'Failed to load chat histories from cloud.';
            if (historyError.toString().contains('network') ||
                historyError.toString().contains('connection')) {
              errorMessage =
                  'Network connection issue. Please check your internet connection.';
            } else if (historyError.toString().contains('permission') ||
                historyError.toString().contains('denied')) {
              errorMessage =
                  'Permission denied. You may not have access to these chat histories.';
            }

            emit(state.copyWith(
              isLoading: false,
              error: errorMessage,
              chatHistories: [], // Ensure we have an empty list rather than null
            ));
          }
        } catch (e) {
          developer.log('Error loading chat histories from cloud: $e');

          // Show a user-friendly error message
          String errorMessage = 'Failed to load chat histories.';
          if (e.toString().contains('network') ||
              e.toString().contains('connection')) {
            errorMessage =
                'Network connection issue. Please check your internet connection.';
          }

          emit(state.copyWith(
            isLoading: false,
            error: errorMessage,
            chatHistories: [], // Ensure we have an empty list rather than null
          ));
        }
      } else if (isLocalMode) {
        try {
          final localRepository = _repository as LocalChatRepository;
          developer.log('Fetching chat histories from local repository...');
          final chats = await localRepository.getChats();
          developer
              .log('Loaded ${chats.length} chat histories from local database');

          // Log the chat histories for debugging
          for (var i = 0; i < chats.length; i++) {
            developer.log(
                'Chat $i: ID=${chats[i]['id']}, Title=${chats[i]['title']}, isPinned=${chats[i]['is_pinned']}');
          }

          // Convert to the same format as cloud histories
          final histories = chats.map((chat) {
            return {
              'id': chat['id'],
              'title': chat['title'],
              'createdAt': DateTime.fromMillisecondsSinceEpoch(
                  chat['created_at'] as int),
              'updatedAt': DateTime.fromMillisecondsSinceEpoch(
                  chat['updated_at'] as int),
              'isPinned': chat['is_pinned'] == 1,
            };
          }).toList();

          // Update pinned chat IDs
          final pinnedChatIds = chats
              .where((chat) => chat['is_pinned'] == 1)
              .map((chat) => chat['id'] as String)
              .toList();

          developer.log('Pinned chat IDs: $pinnedChatIds');

          emit(state.copyWith(
            chatHistories: histories,
            pinnedChatIds: pinnedChatIds,
            isLoading: false,
          ));

          developer
              .log('Chat histories state updated. Total: ${histories.length}');
        } catch (e) {
          developer.log('Error loading chat histories from local database: $e');
          emit(state.copyWith(
            isLoading: false,
            error: 'Failed to load chat histories: $e',
            chatHistories: [], // Ensure we have an empty list rather than null
          ));
        }
      }
    } catch (e) {
      developer.log('Error loading chat histories: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load chat histories: $e',
        chatHistories: [], // Ensure we have an empty list rather than null
      ));
    }
  }

  void selectChat(String chatId) {
    developer.log('Selecting chat: $chatId');
    emit(state.copyWith(currentChatId: chatId));
    _initializeChatStream();
  }

  Future<String> startNewChat() async {
    try {
      String chatId;

      // Cancel any existing subscription
      _chatSubscription?.cancel();
      _chatSubscription = null;

      if (_storageMode == StorageMode.cloud) {
        developer.log('Starting new chat in Cloud Mode');

        // Check Firebase status first
        final cloudRepository = _repository as ChatRepository;
        developer.log('Checking Firebase status...');

        try {
          final firebaseStatus = await cloudRepository.checkFirebaseStatus();
          developer.log('Firebase status: $firebaseStatus');

          if (firebaseStatus['status'] == 'ok') {
            // Firebase is available, create a new chat
            developer.log('Firebase is available, creating new chat');
            chatId = await cloudRepository.createNewChat();
            developer.log('Successfully created new chat with ID: $chatId');
          } else {
            // Firebase is not available, show error and create a local chat ID
            final errorMessage = firebaseStatus['error'] ?? 'Unknown error';
            developer.log('Firebase is not available: $errorMessage');

            // Generate a local chat ID
            chatId = const Uuid().v4();
            developer.log('Generated local chat ID: $chatId');

            // Emit error state but continue with local chat ID
            emit(state.copyWith(
              error:
                  'Could not connect to Firebase: $errorMessage. Using local chat ID instead.',
            ));
          }
        } catch (e) {
          // Error checking Firebase status, use local chat ID
          developer.log('Error checking Firebase status: $e');
          chatId = const Uuid().v4();
          developer.log('Generated local chat ID due to error: $chatId');

          // Emit error state but continue with local chat ID
          emit(state.copyWith(
            error:
                'Error connecting to Firebase: $e. Using local chat ID instead.',
          ));
        }
      } else {
        developer.log('Starting new chat in Local Mode');
        chatId = const Uuid().v4();

        // Create the chat in the local database if in Local Mode
        try {
          final localRepository = _repository as LocalChatRepository;
          await localRepository.createChat('New Chat');
          developer.log('Created new chat in local database with ID: $chatId');

          // Refresh chat histories to include the new chat
          await _loadChatHistories();
        } catch (e) {
          developer.log('Error creating chat in local database: $e');
        }
      }

      // Update state with new chat ID
      emit(state.copyWith(
        currentChatId: chatId,
        messages: [],
        isLoading: false,
      ));

      // Initialize stream for the new chat
      _initializeChatStream();

      developer.log('Started new chat with ID: $chatId');
      return chatId;
    } catch (e) {
      developer.log('Error starting new chat: $e');
      emit(state.copyWith(
        error: 'Failed to start new chat: $e',
        isLoading: false,
      ));
      rethrow;
    }
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
        // For cloud mode, check authentication first
        final firebaseAuth = FirebaseAuth.instance;
        final currentUser = firebaseAuth.currentUser;

        if (currentUser == null) {
          // Try to sign in anonymously if no user is authenticated
          developer.log(
              'No authenticated user found for chat stream, attempting anonymous sign-in...');
          firebaseAuth.signInAnonymously().then((_) {
            developer.log('Anonymous sign-in successful for chat stream');
            _initializeCloudChatStream();
          }).catchError((error) {
            developer.log('Anonymous sign-in failed for chat stream: $error');
            emit(state.copyWith(
              error:
                  'Authentication error: $error. Please try again or restart the app.',
            ));
          });
        } else {
          // User is already authenticated, initialize the stream
          _initializeCloudChatStream();
        }
      } else if (isLocalMode) {
        // For local mode, fetch messages directly
        _loadLocalMessages(state.currentChatId!);
      }
    } else {
      developer.log('No current chat ID, clearing messages');
      emit(state.copyWith(messages: []));
    }
  }

  void _initializeCloudChatStream() {
    try {
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
    } catch (e) {
      developer.log('Error initializing cloud chat stream: $e');
      emit(state.copyWith(
        error: 'Failed to initialize chat stream: $e',
      ));
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

        // If we're in Local Mode and creating a new chat, create it in the database
        if (isLocalMode) {
          try {
            final localRepository = _repository as LocalChatRepository;
            // Check if the chat exists
            final chats = await localRepository.getChats();
            final chatExists = chats.any((chat) => chat['id'] == chatId);

            if (!chatExists) {
              // Create the chat with a default title based on the message content
              final title = content.length > 30
                  ? '${content.substring(0, 27)}...'
                  : content;
              await localRepository.createChat(title);
              developer
                  .log('Created new chat in local database with ID: $chatId');
            }
          } catch (e) {
            developer.log('Error checking/creating chat in local database: $e');
            // Continue anyway to avoid blocking the message
          }
        }
      }

      // Add message to local state immediately
      final currentMessages = _localMessages[chatId] ?? [];
      _localMessages[chatId] = [...currentMessages, message];

      // Update state with new message
      _updateMessagesState(chatId);

      // Send message to repository
      if (isCloudMode) {
        try {
          // Check if Firebase Auth user is available
          final firebaseAuth = FirebaseAuth.instance;
          final currentUser = firebaseAuth.currentUser;

          if (currentUser == null) {
            // Try to sign in anonymously if no user is authenticated
            developer.log(
                'No authenticated user found, attempting anonymous sign-in...');
            try {
              await firebaseAuth.signInAnonymously();
              developer.log('Anonymous sign-in successful');
            } catch (authError) {
              developer.log('Anonymous sign-in failed: $authError');
              emit(state.copyWith(
                error:
                    'Authentication error: $authError. Message saved locally.',
              ));

              // Still keep the message in local state
              developer
                  .log('Message saved locally due to authentication error');
              return;
            }
          }

          // Now send the message to the repository
          try {
            await _repository.sendMessage(message);
            developer.log(
                'Message sent successfully to cloud repository, chatId: $chatId');
          } catch (sendError) {
            developer
                .log('Error sending message to cloud repository: $sendError');

            // Keep the message in local state and show a warning
            emit(state.copyWith(
              error:
                  'Failed to send message to cloud: $sendError. Message saved locally.',
            ));

            developer.log('Message saved locally due to cloud send error');
          }
        } catch (e) {
          developer.log('Error in cloud message handling: $e');
          emit(state.copyWith(
            error: 'Error handling message: $e. Message saved locally.',
          ));

          developer.log('Message saved locally due to general error');
        }
      } else {
        // Local mode - send to local repository
        try {
          await _repository.sendMessage(message);
          developer.log(
              'Message sent successfully to local repository, chatId: $chatId');
        } catch (e) {
          developer.log('Error sending message to local repository: $e');
          emit(state.copyWith(
            error: 'Failed to save message locally: $e',
          ));
        }
      }

      // Initialize stream if needed
      if (_chatSubscription == null) {
        _initializeChatStream();
      }

      // Refresh chat histories after sending a message
      await _loadChatHistories();
    } catch (e) {
      developer.log('Error in sendMessage: $e');
      emit(state.copyWith(
        error: 'Failed to send message: $e',
      ));
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
      emit(state.copyWith(isLoading: true));

      if (isCloudMode) {
        final cloudRepository = _repository as ChatRepository;
        await cloudRepository.clearChat();
        developer.log('Cleared chat in cloud repository');
      } else if (isLocalMode) {
        final localRepository = _repository as LocalChatRepository;
        await localRepository.clearChat();
        developer.log('Cleared chat in local repository');
      }

      // Reload chat histories
      await _loadChatHistories();

      // Start a new chat
      await startNewChat();

      developer.log('Chat clear process completed in cubit');
    } catch (e) {
      developer.log('Error clearing chat: $e');
      emit(state.copyWith(
        error: 'Failed to clear chat: $e',
        isLoading: false,
      ));
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

      // Remove from local messages cache immediately for UI responsiveness
      _localMessages.remove(chatId);

      await _repository.deleteChat(chatId);

      // Remove from pinned chats if it was pinned
      if (state.pinnedChatIds.contains(chatId)) {
        final updatedPinnedChats = List<String>.from(state.pinnedChatIds)
          ..remove(chatId);
        emit(state.copyWith(pinnedChatIds: updatedPinnedChats));
      }

      // If the deleted chat was the current chat, clear it
      if (state.currentChatId == chatId) {
        _chatSubscription?.cancel();
        _chatSubscription = null;
        emit(state.copyWith(currentChatId: null, messages: []));
      }

      // Force refresh chat histories
      await _loadChatHistories();

      // In Local Mode, we need to make sure the chat is removed from the UI
      if (isLocalMode) {
        // Update state to remove the chat from the list
        final updatedHistories =
            state.chatHistories.where((chat) => chat['id'] != chatId).toList();

        emit(state.copyWith(chatHistories: updatedHistories));
        developer.log('Removed chat $chatId from local state');
      }
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

  /// Tests the Firestore connection by trying to access a test document
  Future<Map<String, dynamic>> testFirestoreConnection() async {
    try {
      developer.log('Testing Firestore connection...');

      if (!isCloudMode) {
        return {
          'success': false,
          'error': 'Not in cloud mode. Current mode: $_storageMode',
        };
      }

      // Check if Firebase Auth user is available
      final firebaseAuth = FirebaseAuth.instance;
      final currentUser = firebaseAuth.currentUser;

      developer
          .log('Current Firebase Auth user: ${currentUser?.uid ?? 'null'}');

      if (currentUser == null) {
        // Try to sign in anonymously if no user is authenticated
        developer.log(
            'No authenticated user found, attempting anonymous sign-in...');
        try {
          final userCredential = await firebaseAuth.signInAnonymously();
          developer.log(
              'Anonymous sign-in successful. User ID: ${userCredential.user?.uid}');
        } catch (authError) {
          developer.log('Anonymous sign-in failed: $authError');
          return {
            'success': false,
            'error': 'Authentication failed: $authError',
          };
        }
      }

      // Now test Firestore access
      try {
        final cloudRepository = _repository as ChatRepository;

        // First check security rules
        developer.log('Checking Firestore security rules...');
        final securityRulesResult =
            await cloudRepository.checkFirestoreSecurityRules();

        if (securityRulesResult['success'] != true) {
          developer.log(
              'Firestore security rules check failed: ${securityRulesResult['error']}');
          return securityRulesResult;
        }

        developer.log(
            'Firestore security rules check passed, now trying to get chat histories...');

        // Now try to get chat histories
        final histories = await cloudRepository.getChatHistories();

        developer.log(
            'Successfully retrieved ${histories.length} chat histories from Firestore');

        return {
          'success': true,
          'message': 'Retrieved ${histories.length} chat histories',
          'histories': histories,
          'securityRules': securityRulesResult,
        };
      } catch (firestoreError) {
        developer.log(
            'Error retrieving chat histories from Firestore: $firestoreError');
        return {
          'success': false,
          'error': 'Firestore error: $firestoreError',
        };
      }
    } catch (e) {
      developer.log('Unexpected error testing Firestore connection: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Reloads chat histories from the repository
  Future<void> reloadChatHistories() async {
    developer.log('Manually reloading chat histories...');
    await _loadChatHistories();
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
