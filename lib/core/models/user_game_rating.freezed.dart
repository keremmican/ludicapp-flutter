// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_game_rating.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserGameRating _$UserGameRatingFromJson(Map<String, dynamic> json) {
  return _UserGameRating.fromJson(json);
}

/// @nodoc
mixin _$UserGameRating {
  int get id => throw _privateConstructorUsedError;
  int get userId => throw _privateConstructorUsedError;
  int get gameId => throw _privateConstructorUsedError;
  int get rating => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  DateTime get ratingDate => throw _privateConstructorUsedError;

  /// Serializes this UserGameRating to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserGameRating
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserGameRatingCopyWith<UserGameRating> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserGameRatingCopyWith<$Res> {
  factory $UserGameRatingCopyWith(
          UserGameRating value, $Res Function(UserGameRating) then) =
      _$UserGameRatingCopyWithImpl<$Res, UserGameRating>;
  @useResult
  $Res call(
      {int id,
      int userId,
      int gameId,
      int rating,
      String? comment,
      DateTime ratingDate});
}

/// @nodoc
class _$UserGameRatingCopyWithImpl<$Res, $Val extends UserGameRating>
    implements $UserGameRatingCopyWith<$Res> {
  _$UserGameRatingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserGameRating
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? gameId = null,
    Object? rating = null,
    Object? comment = freezed,
    Object? ratingDate = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as int,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      ratingDate: null == ratingDate
          ? _value.ratingDate
          : ratingDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserGameRatingImplCopyWith<$Res>
    implements $UserGameRatingCopyWith<$Res> {
  factory _$$UserGameRatingImplCopyWith(_$UserGameRatingImpl value,
          $Res Function(_$UserGameRatingImpl) then) =
      __$$UserGameRatingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int userId,
      int gameId,
      int rating,
      String? comment,
      DateTime ratingDate});
}

/// @nodoc
class __$$UserGameRatingImplCopyWithImpl<$Res>
    extends _$UserGameRatingCopyWithImpl<$Res, _$UserGameRatingImpl>
    implements _$$UserGameRatingImplCopyWith<$Res> {
  __$$UserGameRatingImplCopyWithImpl(
      _$UserGameRatingImpl _value, $Res Function(_$UserGameRatingImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserGameRating
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? gameId = null,
    Object? rating = null,
    Object? comment = freezed,
    Object? ratingDate = null,
  }) {
    return _then(_$UserGameRatingImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as int,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      ratingDate: null == ratingDate
          ? _value.ratingDate
          : ratingDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserGameRatingImpl implements _UserGameRating {
  const _$UserGameRatingImpl(
      {required this.id,
      required this.userId,
      required this.gameId,
      required this.rating,
      this.comment,
      required this.ratingDate});

  factory _$UserGameRatingImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserGameRatingImplFromJson(json);

  @override
  final int id;
  @override
  final int userId;
  @override
  final int gameId;
  @override
  final int rating;
  @override
  final String? comment;
  @override
  final DateTime ratingDate;

  @override
  String toString() {
    return 'UserGameRating(id: $id, userId: $userId, gameId: $gameId, rating: $rating, comment: $comment, ratingDate: $ratingDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserGameRatingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.ratingDate, ratingDate) ||
                other.ratingDate == ratingDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, userId, gameId, rating, comment, ratingDate);

  /// Create a copy of UserGameRating
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserGameRatingImplCopyWith<_$UserGameRatingImpl> get copyWith =>
      __$$UserGameRatingImplCopyWithImpl<_$UserGameRatingImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserGameRatingImplToJson(
      this,
    );
  }
}

abstract class _UserGameRating implements UserGameRating {
  const factory _UserGameRating(
      {required final int id,
      required final int userId,
      required final int gameId,
      required final int rating,
      final String? comment,
      required final DateTime ratingDate}) = _$UserGameRatingImpl;

  factory _UserGameRating.fromJson(Map<String, dynamic> json) =
      _$UserGameRatingImpl.fromJson;

  @override
  int get id;
  @override
  int get userId;
  @override
  int get gameId;
  @override
  int get rating;
  @override
  String? get comment;
  @override
  DateTime get ratingDate;

  /// Create a copy of UserGameRating
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserGameRatingImplCopyWith<_$UserGameRatingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
