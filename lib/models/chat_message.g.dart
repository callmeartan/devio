// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      timestamp: ChatMessage._timestampFromJson(json['timestamp']),
      isAI: json['isAI'] as bool? ?? false,
      senderName: json['senderName'] as String?,
      totalDuration: (json['totalDuration'] as num?)?.toDouble(),
      loadDuration: (json['loadDuration'] as num?)?.toDouble(),
      promptEvalCount: (json['promptEvalCount'] as num?)?.toInt(),
      promptEvalDuration: (json['promptEvalDuration'] as num?)?.toDouble(),
      promptEvalRate: (json['promptEvalRate'] as num?)?.toDouble(),
      evalCount: (json['evalCount'] as num?)?.toInt(),
      evalDuration: (json['evalDuration'] as num?)?.toDouble(),
      evalRate: (json['evalRate'] as num?)?.toDouble(),
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
    );

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chatId': instance.chatId,
      'senderId': instance.senderId,
      'content': instance.content,
      'timestamp': ChatMessage._timestampToJson(instance.timestamp),
      'isAI': instance.isAI,
      'senderName': instance.senderName,
      'totalDuration': instance.totalDuration,
      'loadDuration': instance.loadDuration,
      'promptEvalCount': instance.promptEvalCount,
      'promptEvalDuration': instance.promptEvalDuration,
      'promptEvalRate': instance.promptEvalRate,
      'evalCount': instance.evalCount,
      'evalDuration': instance.evalDuration,
      'evalRate': instance.evalRate,
      'isPlaceholder': instance.isPlaceholder,
    };
