import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
@HiveType(typeId: 1)
abstract class UserProfile with _$UserProfile {
  @JsonSerializable(explicitToJson: true)
  const factory UserProfile({
    @HiveField(0) required String id,
    @HiveField(1) required EncryptedVar<String> email,
    @HiveField(2) required EncryptedLocalNonceVar<String> token,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
