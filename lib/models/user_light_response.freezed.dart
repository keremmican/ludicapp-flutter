// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_light_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserLightResponse _$UserLightResponseFromJson(Map<String, dynamic> json) {
  return _UserLightResponse.fromJson(json);
}

/// @nodoc
mixin _$UserLightResponse {
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;

  /// Serializes this UserLightResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserLightResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserLightResponseCopyWith<UserLightResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserLightResponseCopyWith<$Res> {
  factory $UserLightResponseCopyWith(
          UserLightResponse value, $Res Function(UserLightResponse) then) =
      _$UserLightResponseCopyWithImpl<$Res, UserLightResponse>;
  @useResult
  $Res call({int id, String username});
}

/// @nodoc
class _$UserLightResponseCopyWithImpl<$Res, $Val extends UserLightResponse>
    implements $UserLightResponseCopyWith<$Res> {
  _$UserLightResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserLightResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserLightResponseImplCopyWith<$Res>
    implements $UserLightResponseCopyWith<$Res> {
  factory _$$UserLightResponseImplCopyWith(_$UserLightResponseImpl value,
          $Res Function(_$UserLightResponseImpl) then) =
      __$$UserLightResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String username});
}

/// @nodoc
class __$$UserLightResponseImplCopyWithImpl<$Res>
    extends _$UserLightResponseCopyWithImpl<$Res, _$UserLightResponseImpl>
    implements _$$UserLightResponseImplCopyWith<$Res> {
  __$$UserLightResponseImplCopyWithImpl(_$UserLightResponseImpl _value,
      $Res Function(_$UserLightResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserLightResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
  }) {
    return _then(_$UserLightResponseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserLightResponseImpl implements _UserLightResponse {
  const _$UserLightResponseImpl({required this.id, required this.username});

  factory _$UserLightResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserLightResponseImplFromJson(json);

  @override
  final int id;
  @override
  final String username;

  @override
  String toString() {
    return 'UserLightResponse(id: $id, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserLightResponseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, username);

  /// Create a copy of UserLightResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserLightResponseImplCopyWith<_$UserLightResponseImpl> get copyWith =>
      __$$UserLightResponseImplCopyWithImpl<_$UserLightResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserLightResponseImplToJson(
      this,
    );
  }
}

abstract class _UserLightResponse implements UserLightResponse {
  const factory _UserLightResponse(
      {required final int id,
      required final String username}) = _$UserLightResponseImpl;

  factory _UserLightResponse.fromJson(Map<String, dynamic> json) =
      _$UserLightResponseImpl.fromJson;

  @override
  int get id;
  @override
  String get username;

  /// Create a copy of UserLightResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserLightResponseImplCopyWith<_$UserLightResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
