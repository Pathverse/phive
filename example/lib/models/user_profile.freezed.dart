// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserProfile {

@PHiveField(0) String get id;@PHiveField(1, hooks: [GCMEncrypted()]) String get encryptedToken;@PHiveField(2, hooks: [TTL(10)]) String get tempSessionId;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.encryptedToken, encryptedToken) || other.encryptedToken == encryptedToken)&&(identical(other.tempSessionId, tempSessionId) || other.tempSessionId == tempSessionId));
}


@override
int get hashCode => Object.hash(runtimeType,id,encryptedToken,tempSessionId);

@override
String toString() {
  return 'UserProfile(id: $id, encryptedToken: $encryptedToken, tempSessionId: $tempSessionId)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
@PHiveField(0) String id,@PHiveField(1, hooks: [GCMEncrypted()]) String encryptedToken,@PHiveField(2, hooks: [TTL(10)]) String tempSessionId
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? encryptedToken = null,Object? tempSessionId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,encryptedToken: null == encryptedToken ? _self.encryptedToken : encryptedToken // ignore: cast_nullable_to_non_nullable
as String,tempSessionId: null == tempSessionId ? _self.tempSessionId : tempSessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@PHiveField(0)  String id, @PHiveField(1, hooks: [GCMEncrypted()])  String encryptedToken, @PHiveField(2, hooks: [TTL(10)])  String tempSessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.encryptedToken,_that.tempSessionId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@PHiveField(0)  String id, @PHiveField(1, hooks: [GCMEncrypted()])  String encryptedToken, @PHiveField(2, hooks: [TTL(10)])  String tempSessionId)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.encryptedToken,_that.tempSessionId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@PHiveField(0)  String id, @PHiveField(1, hooks: [GCMEncrypted()])  String encryptedToken, @PHiveField(2, hooks: [TTL(10)])  String tempSessionId)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.encryptedToken,_that.tempSessionId);case _:
  return null;

}
}

}

/// @nodoc


class _UserProfile implements UserProfile {
  const _UserProfile({@PHiveField(0) required this.id, @PHiveField(1, hooks: [GCMEncrypted()]) required this.encryptedToken, @PHiveField(2, hooks: [TTL(10)]) required this.tempSessionId});
  

@override@PHiveField(0) final  String id;
@override@PHiveField(1, hooks: [GCMEncrypted()]) final  String encryptedToken;
@override@PHiveField(2, hooks: [TTL(10)]) final  String tempSessionId;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.encryptedToken, encryptedToken) || other.encryptedToken == encryptedToken)&&(identical(other.tempSessionId, tempSessionId) || other.tempSessionId == tempSessionId));
}


@override
int get hashCode => Object.hash(runtimeType,id,encryptedToken,tempSessionId);

@override
String toString() {
  return 'UserProfile(id: $id, encryptedToken: $encryptedToken, tempSessionId: $tempSessionId)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
@PHiveField(0) String id,@PHiveField(1, hooks: [GCMEncrypted()]) String encryptedToken,@PHiveField(2, hooks: [TTL(10)]) String tempSessionId
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? encryptedToken = null,Object? tempSessionId = null,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,encryptedToken: null == encryptedToken ? _self.encryptedToken : encryptedToken // ignore: cast_nullable_to_non_nullable
as String,tempSessionId: null == tempSessionId ? _self.tempSessionId : tempSessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
