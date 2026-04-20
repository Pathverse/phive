import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

part 'test_model2.g.dart';

@PHiveType(2, hooks: [AESEncrypted()], autoFields: true)
/// Integration fixture covering model-level AES encryption only.
class DemoTopLevelAesUser {
  final String id;
  final String secret;

  DemoTopLevelAesUser({
    required this.id,
    required this.secret,
  });
}
