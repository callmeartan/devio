import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Simple implementation without Freezed
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isAI;
  final String? senderName;
  // Performance metrics
  final double? totalDuration;
  final double? loadDuration;
  final int? promptEvalCount;
  final double? promptEvalDuration;
  final double? promptEvalRate;
  final int? evalCount;
  final double? evalDuration;
  final double? evalRate;
  final bool isPlaceholder;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isAI = false,
    this.senderName,
    this.totalDuration,
    this.loadDuration,
    this.promptEvalCount,
    this.promptEvalDuration,
    this.promptEvalRate,
    this.evalCount,
    this.evalDuration,
    this.evalRate,
    this.isPlaceholder = false,
  });

  // Copy with method
  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    DateTime? timestamp,
    bool? isAI,
    String? senderName,
    double? totalDuration,
    double? loadDuration,
    int? promptEvalCount,
    double? promptEvalDuration,
    double? promptEvalRate,
    int? evalCount,
    double? evalDuration,
    double? evalRate,
    bool? isPlaceholder,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isAI: isAI ?? this.isAI,
      senderName: senderName ?? this.senderName,
      totalDuration: totalDuration ?? this.totalDuration,
      loadDuration: loadDuration ?? this.loadDuration,
      promptEvalCount: promptEvalCount ?? this.promptEvalCount,
      promptEvalDuration: promptEvalDuration ?? this.promptEvalDuration,
      promptEvalRate: promptEvalRate ?? this.promptEvalRate,
      evalCount: evalCount ?? this.evalCount,
      evalDuration: evalDuration ?? this.evalDuration,
      evalRate: evalRate ?? this.evalRate,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'timestamp': _timestampToJson(timestamp),
      'is_ai': isAI,
      'sender_name': senderName,
      'total_duration': totalDuration,
      'load_duration': loadDuration,
      'prompt_eval_count': promptEvalCount,
      'prompt_eval_duration': promptEvalDuration,
      'prompt_eval_rate': promptEvalRate,
      'eval_count': evalCount,
      'eval_duration': evalDuration,
      'eval_rate': evalRate,
      'is_placeholder': isPlaceholder,
    };
  }

  // Factory method to create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      timestamp: _timestampFromJson(json['timestamp']),
      isAI: json['is_ai'] as bool? ?? false,
      senderName: json['sender_name'] as String?,
      totalDuration: json['total_duration'] as double?,
      loadDuration: json['load_duration'] as double?,
      promptEvalCount: json['prompt_eval_count'] as int?,
      promptEvalDuration: json['prompt_eval_duration'] as double?,
      promptEvalRate: json['prompt_eval_rate'] as double?,
      evalCount: json['eval_count'] as int?,
      evalDuration: json['eval_duration'] as double?,
      evalRate: json['eval_rate'] as double?,
      isPlaceholder: json['is_placeholder'] as bool? ?? false,
    );
  }

  factory ChatMessage.create({
    String? chatId,
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
      totalDuration: totalDuration,
      loadDuration: loadDuration,
      promptEvalCount: promptEvalCount,
      promptEvalDuration: promptEvalDuration,
      promptEvalRate: promptEvalRate,
      evalCount: evalCount,
      evalDuration: evalDuration,
      evalRate: evalRate,
      isPlaceholder: false,
    );
  }

  // Helper factory constructors for UI
  factory ChatMessage.user({
    String? chatId,
    required String content,
    required String userId,
    String? userName,
  }) =>
      ChatMessage.create(
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
    double? totalDuration,
    double? loadDuration,
    int? promptEvalCount,
    double? promptEvalDuration,
    double? promptEvalRate,
    int? evalCount,
    double? evalDuration,
    double? evalRate,
  }) =>
      ChatMessage.create(
        chatId: chatId,
        senderId: userId,
        content: content,
        isAI: true,
        senderName: 'AI Assistant',
        totalDuration: totalDuration,
        loadDuration: loadDuration,
        promptEvalCount: promptEvalCount,
        promptEvalDuration: promptEvalDuration,
        promptEvalRate: promptEvalRate,
        evalCount: evalCount,
        evalDuration: evalDuration,
        evalRate: evalRate,
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
