import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/templates/ttl.dart';

part 'note.g.dart';

/// A small record persisted by the example router.
@PHiveType(1)
class Note {
  /// Creates a note with a stable identifier.
  const Note({required this.id, required this.text});

  /// Storage key for this note.
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'expiring_notes')
  final String id;

  /// A value that expires one second after it is written.
  @PHiveField(1, hooks: [TTL(1)])
  final String text;
}
