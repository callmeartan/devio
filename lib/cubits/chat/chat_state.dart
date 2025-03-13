import '../../models/chat_message.dart';

// Simple implementation without Freezed
class ChatState {
  final List<ChatMessage> messages;
  final List<Map<String, dynamic>> chatHistories;
  final List<String> pinnedChatIds;
  final String? currentChatId;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const ChatState({
    this.messages = const [],
    this.chatHistories = const [],
    this.pinnedChatIds = const [],
    this.currentChatId,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  // Copy with method
  ChatState copyWith({
    List<ChatMessage>? messages,
    List<Map<String, dynamic>>? chatHistories,
    List<String>? pinnedChatIds,
    String? currentChatId,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      chatHistories: chatHistories ?? this.chatHistories,
      pinnedChatIds: pinnedChatIds ?? this.pinnedChatIds,
      currentChatId: currentChatId ?? this.currentChatId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
