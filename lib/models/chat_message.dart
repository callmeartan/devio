import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@Freezed(toJson: true, fromJson: true)
class ChatMessage with _$ChatMessage {
  const ChatMessage._();

  @JsonSerializable(explicitToJson: true)
  const factory ChatMessage({
    required String id,
    required String chatId,
    required String senderId,
    required String content,
    @JsonKey(fromJson: ChatMessage._timestampFromJson, toJson: ChatMessage._timestampToJson)
    required DateTime timestamp,
    @Default(false) bool isAI,
    String? senderName,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  factory ChatMessage.create({
    String? chatId,
    required String senderId,
    required String content,
    required bool isAI,
    String? senderName,
  }) {
    final messageId = const Uuid().v4();
    return ChatMessage(
      id: messageId,
      chatId: chatId ?? messageId,
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
      isAI: isAI,
      senderName: senderName,
    );
  }

  // Helper factory constructors for UI
  factory ChatMessage.user({
    String? chatId,
    required String content,
    required String userId,
    String? userName,
  }) => ChatMessage.create(
    chatId: chatId,
    senderId: userId,
    content: content,
    isAI: false,
    senderName: userName,
  );

  factory ChatMessage.ai({
    String? chatId,
    required String content,
    required String userId,
  }) => ChatMessage.create(
    chatId: chatId,
    senderId: userId,
    content: content,
    isAI: true,
    senderName: 'AI Assistant',
  );

  static DateTime _timestampFromJson(dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is DateTime) {
      return json;
    }
    throw FormatException('Invalid timestamp format: $json');
  }

  static Timestamp _timestampToJson(DateTime time) {
    return Timestamp.fromDate(time);
  }
} 