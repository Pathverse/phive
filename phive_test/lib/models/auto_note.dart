import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

part 'auto_note.g.dart';

@PHiveAutoType()
/// Integration fixture for [PHiveAutoType]: no explicit typeId at the call site.
///
/// The adapter's `typeId = 10` is injected from `phive_type_registry.json`
/// by [PhiveAutoTypeGenerator] at build time.
///
/// Field layout:
/// - `id`    — index 0, plain
/// - `title` — index 1, plain
/// - `body`  — index 2, GCM-encrypted via [GCMEncrypted]
class AutoNote {
  @PHiveField(0)
  final String id;

  @PHiveField(1)
  final String title;

  @PHiveField(2, hooks: [GCMEncrypted()])
  final String body;

  AutoNote({
    required this.id,
    required this.title,
    required this.body,
  });
}
