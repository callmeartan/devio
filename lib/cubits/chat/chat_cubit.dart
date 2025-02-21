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
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

  Future<void> clearChat() async {
    try {
      developer.log('Clearing all chats');
      emit(state.copyWith(isLoading: true));
      await _chatRepository.clearChat();
      await _loadChatHistories(); // Refresh chat histories after clearing
      emit(state.copyWith(
        isLoading: false,
        error: null,
        currentChatId: null,
        messages: [],
      ));
    } catch (e) {
      developer.log('Error clearing chat: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to clear chat: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
} 