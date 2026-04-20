import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

part 'test_model.g.dart';

@PHiveType(1)
/// Integration fixture covering mixed field-level hook usage.
class DemoUser {
  @PHiveField(0)
  final String id;

  @PHiveField(1, hooks: [GCMEncrypted()])
  final String secretToken;

  @PHiveField(2, hooks: [TTL(3600)])
  final String cachedData;

  @PHiveField(3, hooks: [AESEncrypted()])
  final String legacyToken;

  @PHiveField(4, hooks: [UniversalEncrypted()])
  final Map<String, dynamic> metadata;

  DemoUser({
    required this.id, 
    required this.secretToken, 
    required this.cachedData,
    required this.legacyToken,
    required this.metadata,
  });
}

