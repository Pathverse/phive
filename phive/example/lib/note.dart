import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'note.g.dart';

/// A small record persisted by the example router.
@PHiveType(1)
class Note {
  /// Creates a note with a stable identifier.
  const Note({required this.id, required this.text});

  /// Storage key for this note.
  @PHiveField(0)
  final String id;

  /// The value recovered from storage.
  @PHiveField(1)
  final String text;
}
