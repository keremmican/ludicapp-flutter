// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HomeState {
  List<GameSummary> get newReleases => throw _privateConstructorUsedError;
  List<GameSummary> get topRatedGames => throw _privateConstructorUsedError;
  GameSummary? get randomGame => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeStateCopyWith<HomeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeStateCopyWith<$Res> {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) then) =
      _$HomeStateCopyWithImpl<$Res, HomeState>;
  @useResult
  $Res call(
      {List<GameSummary> newReleases,
      List<GameSummary> topRatedGames,
      GameSummary? randomGame,
      bool isLoading,
      String? error});
}

/// @nodoc
class _$HomeStateCopyWithImpl<$Res, $Val extends HomeState>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newReleases = null,
    Object? topRatedGames = null,
    Object? randomGame = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      newReleases: null == newReleases
          ? _value.newReleases
          : newReleases // ignore: cast_nullable_to_non_nullable
              as List<GameSummary>,
      topRatedGames: null == topRatedGames
          ? _value.topRatedGames
          : topRatedGames // ignore: cast_nullable_to_non_nullable
              as List<GameSummary>,
      randomGame: freezed == randomGame
          ? _value.randomGame
          : randomGame // ignore: cast_nullable_to_non_nullable
              as GameSummary?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeStateImplCopyWith<$Res>
    implements $HomeStateCopyWith<$Res> {
  factory _$$HomeStateImplCopyWith(
          _$HomeStateImpl value, $Res Function(_$HomeStateImpl) then) =
      __$$HomeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<GameSummary> newReleases,
      List<GameSummary> topRatedGames,
      GameSummary? randomGame,
      bool isLoading,
      String? error});
}

/// @nodoc
class __$$HomeStateImplCopyWithImpl<$Res>
    extends _$HomeStateCopyWithImpl<$Res, _$HomeStateImpl>
    implements _$$HomeStateImplCopyWith<$Res> {
  __$$HomeStateImplCopyWithImpl(
      _$HomeStateImpl _value, $Res Function(_$HomeStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newReleases = null,
    Object? topRatedGames = null,
    Object? randomGame = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$HomeStateImpl(
      newReleases: null == newReleases
          ? _value._newReleases
          : newReleases // ignore: cast_nullable_to_non_nullable
              as List<GameSummary>,
      topRatedGames: null == topRatedGames
          ? _value._topRatedGames
          : topRatedGames // ignore: cast_nullable_to_non_nullable
              as List<GameSummary>,
      randomGame: freezed == randomGame
          ? _value.randomGame
          : randomGame // ignore: cast_nullable_to_non_nullable
              as GameSummary?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$HomeStateImpl implements _HomeState {
  const _$HomeStateImpl(
      {final List<GameSummary> newReleases = const [],
      final List<GameSummary> topRatedGames = const [],
      this.randomGame,
      this.isLoading = false,
      this.error})
      : _newReleases = newReleases,
        _topRatedGames = topRatedGames;

  final List<GameSummary> _newReleases;
  @override
  @JsonKey()
  List<GameSummary> get newReleases {
    if (_newReleases is EqualUnmodifiableListView) return _newReleases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_newReleases);
  }

  final List<GameSummary> _topRatedGames;
  @override
  @JsonKey()
  List<GameSummary> get topRatedGames {
    if (_topRatedGames is EqualUnmodifiableListView) return _topRatedGames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topRatedGames);
  }

  @override
  final GameSummary? randomGame;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'HomeState(newReleases: $newReleases, topRatedGames: $topRatedGames, randomGame: $randomGame, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeStateImpl &&
            const DeepCollectionEquality()
                .equals(other._newReleases, _newReleases) &&
            const DeepCollectionEquality()
                .equals(other._topRatedGames, _topRatedGames) &&
            (identical(other.randomGame, randomGame) ||
                other.randomGame == randomGame) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_newReleases),
      const DeepCollectionEquality().hash(_topRatedGames),
      randomGame,
      isLoading,
      error);

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeStateImplCopyWith<_$HomeStateImpl> get copyWith =>
      __$$HomeStateImplCopyWithImpl<_$HomeStateImpl>(this, _$identity);
}

abstract class _HomeState implements HomeState {
  const factory _HomeState(
      {final List<GameSummary> newReleases,
      final List<GameSummary> topRatedGames,
      final GameSummary? randomGame,
      final bool isLoading,
      final String? error}) = _$HomeStateImpl;

  @override
  List<GameSummary> get newReleases;
  @override
  List<GameSummary> get topRatedGames;
  @override
  GameSummary? get randomGame;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeStateImplCopyWith<_$HomeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
