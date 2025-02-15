import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String content,
    required DateTime timestamp,
    required bool isUserMessage,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  factory Message.user(String content) => Message(
        id: const Uuid().v4(),
        content: content,
        timestamp: DateTime.now(),
        isUserMessage: true,
      );

  factory Message.ai(String content) => Message(
        id: const Uuid().v4(),
        content: content,
        timestamp: DateTime.now(),
        isUserMessage: false,
      );
} 