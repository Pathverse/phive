import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

import 'note.dart';

/// Writes and reads a record through PHive using disposable native storage.
Future<void> main() async {
  final directory = await Directory.systemTemp.createTemp('phive_example_');
  try {
    Hive.init(directory.path);
    Hive.registerAdapter(NoteAdapter());

    final router = PHiveDynamicRouter()
      ..register<Note>(primaryKey: (note) => note.id, boxName: 'example_notes');
    await router.store(const Note(id: 'note-1', text: 'Hello PHive'));
    final restored = await router.get<Note>('note-1');
    if (restored?.id != 'note-1' || restored?.text != 'Hello PHive') {
      throw StateError('The stored note did not round-trip.');
    }
    stdout.writeln('Restored ${restored!.id}: ${restored.text}');
  } finally {
    try {
      await Hive.close();
    } finally {
      await directory.delete(recursive: true);
    }
  }
  stdout.writeln('Temporary storage removed.');
}
