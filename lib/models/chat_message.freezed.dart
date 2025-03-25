// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessage {
  String get id;
  String get chatId;
  String get senderId;
  String get content;
  @JsonKey(
      fromJson: ChatMessage._timestampFromJson,
      toJson: ChatMessage._timestampToJson)
  DateTime get timestamp;
  bool get isAI;
  String? get senderName; // Performance metrics
  double? get totalDuration;
  double? get loadDuration;
  int? get promptEvalCount;
  double? get promptEvalDuration;
  double? get promptEvalRate;
  int? get evalCount;
  double? get evalDuration;
  double? get evalRate;
  bool get isPlaceholder;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ChatMessage &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isAI, isAI) || other.isAI == isAI) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration) &&
            (identical(other.loadDuration, loadDuration) ||
                other.loadDuration == loadDuration) &&
            (identical(other.promptEvalCount, promptEvalCount) ||
                other.promptEvalCount == promptEvalCount) &&
            (identical(other.promptEvalDuration, promptEvalDuration) ||
                other.promptEvalDuration == promptEvalDuration) &&
            (identical(other.promptEvalRate, promptEvalRate) ||
                other.promptEvalRate == promptEvalRate) &&
            (identical(other.evalCount, evalCount) ||
                other.evalCount == evalCount) &&
            (identical(other.evalDuration, evalDuration) ||
                other.evalDuration == evalDuration) &&
            (identical(other.evalRate, evalRate) ||
                other.evalRate == evalRate) &&
            (identical(other.isPlaceholder, isPlaceholder) ||
                other.isPlaceholder == isPlaceholder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      chatId,
      senderId,
      content,
      timestamp,
      isAI,
      senderName,
      totalDuration,
      loadDuration,
      promptEvalCount,
      promptEvalDuration,
      promptEvalRate,
      evalCount,
      evalDuration,
      evalRate,
      isPlaceholder);

  @override
  String toString() {
    return 'ChatMessage(id: $id, chatId: $chatId, senderId: $senderId, content: $content, timestamp: $timestamp, isAI: $isAI, senderName: $senderName, totalDuration: $totalDuration, loadDuration: $loadDuration, promptEvalCount: $promptEvalCount, promptEvalDuration: $promptEvalDuration, promptEvalRate: $promptEvalRate, evalCount: $evalCount, evalDuration: $evalDuration, evalRate: $evalRate, isPlaceholder: $isPlaceholder)';
  }
}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) _then) =
      _$ChatMessageCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String chatId,
      String senderId,
      String content,
      @JsonKey(
          fromJson: ChatMessage._timestampFromJson,
          toJson: ChatMessage._timestampToJson)
      DateTime timestamp,
      bool isAI,
      String? senderName,
      double? totalDuration,
      double? loadDuration,
      int? promptEvalCount,
      double? promptEvalDuration,
      double? promptEvalRate,
      int? evalCount,
      double? evalDuration,
      double? evalRate,
      bool isPlaceholder});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res> implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chatId = null,
    Object? senderId = null,
    Object? content = null,
    Object? timestamp = null,
    Object? isAI = null,
    Object? senderName = freezed,
    Object? totalDuration = freezed,
    Object? loadDuration = freezed,
    Object? promptEvalCount = freezed,
    Object? promptEvalDuration = freezed,
    Object? promptEvalRate = freezed,
    Object? evalCount = freezed,
    Object? evalDuration = freezed,
    Object? evalRate = freezed,
    Object? isPlaceholder = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chatId: null == chatId
          ? _self.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _self.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAI: null == isAI
          ? _self.isAI
          : isAI // ignore: cast_nullable_to_non_nullable
              as bool,
      senderName: freezed == senderName
          ? _self.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDuration: freezed == totalDuration
          ? _self.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      loadDuration: freezed == loadDuration
          ? _self.loadDuration
          : loadDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalCount: freezed == promptEvalCount
          ? _self.promptEvalCount
          : promptEvalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      promptEvalDuration: freezed == promptEvalDuration
          ? _self.promptEvalDuration
          : promptEvalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalRate: freezed == promptEvalRate
          ? _self.promptEvalRate
          : promptEvalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      evalCount: freezed == evalCount
          ? _self.evalCount
          : evalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      evalDuration: freezed == evalDuration
          ? _self.evalDuration
          : evalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      evalRate: freezed == evalRate
          ? _self.evalRate
          : evalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      isPlaceholder: null == isPlaceholder
          ? _self.isPlaceholder
          : isPlaceholder // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ChatMessage extends ChatMessage {
  const _ChatMessage(
      {required this.id,
      required this.chatId,
      required this.senderId,
      required this.content,
      @JsonKey(
          fromJson: ChatMessage._timestampFromJson,
          toJson: ChatMessage._timestampToJson)
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
      this.isPlaceholder = false})
      : super._();
  factory _ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  @override
  final String id;
  @override
  final String chatId;
  @override
  final String senderId;
  @override
  final String content;
  @override
  @JsonKey(
      fromJson: ChatMessage._timestampFromJson,
      toJson: ChatMessage._timestampToJson)
  final DateTime timestamp;
  @override
  @JsonKey()
  final bool isAI;
  @override
  final String? senderName;
// Performance metrics
  @override
  final double? totalDuration;
  @override
  final double? loadDuration;
  @override
  final int? promptEvalCount;
  @override
  final double? promptEvalDuration;
  @override
  final double? promptEvalRate;
  @override
  final int? evalCount;
  @override
  final double? evalDuration;
  @override
  final double? evalRate;
  @override
  @JsonKey()
  final bool isPlaceholder;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChatMessageCopyWith<_ChatMessage> get copyWith =>
      __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ChatMessageToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ChatMessage &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isAI, isAI) || other.isAI == isAI) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration) &&
            (identical(other.loadDuration, loadDuration) ||
                other.loadDuration == loadDuration) &&
            (identical(other.promptEvalCount, promptEvalCount) ||
                other.promptEvalCount == promptEvalCount) &&
            (identical(other.promptEvalDuration, promptEvalDuration) ||
                other.promptEvalDuration == promptEvalDuration) &&
            (identical(other.promptEvalRate, promptEvalRate) ||
                other.promptEvalRate == promptEvalRate) &&
            (identical(other.evalCount, evalCount) ||
                other.evalCount == evalCount) &&
            (identical(other.evalDuration, evalDuration) ||
                other.evalDuration == evalDuration) &&
            (identical(other.evalRate, evalRate) ||
                other.evalRate == evalRate) &&
            (identical(other.isPlaceholder, isPlaceholder) ||
                other.isPlaceholder == isPlaceholder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      chatId,
      senderId,
      content,
      timestamp,
      isAI,
      senderName,
      totalDuration,
      loadDuration,
      promptEvalCount,
      promptEvalDuration,
      promptEvalRate,
      evalCount,
      evalDuration,
      evalRate,
      isPlaceholder);

  @override
  String toString() {
    return 'ChatMessage(id: $id, chatId: $chatId, senderId: $senderId, content: $content, timestamp: $timestamp, isAI: $isAI, senderName: $senderName, totalDuration: $totalDuration, loadDuration: $loadDuration, promptEvalCount: $promptEvalCount, promptEvalDuration: $promptEvalDuration, promptEvalRate: $promptEvalRate, evalCount: $evalCount, evalDuration: $evalDuration, evalRate: $evalRate, isPlaceholder: $isPlaceholder)';
  }
}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(
          _ChatMessage value, $Res Function(_ChatMessage) _then) =
      __$ChatMessageCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String chatId,
      String senderId,
      String content,
      @JsonKey(
          fromJson: ChatMessage._timestampFromJson,
          toJson: ChatMessage._timestampToJson)
      DateTime timestamp,
      bool isAI,
      String? senderName,
      double? totalDuration,
      double? loadDuration,
      int? promptEvalCount,
      double? promptEvalDuration,
      double? promptEvalRate,
      int? evalCount,
      double? evalDuration,
      double? evalRate,
      bool isPlaceholder});
}

/// @nodoc
class __$ChatMessageCopyWithImpl<$Res> implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? chatId = null,
    Object? senderId = null,
    Object? content = null,
    Object? timestamp = null,
    Object? isAI = null,
    Object? senderName = freezed,
    Object? totalDuration = freezed,
    Object? loadDuration = freezed,
    Object? promptEvalCount = freezed,
    Object? promptEvalDuration = freezed,
    Object? promptEvalRate = freezed,
    Object? evalCount = freezed,
    Object? evalDuration = freezed,
    Object? evalRate = freezed,
    Object? isPlaceholder = null,
  }) {
    return _then(_ChatMessage(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chatId: null == chatId
          ? _self.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _self.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAI: null == isAI
          ? _self.isAI
          : isAI // ignore: cast_nullable_to_non_nullable
              as bool,
      senderName: freezed == senderName
          ? _self.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDuration: freezed == totalDuration
          ? _self.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      loadDuration: freezed == loadDuration
          ? _self.loadDuration
          : loadDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalCount: freezed == promptEvalCount
          ? _self.promptEvalCount
          : promptEvalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      promptEvalDuration: freezed == promptEvalDuration
          ? _self.promptEvalDuration
          : promptEvalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalRate: freezed == promptEvalRate
          ? _self.promptEvalRate
          : promptEvalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      evalCount: freezed == evalCount
          ? _self.evalCount
          : evalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      evalDuration: freezed == evalDuration
          ? _self.evalDuration
          : evalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      evalRate: freezed == evalRate
          ? _self.evalRate
          : evalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      isPlaceholder: null == isPlaceholder
          ? _self.isPlaceholder
          : isPlaceholder // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
