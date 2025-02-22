import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/chat_message.dart';
import '../../repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<List<ChatMessage>>? _chatSubscription;
  final Map<String, List<ChatMessage>> _localMessages = {};

  ChatCubit({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatState()) {
    _loadChatHistories();
  }

  Future<void> _loadChatHistories() async {
    try {
      developer.log('Loading chat histories...');
      emit(state.copyWith(isLoading: true));
      final histories = await _chatRepository.getChatHistories();
      developer.log('Loaded ${histories.length} chat histories');
      emit(state.copyWith(
        chatHistories: histories,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      developer.log('Error loading chat histories: $e');
      emit(state.copyWith(
        error: 'Failed to load chat histories: $e',
        isLoading: false,
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
    emit(state.copyWith(currentChatId: null, messages: []));
    _initializeChatStream();
  }

  void _initializeChatStream() {
    _chatSubscription?.cancel();
    
    if (state.currentChatId != null) {
      developer.log('Initializing chat stream for chat: ${state.currentChatId}');
      _chatSubscription = _chatRepository
          .getChatMessagesForId(state.currentChatId!)
          .listen(
        (messages) {
          developer.log('Received ${messages.length} messages for chat: ${state.currentChatId}');
          _localMessages[state.currentChatId!] = messages;
          _updateMessagesState(state.currentChatId);
        },
        onError: (error) {
          developer.log('Error in chat stream: $error');
          // Don't clear messages on error, keep showing local state
          if (!error.toString().contains('index')) {
            emit(state.copyWith(error: 'Failed to load messages: $error'));
          }
        },
      );
    } else {
      developer.log('Clearing messages for new chat');
      emit(state.copyWith(messages: []));
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String content,
    required bool isAI,
    String? senderName,
  }) async {
    try {
      developer.log('Sending message for chat: ${state.currentChatId}');
      final message = ChatMessage.create(
        chatId: state.currentChatId,
        senderId: senderId,
        content: content,
        isAI: isAI,
        senderName: senderName,
      );
      
      // Add message to local state immediately
      final chatId = message.chatId;
      _localMessages[chatId] = [...(_localMessages[chatId] ?? []), message];
      _updateMessagesState(chatId);
      
      await _chatRepository.sendMessage(message);
      developer.log('Message sent successfully, chatId: ${message.chatId}');
      
      // If this is a new chat, update the chat ID and histories
      if (state.currentChatId == null) {
        developer.log('New chat created with ID: ${message.chatId}');
        emit(state.copyWith(currentChatId: message.chatId));
        _initializeChatStream();
      }
      
      // Always refresh chat histories after sending a message
      await _loadChatHistories();
    } catch (e) {
      developer.log('Error sending message: $e');
      emit(state.copyWith(error: 'Failed to send message: $e'));
    }
  }

  void _updateMessagesState(String? chatId) {
    if (chatId == null) return;
    final messages = _localMessages[chatId] ?? [];
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    emit(state.copyWith(messages: messages));
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      developer.log('Deleting message: $messageId');
      await _chatRepository.deleteMessage(messageId);
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
      await _chatRepository.deleteChat(chatId);
      
      // Clean up local state
      _localMessages.remove(chatId);
      
      // Update state
      if (state.currentChatId == chatId) {
        emit(state.copyWith(currentChatId: null, messages: []));
      }
      
      // Remove from pinned chats if needed
      if (state.pinnedChatIds.contains(chatId)) {
        final updatedPinnedChats = List<String>.from(state.pinnedChatIds)..remove(chatId);
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
      developer.log('Clearing all chats');
      emit(state.copyWith(isLoading: true));
      
      // Cancel existing chat subscription
      _chatSubscription?.cancel();
      
      // Clear chats in repository
      await _chatRepository.clearChat();
      
      // Clear local state
      _localMessages.clear();
      
      // Reset state and reload histories
      emit(const ChatState());
      await _loadChatHistories();
      
      // If any chats remain, try to force delete them
      if (state.chatHistories.isNotEmpty) {
        developer.log('Found remaining chats, attempting force delete');
        for (var chat in state.chatHistories) {
          await forceDeleteChat(chat['id'] as String);
        }
      }
      
      developer.log('Chat history cleared successfully');
    } catch (e) {
      developer.log('Error clearing chat: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to clear chat: $e',
      ));
    }
  }

  Future<void> pinChat(String chatId) async {
    try {
      developer.log('Pinning chat: $chatId');
      if (!state.pinnedChatIds.contains(chatId)) {
        final updatedPinnedChats = List<String>.from(state.pinnedChatIds)..add(chatId);
        emit(state.copyWith(pinnedChatIds: updatedPinnedChats));
        await _chatRepository.updateChatPin(chatId, true);
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
        final updatedPinnedChats = List<String>.from(state.pinnedChatIds)..remove(chatId);
        emit(state.copyWith(pinnedChatIds: updatedPinnedChats));
        await _chatRepository.updateChatPin(chatId, false);
      }
    } catch (e) {
      developer.log('Error unpinning chat: $e');
      emit(state.copyWith(error: 'Failed to unpin chat: $e'));
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      developer.log('Deleting chat: $chatId');
      await _chatRepository.deleteChat(chatId);
      
      // Remove from pinned chats if it was pinned
      if (state.pinnedChatIds.contains(chatId)) {
        final updatedPinnedChats = List<String>.from(state.pinnedChatIds)..remove(chatId);
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
      await _chatRepository.updateChatTitle(chatId, newTitle);
      await _loadChatHistories();
    } catch (e) {
      developer.log('Error renaming chat: $e');
      emit(state.copyWith(error: 'Failed to rename chat: $e'));
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
} 