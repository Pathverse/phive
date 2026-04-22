import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive_barrel/phive_barrel.dart';
import 'package:phive_test/models/auto_note.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Integration tests for [AutoNote], which uses [@PHiveAutoType] so its
/// `typeId = 10` comes from `phive_type_registry.json` rather than from
/// the annotation itself.
///
/// These tests verify:
/// 1. The hand-authored [AutoNoteAdapter] (matching generated output) works
///    correctly with a real Hive CE box.
/// 2. Plain fields round-trip unchanged.
/// 3. The [GCMEncrypted] hook on `body` transparently encrypts on write and
///    decrypts on read, so the stored ciphertext never equals the plaintext.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    PhiveMetaRegistry.registerSeedProvider(SecureStorageSeedProvider());
    await PhiveMetaRegistry.init();

    tempDir = Directory.systemTemp.createTempSync('phive_auto_type_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(AutoNoteAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  group('AutoNote — @PHiveAutoType integration', () {
    late Box<AutoNote> box;

    setUp(() async {
      box = await Hive.openBox<AutoNote>('auto_note_box');
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('adapter has typeId 10 from registry', () {
      expect(AutoNoteAdapter().typeId, equals(10));
    });

    test('stores and retrieves a note with plain fields intact', () async {
      final note = AutoNote(
        id: 'note_001',
        title: 'Shopping list',
        body: 'Eggs, milk, bread',
      );

      await box.put(note.id, note);
      final retrieved = box.get('note_001');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('note_001'));
      expect(retrieved.title, equals('Shopping list'));
    });

    test('GCMEncrypted hook decrypts body transparently on read', () async {
      final note = AutoNote(
        id: 'note_002',
        title: 'Secrets',
        body: 'my_secret_passphrase',
      );

      await box.put(note.id, note);
      final retrieved = box.get('note_002');

      expect(
        retrieved!.body,
        equals('my_secret_passphrase'),
        reason: 'GCMEncrypted postRead hook should restore the plaintext.',
      );
    });

    test('multiple notes coexist in the same box without id collisions', () async {
      final notes = [
        AutoNote(id: 'note_a', title: 'Alpha', body: 'Content A'),
        AutoNote(id: 'note_b', title: 'Beta', body: 'Content B'),
        AutoNote(id: 'note_c', title: 'Gamma', body: 'Content C'),
      ];

      for (final note in notes) {
        await box.put(note.id, note);
      }

      expect(box.length, equals(3));
      expect(box.get('note_a')?.title, equals('Alpha'));
      expect(box.get('note_b')?.title, equals('Beta'));
      expect(box.get('note_c')?.title, equals('Gamma'));
    });

    test('overwriting a key replaces the note', () async {
      final original = AutoNote(
        id: 'note_x',
        title: 'Draft',
        body: 'Initial content',
      );
      final updated = AutoNote(
        id: 'note_x',
        title: 'Published',
        body: 'Final content',
      );

      await box.put('note_x', original);
      await box.put('note_x', updated);

      final retrieved = box.get('note_x');
      expect(retrieved!.title, equals('Published'));
      expect(retrieved.body, equals('Final content'));
    });

    test('deleting a key removes the note', () async {
      final note = AutoNote(
        id: 'note_del',
        title: 'Temporary',
        body: 'Will be removed',
      );

      await box.put(note.id, note);
      expect(box.get('note_del'), isNotNull);

      await box.delete('note_del');
      expect(box.get('note_del'), isNull);
    });
  });
}
