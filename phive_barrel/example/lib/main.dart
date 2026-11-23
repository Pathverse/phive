import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

import 'note.dart';

/// Demonstrates fresh reads and TTL-driven deletion through a PHive router.
Future<void> main() async {
  final directory = await Directory.systemTemp.createTemp(
    'phive_barrel_example_',
  );
  try {
    Hive.init(directory.path);
    Hive.registerAdapter(NoteAdapter());

    final router = PHiveDynamicRouter()
      ..applyDescriptors(const [NoteRouterDescriptor()]);
    await router.store(const Note(id: 'note-1', text: 'Hello PHive'));
    final restored = await router.get<Note>('note-1');
    if (restored?.id != 'note-1' || restored?.text != 'Hello PHive') {
      throw StateError('The stored note did not round-trip.');
    }
    stdout.writeln('Restored ${restored!.id}: ${restored.text}');

    // TTL rejects expired payloads; the router handles the requested deletion.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final expired = await router.get<Note>('note-1');
    final stillStored = Hive.lazyBox<Note>(
      'expiring_notes',
    ).containsKey('note-1');
    if (expired != null || stillStored) {
      throw StateError('The expired note was not removed by the router.');
    }
    stdout.writeln('Expired read: $expired');
    stdout.writeln('Expired record removed: ${!stillStored}');
  } finally {
    try {
      await Hive.close();
    } finally {
      await directory.delete(recursive: true);
    }
  }
  stdout.writeln('Temporary storage removed.');
}
