// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatState {
  List<ChatMessage> get messages;
  List<Map<String, dynamic>> get chatHistories;
  List<String> get pinnedChatIds;
  String? get currentChatId;
  bool get isLoading;
  String? get error;
  String get searchQuery;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChatStateCopyWith<ChatState> get copyWith =>
      _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ChatState &&
            const DeepCollectionEquality().equals(other.messages, messages) &&
            const DeepCollectionEquality()
                .equals(other.chatHistories, chatHistories) &&
            const DeepCollectionEquality()
                .equals(other.pinnedChatIds, pinnedChatIds) &&
            (identical(other.currentChatId, currentChatId) ||
                other.currentChatId == currentChatId) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(messages),
      const DeepCollectionEquality().hash(chatHistories),
      const DeepCollectionEquality().hash(pinnedChatIds),
      currentChatId,
      isLoading,
      error,
      searchQuery);

  @override
  String toString() {
    return 'ChatState(messages: $messages, chatHistories: $chatHistories, pinnedChatIds: $pinnedChatIds, currentChatId: $currentChatId, isLoading: $isLoading, error: $error, searchQuery: $searchQuery)';
  }
}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) =
      _$ChatStateCopyWithImpl;
  @useResult
  $Res call(
      {List<ChatMessage> messages,
      List<Map<String, dynamic>> chatHistories,
      List<String> pinnedChatIds,
      String? currentChatId,
      bool isLoading,
      String? error,
      String searchQuery});
}

/// @nodoc
class _$ChatStateCopyWithImpl<$Res> implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._self, this._then);

  final ChatState _self;
  final $Res Function(ChatState) _then;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? chatHistories = null,
    Object? pinnedChatIds = null,
    Object? currentChatId = freezed,
    Object? isLoading = null,
    Object? error = freezed,
    Object? searchQuery = null,
  }) {
    return _then(_self.copyWith(
      messages: null == messages
          ? _self.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      chatHistories: null == chatHistories
          ? _self.chatHistories
          : chatHistories // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      pinnedChatIds: null == pinnedChatIds
          ? _self.pinnedChatIds
          : pinnedChatIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentChatId: freezed == currentChatId
          ? _self.currentChatId
          : currentChatId // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: null == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _ChatState implements ChatState {
  const _ChatState(
      {final List<ChatMessage> messages = const [],
      final List<Map<String, dynamic>> chatHistories = const [],
      final List<String> pinnedChatIds = const [],
      this.currentChatId,
      this.isLoading = false,
      this.error,
      this.searchQuery = ''})
      : _messages = messages,
        _chatHistories = chatHistories,
        _pinnedChatIds = pinnedChatIds;

  final List<ChatMessage> _messages;
  @override
  @JsonKey()
  List<ChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  final List<Map<String, dynamic>> _chatHistories;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get chatHistories {
    if (_chatHistories is EqualUnmodifiableListView) return _chatHistories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chatHistories);
  }

  final List<String> _pinnedChatIds;
  @override
  @JsonKey()
  List<String> get pinnedChatIds {
    if (_pinnedChatIds is EqualUnmodifiableListView) return _pinnedChatIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pinnedChatIds);
  }

  @override
  final String? currentChatId;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;
  @override
  @JsonKey()
  final String searchQuery;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChatStateCopyWith<_ChatState> get copyWith =>
      __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ChatState &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            const DeepCollectionEquality()
                .equals(other._chatHistories, _chatHistories) &&
            const DeepCollectionEquality()
                .equals(other._pinnedChatIds, _pinnedChatIds) &&
            (identical(other.currentChatId, currentChatId) ||
                other.currentChatId == currentChatId) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_messages),
      const DeepCollectionEquality().hash(_chatHistories),
      const DeepCollectionEquality().hash(_pinnedChatIds),
      currentChatId,
      isLoading,
      error,
      searchQuery);

  @override
  String toString() {
    return 'ChatState(messages: $messages, chatHistories: $chatHistories, pinnedChatIds: $pinnedChatIds, currentChatId: $currentChatId, isLoading: $isLoading, error: $error, searchQuery: $searchQuery)';
  }
}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res>
    implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(
          _ChatState value, $Res Function(_ChatState) _then) =
      __$ChatStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<ChatMessage> messages,
      List<Map<String, dynamic>> chatHistories,
      List<String> pinnedChatIds,
      String? currentChatId,
      bool isLoading,
      String? error,
      String searchQuery});
}

/// @nodoc
class __$ChatStateCopyWithImpl<$Res> implements _$ChatStateCopyWith<$Res> {
  __$ChatStateCopyWithImpl(this._self, this._then);

  final _ChatState _self;
  final $Res Function(_ChatState) _then;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? messages = null,
    Object? chatHistories = null,
    Object? pinnedChatIds = null,
    Object? currentChatId = freezed,
    Object? isLoading = null,
    Object? error = freezed,
    Object? searchQuery = null,
  }) {
    return _then(_ChatState(
      messages: null == messages
          ? _self._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      chatHistories: null == chatHistories
          ? _self._chatHistories
          : chatHistories // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      pinnedChatIds: null == pinnedChatIds
          ? _self._pinnedChatIds
          : pinnedChatIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentChatId: freezed == currentChatId
          ? _self.currentChatId
          : currentChatId // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: null == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
