import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
/// Demo profile model showing per-field hook behavior in the example app.
@PHiveType(2)
abstract class UserProfile with _$UserProfile {
  /// Creates the private base constructor needed for custom getters.
  const UserProfile._();

  const factory UserProfile({
    @PHiveField(0) required String id,
    @PHiveField(1, hooks: [GCMEncrypted()]) required String encryptedToken,
    @PHiveField(2, hooks: [TTL(10)]) required String tempSessionId,
  }) = _UserProfile;

  /// Constant storage key used by the generated example router descriptor.
  @PHivePrimaryKey(boxName: 'user_sessions')
  String get storageKey => 'active_user';
}
