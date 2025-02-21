import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/chat_message.dart';

part 'chat_state.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) List<ChatMessage> messages,
    @Default([]) List<Map<String, dynamic>> chatHistories,
    @Default([]) List<String> pinnedChatIds,
    String? currentChatId,
    @Default(false) bool isLoading,
    String? error,
  }) = _ChatState;
} 