// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get chatId => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(
      fromJson: ChatMessage._timestampFromJson,
      toJson: ChatMessage._timestampToJson)
  DateTime get timestamp => throw _privateConstructorUsedError;
  bool get isAI => throw _privateConstructorUsedError;
  String? get senderName =>
      throw _privateConstructorUsedError; // Performance metrics
  double? get totalDuration => throw _privateConstructorUsedError;
  double? get loadDuration => throw _privateConstructorUsedError;
  int? get promptEvalCount => throw _privateConstructorUsedError;
  double? get promptEvalDuration => throw _privateConstructorUsedError;
  double? get promptEvalRate => throw _privateConstructorUsedError;
  int? get evalCount => throw _privateConstructorUsedError;
  double? get evalDuration => throw _privateConstructorUsedError;
  double? get evalRate => throw _privateConstructorUsedError;
  bool get isPlaceholder => throw _privateConstructorUsedError;

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
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
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAI: null == isAI
          ? _value.isAI
          : isAI // ignore: cast_nullable_to_non_nullable
              as bool,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDuration: freezed == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      loadDuration: freezed == loadDuration
          ? _value.loadDuration
          : loadDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalCount: freezed == promptEvalCount
          ? _value.promptEvalCount
          : promptEvalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      promptEvalDuration: freezed == promptEvalDuration
          ? _value.promptEvalDuration
          : promptEvalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalRate: freezed == promptEvalRate
          ? _value.promptEvalRate
          : promptEvalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      evalCount: freezed == evalCount
          ? _value.evalCount
          : evalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      evalDuration: freezed == evalDuration
          ? _value.evalDuration
          : evalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      evalRate: freezed == evalRate
          ? _value.evalRate
          : evalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      isPlaceholder: null == isPlaceholder
          ? _value.isPlaceholder
          : isPlaceholder // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
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
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

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
    return _then(_$ChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAI: null == isAI
          ? _value.isAI
          : isAI // ignore: cast_nullable_to_non_nullable
              as bool,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDuration: freezed == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      loadDuration: freezed == loadDuration
          ? _value.loadDuration
          : loadDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalCount: freezed == promptEvalCount
          ? _value.promptEvalCount
          : promptEvalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      promptEvalDuration: freezed == promptEvalDuration
          ? _value.promptEvalDuration
          : promptEvalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      promptEvalRate: freezed == promptEvalRate
          ? _value.promptEvalRate
          : promptEvalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      evalCount: freezed == evalCount
          ? _value.evalCount
          : evalCount // ignore: cast_nullable_to_non_nullable
              as int?,
      evalDuration: freezed == evalDuration
          ? _value.evalDuration
          : evalDuration // ignore: cast_nullable_to_non_nullable
              as double?,
      evalRate: freezed == evalRate
          ? _value.evalRate
          : evalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      isPlaceholder: null == isPlaceholder
          ? _value.isPlaceholder
          : isPlaceholder // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ChatMessageImpl extends _ChatMessage {
  const _$ChatMessageImpl(
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

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

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

  @override
  String toString() {
    return 'ChatMessage(id: $id, chatId: $chatId, senderId: $senderId, content: $content, timestamp: $timestamp, isAI: $isAI, senderName: $senderName, totalDuration: $totalDuration, loadDuration: $loadDuration, promptEvalCount: $promptEvalCount, promptEvalDuration: $promptEvalDuration, promptEvalRate: $promptEvalRate, evalCount: $evalCount, evalDuration: $evalDuration, evalRate: $evalRate, isPlaceholder: $isPlaceholder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
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

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage extends ChatMessage {
  const factory _ChatMessage(
      {required final String id,
      required final String chatId,
      required final String senderId,
      required final String content,
      @JsonKey(
          fromJson: ChatMessage._timestampFromJson,
          toJson: ChatMessage._timestampToJson)
      required final DateTime timestamp,
      final bool isAI,
      final String? senderName,
      final double? totalDuration,
      final double? loadDuration,
      final int? promptEvalCount,
      final double? promptEvalDuration,
      final double? promptEvalRate,
      final int? evalCount,
      final double? evalDuration,
      final double? evalRate,
      final bool isPlaceholder}) = _$ChatMessageImpl;
  const _ChatMessage._() : super._();

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get chatId;
  @override
  String get senderId;
  @override
  String get content;
  @override
  @JsonKey(
      fromJson: ChatMessage._timestampFromJson,
      toJson: ChatMessage._timestampToJson)
  DateTime get timestamp;
  @override
  bool get isAI;
  @override
  String? get senderName; // Performance metrics
  @override
  double? get totalDuration;
  @override
  double? get loadDuration;
  @override
  int? get promptEvalCount;
  @override
  double? get promptEvalDuration;
  @override
  double? get promptEvalRate;
  @override
  int? get evalCount;
  @override
  double? get evalDuration;
  @override
  double? get evalRate;
  @override
  bool get isPlaceholder;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
