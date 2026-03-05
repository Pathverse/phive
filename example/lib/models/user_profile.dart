import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
@PHiveType(2, hooks: [TTL(10)])
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    @PHiveField(0) required String id,
    @PHiveField(1, hooks: [GCMEncrypted()]) required String encryptedToken,
    @PHiveField(2) required String tempSessionId,
  }) = _UserProfile;
}
