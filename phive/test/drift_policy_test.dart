import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

/// Record whose adapter reports schema drift or fails depending on [mode].
class Entry {
  final String id;
  final String mode;
  final String parentId;
  final Legacy? nested;

  Entry(this.id, {this.mode = 'ok', this.parentId = 'p', this.nested});
}

/// Nested type standing in for a retired identifier.
class Legacy {
  final String value;
  Legacy(this.value);
}

/// Parent type for container traversal.
class Parent {
  final String id;
  Parent(this.id);
}

class EntryAdapter extends TypeAdapter<Entry> {
  @override
  final int typeId = 90;

  @override
  Entry read(BinaryReader reader) {
    final id = reader.read() as String;
    final mode = reader.read() as String;
    final parentId = reader.read() as String;
    final nested = reader.read() as Legacy?;
    if (mode == 'drift') {
      throw PHiveSchemaDriftException(
        typeName: 'Entry',
        fieldName: 'mode',
        reason: 'test drift',
      );
    }
    if (mode == 'raw') throw StateError('adapter bug');
    return Entry(id, mode: mode, parentId: parentId, nested: nested);
  }

  @override
  void write(BinaryWriter writer, Entry obj) {
    writer.write(obj.id);
    writer.write(obj.mode);
    writer.write(obj.parentId);
    writer.write(obj.nested);
  }
}

class LegacyAdapter extends TypeAdapter<Legacy> {
  @override
  final int typeId = 91;

  @override
  Legacy read(BinaryReader reader) => Legacy(reader.read() as String);

  @override
  void write(BinaryWriter writer, Legacy obj) => writer.write(obj.value);
}

class ParentAdapter extends TypeAdapter<Parent> {
  @override
  final int typeId = 92;

  @override
  Parent read(BinaryReader reader) => Parent(reader.read() as String);

  @override
  void write(BinaryWriter writer, Parent obj) => writer.write(obj.id);
}

void _registerAll() {
  if (!Hive.isAdapterRegistered(90)) {
    Hive.registerAdapter<Entry>(EntryAdapter());
  }
  if (!Hive.isAdapterRegistered(91)) {
    Hive.registerAdapter<Legacy>(LegacyAdapter());
  }
  if (!Hive.isAdapterRegistered(92)) {
    Hive.registerAdapter<Parent>(ParentAdapter());
  }
}

/// Simulates a later build that no longer registers [LegacyAdapter].
class _RetiredLegacy {}

void _retireLegacy({bool tombstone = true}) {
  Hive.resetAdapters();
  Hive.registerAdapter<Entry>(EntryAdapter());
  Hive.registerAdapter<Parent>(ParentAdapter());
  if (tombstone) registerPHiveTombstone<_RetiredLegacy>(91);
}

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive_drift_');
    Hive.init(directory.path);
    Hive.resetAdapters();
    _registerAll();
  });

  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  for (final backend in ['dynamic', 'static']) {
    PHiveRouter build({
      PHiveDriftPolicy? routerDefault,
      PHiveDriftPolicy? entryPolicy,
    }) {
      final router = backend == 'dynamic'
          ? (routerDefault == null
                ? PHiveDynamicRouter()
                : PHiveDynamicRouter(driftPolicy: routerDefault))
          : (routerDefault == null
                ? PHiveStaticRouter(
                    collectionName: 'drift',
                    path: directory.path,
                  )
                : PHiveStaticRouter(
                    collectionName: 'drift',
                    path: directory.path,
                    driftPolicy: routerDefault,
                  ));
      router
        ..register<Entry>(
          primaryKey: (e) => e.id,
          boxName: 'entries',
          driftPolicy: entryPolicy,
        )
        ..register<Parent>(primaryKey: (p) => p.id, boxName: 'parents')
        ..createRef<Entry, Parent>(
          resolve: (e) => e.parentId,
          refBoxName: 'entries_by_parent',
        );
      return router;
    }

    group('$backend router', () {
      test('default policy propagates drift and keeps the entry', () async {
        final router = build();
        await router.ensureOpen();
        await router.store(Entry('e1', mode: 'drift'));

        await expectLater(
          router.get<Entry>('e1'),
          throwsA(isA<PHiveSchemaDriftException>()),
        );
        await expectLater(
          router.get<Entry>('e1'),
          throwsA(isA<PHiveSchemaDriftException>()),
          reason: 'the entry must still be stored',
        );
      });

      test('opt-in registration removes the drifted entry', () async {
        final router = build(entryPolicy: PHiveDriftPolicy.deleteAndMiss);
        await router.ensureOpen();
        await router.store(Entry('e1', mode: 'drift'));
        await router.store(Entry('e2'));

        expect(await router.get<Entry>('e1'), isNull);
        expect((await router.getAll<Entry>()).map((e) => e.id), ['e2']);
      });

      test('router-level default applies to registrations', () async {
        final router = build(routerDefault: PHiveDriftPolicy.deleteAndMiss);
        await router.ensureOpen();
        await router.store(Entry('e1', mode: 'drift'));

        expect(await router.get<Entry>('e1'), isNull);
      });

      test('a per-registration policy overrides the router default', () async {
        final router = build(
          routerDefault: PHiveDriftPolicy.deleteAndMiss,
          entryPolicy: PHiveDriftPolicy.propagate,
        );
        await router.ensureOpen();
        await router.store(Entry('e1', mode: 'drift'));

        await expectLater(
          router.get<Entry>('e1'),
          throwsA(isA<PHiveSchemaDriftException>()),
        );
      });

      test('an unrelated adapter failure always propagates', () async {
        final router = build(entryPolicy: PHiveDriftPolicy.deleteAndMiss);
        await router.ensureOpen();
        await router.store(Entry('e1', mode: 'raw'));

        await expectLater(router.get<Entry>('e1'), throwsStateError);
        await expectLater(
          router.get<Entry>('e1'),
          throwsStateError,
          reason: 'the entry must still be stored',
        );
      });

      test('a retired nested identifier propagates by default', () async {
        final router = build();
        await router.ensureOpen();
        await router.store(Entry('e1', nested: Legacy('old')));
        _retireLegacy();

        await expectLater(
          router.get<Entry>('e1'),
          throwsA(isA<PHiveSchemaDriftException>()),
        );
        _retireLegacy(tombstone: false);
        _registerAll();
        expect((await router.get<Entry>('e1'))!.nested!.value, 'old');
      });

      test('a retired nested identifier is a miss under opt-in', () async {
        final router = build(entryPolicy: PHiveDriftPolicy.deleteAndMiss);
        await router.ensureOpen();
        await router.store(Entry('e1', nested: Legacy('old')));
        _retireLegacy();

        expect(await router.get<Entry>('e1'), isNull);
        _registerAll();
        expect(await router.get<Entry>('e1'), isNull);
      });

      for (final policy in PHiveDriftPolicy.values) {
        test('unknown untombstoned ID is preserved under $policy', () async {
          final router = build(entryPolicy: policy);
          await router.ensureOpen();
          await router.store(Entry('e1', nested: Legacy('old')));
          _retireLegacy(tombstone: false);
          await expectLater(router.get<Entry>('e1'), throwsA(isA<HiveError>()));
          _registerAll();
          expect((await router.get<Entry>('e1'))!.nested!.value, 'old');
        });
      }

      test('enumeration skips and removes drifted entries', () async {
        final router = build(entryPolicy: PHiveDriftPolicy.deleteAndMiss);
        await router.ensureOpen();
        await router.store(Entry('e1'));
        await router.store(Entry('e2', mode: 'drift'));
        await router.store(Entry('e3'));

        final ids = (await router.getAll<Entry>()).map((e) => e.id).toList()
          ..sort();
        expect(ids, ['e1', 'e3']);
        expect(await router.get<Entry>('e2'), isNull);
      });

      test('container traversal skips and removes drifted entries', () async {
        final router = build(entryPolicy: PHiveDriftPolicy.deleteAndMiss);
        await router.ensureOpen();
        final parent = Parent('p');
        await router.store(parent);
        await router.store(Entry('e1'));
        await router.store(Entry('e2', mode: 'drift'));
        await router.store(Entry('e3'));

        final children = await router.getContainer(
          router.containerOf<Entry, Parent>(parent),
        );
        expect(children.map((e) => e.id).toList()..sort(), ['e1', 'e3']);
        expect(await router.get<Entry>('e2'), isNull);
      });
    });
  }
}
