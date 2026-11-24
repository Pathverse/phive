import 'package:phive/phive.dart';

import 'note.dart';

/// Compiled counterparts of the README "Schema Evolution" snippets.
///
/// Kept in the example so `dart analyze` verifies the documented runtime APIs
/// against a real generated adapter.

/// Class hooks a model would declare to opt into the tolerant layout.
const List<PHiveHook> tolerantClassHooks = [TolerantLayout()];

/// Reads a note, treating schema drift as a cache miss.
Future<Note?> readNoteOrNull(PHiveRouter router, String id) async {
  try {
    return await router.get<Note>(id);
  } on PHiveSchemaDriftException catch (drift) {
    // A real application would log this before discarding the entry.
    assert(drift.typeName.isNotEmpty);
    return null;
  }
}

/// Clears stored notes when the stored fingerprint no longer matches.
Future<String> reconcileFingerprint(
  PHiveRouter router,
  String? storedFingerprint,
) async {
  final current = phiveSchemaFingerprint([NoteAdapter()]);
  if (storedFingerprint != current) {
    await router.clearType<Note>();
  }
  return current;
}

/// Router treating drifted notes as cache misses, as in the README
/// "Drift policy" snippet.
/// Registrations without their own policy inherit the router default.
PHiveRouter cacheRouter() =>
    PHiveDynamicRouter(driftPolicy: PHiveDriftPolicy.deleteAndMiss)
      ..register<Note>(primaryKey: (note) => note.id, boxName: 'notes');

/// Per-type override of the router default, as in the README snippet.
PHiveRouter perTypeRouter() => PHiveDynamicRouter()
  ..register<Note>(
    primaryKey: (note) => note.id,
    boxName: 'notes_cache',
    driftPolicy: PHiveDriftPolicy.deleteAndMiss,
  );
