// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChatState {
  List<ChatMessage> get messages => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get chatHistories =>
      throw _privateConstructorUsedError;
  List<String> get pinnedChatIds => throw _privateConstructorUsedError;
  String? get currentChatId => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String get searchQuery => throw _privateConstructorUsedError;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatStateCopyWith<ChatState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) then) =
      _$ChatStateCopyWithImpl<$Res, ChatState>;
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
class _$ChatStateCopyWithImpl<$Res, $Val extends ChatState>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      chatHistories: null == chatHistories
          ? _value.chatHistories
          : chatHistories // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      pinnedChatIds: null == pinnedChatIds
          ? _value.pinnedChatIds
          : pinnedChatIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentChatId: freezed == currentChatId
          ? _value.currentChatId
          : currentChatId // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatStateImplCopyWith<$Res>
    implements $ChatStateCopyWith<$Res> {
  factory _$$ChatStateImplCopyWith(
          _$ChatStateImpl value, $Res Function(_$ChatStateImpl) then) =
      __$$ChatStateImplCopyWithImpl<$Res>;
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
class __$$ChatStateImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatStateImpl>
    implements _$$ChatStateImplCopyWith<$Res> {
  __$$ChatStateImplCopyWithImpl(
      _$ChatStateImpl _value, $Res Function(_$ChatStateImpl) _then)
      : super(_value, _then);

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
    return _then(_$ChatStateImpl(
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      chatHistories: null == chatHistories
          ? _value._chatHistories
          : chatHistories // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      pinnedChatIds: null == pinnedChatIds
          ? _value._pinnedChatIds
          : pinnedChatIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentChatId: freezed == currentChatId
          ? _value.currentChatId
          : currentChatId // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatStateImpl implements _ChatState {
  const _$ChatStateImpl(
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

  @override
  String toString() {
    return 'ChatState(messages: $messages, chatHistories: $chatHistories, pinnedChatIds: $pinnedChatIds, currentChatId: $currentChatId, isLoading: $isLoading, error: $error, searchQuery: $searchQuery)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatStateImpl &&
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

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatStateImplCopyWith<_$ChatStateImpl> get copyWith =>
      __$$ChatStateImplCopyWithImpl<_$ChatStateImpl>(this, _$identity);
}

abstract class _ChatState implements ChatState {
  const factory _ChatState(
      {final List<ChatMessage> messages,
      final List<Map<String, dynamic>> chatHistories,
      final List<String> pinnedChatIds,
      final String? currentChatId,
      final bool isLoading,
      final String? error,
      final String searchQuery}) = _$ChatStateImpl;

  @override
  List<ChatMessage> get messages;
  @override
  List<Map<String, dynamic>> get chatHistories;
  @override
  List<String> get pinnedChatIds;
  @override
  String? get currentChatId;
  @override
  bool get isLoading;
  @override
  String? get error;
  @override
  String get searchQuery;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatStateImplCopyWith<_$ChatStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
