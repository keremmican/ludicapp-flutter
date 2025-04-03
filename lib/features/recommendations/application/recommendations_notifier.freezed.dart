// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recommendations_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RecommendationsState {
  List<GameSummary> get games => throw _privateConstructorUsedError;
  int get currentCardIndex => throw _privateConstructorUsedError;
  bool get isLoadingMore =>
      throw _privateConstructorUsedError; // Daha fazla yükleme durumunu özel olarak yönetmek için
  bool get noMoreGamesInitially =>
      throw _privateConstructorUsedError; // Başlangıçta hiç oyun bulunamadığında işaretlemek için
  bool get allGamesLoaded => throw _privateConstructorUsedError;

  /// Create a copy of RecommendationsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecommendationsStateCopyWith<RecommendationsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecommendationsStateCopyWith<$Res> {
  factory $RecommendationsStateCopyWith(RecommendationsState value,
          $Res Function(RecommendationsState) then) =
      _$RecommendationsStateCopyWithImpl<$Res, RecommendationsState>;
  @useResult
  $Res call(
      {List<GameSummary> games,
      int currentCardIndex,
      bool isLoadingMore,
      bool noMoreGamesInitially,
      bool allGamesLoaded});
}

/// @nodoc
class _$RecommendationsStateCopyWithImpl<$Res,
        $Val extends RecommendationsState>
    implements $RecommendationsStateCopyWith<$Res> {
  _$RecommendationsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecommendationsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? games = null,
    Object? currentCardIndex = null,
    Object? isLoadingMore = null,
    Object? noMoreGamesInitially = null,
    Object? allGamesLoaded = null,
  }) {
    return _then(_value.copyWith(
      games: null == games
          ? _value.games
          : games // ignore: cast_nullable_to_non_nullable
              as List<GameSummary>,
      currentCardIndex: null == currentCardIndex
          ? _value.currentCardIndex
          : currentCardIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      noMoreGamesInitially: null == noMoreGamesInitially
          ? _value.noMoreGamesInitially
          : noMoreGamesInitially // ignore: cast_nullable_to_non_nullable
              as bool,
      allGamesLoaded: null == allGamesLoaded
          ? _value.allGamesLoaded
          : allGamesLoaded // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecommendationsStateImplCopyWith<$Res>
    implements $RecommendationsStateCopyWith<$Res> {
  factory _$$RecommendationsStateImplCopyWith(_$RecommendationsStateImpl value,
          $Res Function(_$RecommendationsStateImpl) then) =
      __$$RecommendationsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<GameSummary> games,
      int currentCardIndex,
      bool isLoadingMore,
      bool noMoreGamesInitially,
      bool allGamesLoaded});
}

/// @nodoc
class __$$RecommendationsStateImplCopyWithImpl<$Res>
    extends _$RecommendationsStateCopyWithImpl<$Res, _$RecommendationsStateImpl>
    implements _$$RecommendationsStateImplCopyWith<$Res> {
  __$$RecommendationsStateImplCopyWithImpl(_$RecommendationsStateImpl _value,
      $Res Function(_$RecommendationsStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecommendationsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? games = null,
    Object? currentCardIndex = null,
    Object? isLoadingMore = null,
    Object? noMoreGamesInitially = null,
    Object? allGamesLoaded = null,
  }) {
    return _then(_$RecommendationsStateImpl(
      games: null == games
          ? _value._games
          : games // ignore: cast_nullable_to_non_nullable
              as List<GameSummary>,
      currentCardIndex: null == currentCardIndex
          ? _value.currentCardIndex
          : currentCardIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      noMoreGamesInitially: null == noMoreGamesInitially
          ? _value.noMoreGamesInitially
          : noMoreGamesInitially // ignore: cast_nullable_to_non_nullable
              as bool,
      allGamesLoaded: null == allGamesLoaded
          ? _value.allGamesLoaded
          : allGamesLoaded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$RecommendationsStateImpl implements _RecommendationsState {
  const _$RecommendationsStateImpl(
      {final List<GameSummary> games = const [],
      this.currentCardIndex = 0,
      this.isLoadingMore = false,
      this.noMoreGamesInitially = false,
      this.allGamesLoaded = false})
      : _games = games;

  final List<GameSummary> _games;
  @override
  @JsonKey()
  List<GameSummary> get games {
    if (_games is EqualUnmodifiableListView) return _games;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_games);
  }

  @override
  @JsonKey()
  final int currentCardIndex;
  @override
  @JsonKey()
  final bool isLoadingMore;
// Daha fazla yükleme durumunu özel olarak yönetmek için
  @override
  @JsonKey()
  final bool noMoreGamesInitially;
// Başlangıçta hiç oyun bulunamadığında işaretlemek için
  @override
  @JsonKey()
  final bool allGamesLoaded;

  @override
  String toString() {
    return 'RecommendationsState(games: $games, currentCardIndex: $currentCardIndex, isLoadingMore: $isLoadingMore, noMoreGamesInitially: $noMoreGamesInitially, allGamesLoaded: $allGamesLoaded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecommendationsStateImpl &&
            const DeepCollectionEquality().equals(other._games, _games) &&
            (identical(other.currentCardIndex, currentCardIndex) ||
                other.currentCardIndex == currentCardIndex) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.noMoreGamesInitially, noMoreGamesInitially) ||
                other.noMoreGamesInitially == noMoreGamesInitially) &&
            (identical(other.allGamesLoaded, allGamesLoaded) ||
                other.allGamesLoaded == allGamesLoaded));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_games),
      currentCardIndex,
      isLoadingMore,
      noMoreGamesInitially,
      allGamesLoaded);

  /// Create a copy of RecommendationsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecommendationsStateImplCopyWith<_$RecommendationsStateImpl>
      get copyWith =>
          __$$RecommendationsStateImplCopyWithImpl<_$RecommendationsStateImpl>(
              this, _$identity);
}

abstract class _RecommendationsState implements RecommendationsState {
  const factory _RecommendationsState(
      {final List<GameSummary> games,
      final int currentCardIndex,
      final bool isLoadingMore,
      final bool noMoreGamesInitially,
      final bool allGamesLoaded}) = _$RecommendationsStateImpl;

  @override
  List<GameSummary> get games;
  @override
  int get currentCardIndex;
  @override
  bool
      get isLoadingMore; // Daha fazla yükleme durumunu özel olarak yönetmek için
  @override
  bool
      get noMoreGamesInitially; // Başlangıçta hiç oyun bulunamadığında işaretlemek için
  @override
  bool get allGamesLoaded;

  /// Create a copy of RecommendationsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecommendationsStateImplCopyWith<_$RecommendationsStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
