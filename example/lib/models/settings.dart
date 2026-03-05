import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

part 'settings.g.dart';

@PHiveType(1)
class Settings {
  @PHiveField(0)
  final String username;

  @PHiveField(1, hooks: [GCMEncrypted()])
  final String secretKey;

  @PHiveField(2, hooks: [TTL(10)])
  final String cachedToken;

  @PHiveField(3, hooks: [UniversalEncrypted()])
  final Map<String, dynamic> config;

  Settings({
    required this.username,
    required this.secretKey,
    required this.cachedToken,
    required this.config,
  });

  @override
  String toString() {
    return 'Settings(username: $username, secretKey: $secretKey, cachedToken: $cachedToken, config: $config)';
  }
}
