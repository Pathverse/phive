// BDD bound integration proofs for the phive library.
//
// Each test is tagged to match exactly one @proof_<id> scenario in features/.
// Run individually via:   flutter test --tags proof_<id>   (from phive/)
// Run all proofs via:     flutter test test/proofs/        (from phive/)
//
// TypeIds 60–69 are reserved for these proofs to avoid conflicts with
// router_test.dart (50–53) and core_test.dart (0).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

// ── Inline types ─────────────────────────────────────────────────────────────

class ProofLesson {
  final String lessonId;
  final String title;
  ProofLesson({required this.lessonId, required this.title});
}

class ProofCard {
  final String cardId;
  final String lessonId;
  ProofCard({required this.cardId, required this.lessonId});
}

class ProofExpiringEntry {
  final String entryId;
  ProofExpiringEntry({required this.entryId});
}

class ProofLessonAdapter extends TypeAdapter<ProofLesson> {
  @override
  final int typeId = 60;
  @override
  ProofLesson read(BinaryReader r) =>
      ProofLesson(lessonId: r.read() as String, title: r.read() as String);
  @override
  void write(BinaryWriter w, ProofLesson obj) {
    w.write(obj.lessonId);
    w.write(obj.title);
  }
}

class ProofCardAdapter extends TypeAdapter<ProofCard> {
  @override
  final int typeId = 61;
  @override
  ProofCard read(BinaryReader r) =>
      ProofCard(cardId: r.read() as String, lessonId: r.read() as String);
  @override
  void write(BinaryWriter w, ProofCard obj) {
    w.write(obj.cardId);
    w.write(obj.lessonId);
  }
}

/// Simulates a hook-driven expiry: always throws deleteEntry + returnNull.
class ProofExpiringAdapter extends TypeAdapter<ProofExpiringEntry> {
  @override
  final int typeId = 62;
  @override
  ProofExpiringEntry read(BinaryReader r) {
    final id = r.read() as String;
    throw PHiveActionException(
      'Proof: entry $id expired',
      behaviors: {PHiveActionBehavior.deleteEntry, PHiveActionBehavior.returnNull},
    );
  }
  @override
  void write(BinaryWriter w, ProofExpiringEntry obj) => w.write(obj.entryId);
}

// ── Shared setup ─────────────────────────────────────────────────────────────

late Directory _tempDir;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.registerAdapter(ProofLessonAdapter());
    Hive.registerAdapter(ProofCardAdapter());
    Hive.registerAdapter(ProofExpiringAdapter());
  });

  setUp(() async {
    _tempDir = await Directory.systemTemp.createTemp('phive_bdd_proof_');
    Hive.init(_tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });

  // ── proof_router_crud ─────────────────────────────────────────────────────

  test(
    'router crud: store, retrieve, and delete typed items',
    () async {
      final router = PHiveDynamicRouter()
        ..register<ProofLesson>(primaryKey: (l) => l.lessonId);

      await router.store(ProofLesson(lessonId: 'L1', title: 'Intro'));
      final retrieved = await router.get<ProofLesson>('L1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Intro');

      await router.delete<ProofLesson>('L1');
      expect(await router.get<ProofLesson>('L1'), isNull);
    },
    tags: ['proof_router_crud'],
  );

  // ── proof_router_container ────────────────────────────────────────────────

  test(
    'router container: traverse and cascade-delete children through a container handle',
    () async {
      final router = PHiveDynamicRouter()
        ..register<ProofLesson>(primaryKey: (l) => l.lessonId)
        ..register<ProofCard>(primaryKey: (c) => c.cardId)
        ..createRef<ProofCard, ProofLesson>(resolve: (c) => c.lessonId);

      final lesson = ProofLesson(lessonId: 'L1', title: 'Lesson');
      await router.store(lesson);
      await router.store(ProofCard(cardId: 'C1', lessonId: 'L1'));
      await router.store(ProofCard(cardId: 'C2', lessonId: 'L1'));

      final handle = router.containerOf<ProofCard, ProofLesson>(lesson);
      final cards = await router.getContainer<ProofCard>(handle);
      expect(cards.length, 2);
      expect(cards.map((c) => c.cardId), containsAll(['C1', 'C2']));

      await router.deleteContainer<ProofCard>(handle);
      expect(await router.get<ProofCard>('C1'), isNull);
      expect(await router.get<ProofCard>('C2'), isNull);
      expect(await router.getContainer<ProofCard>(handle), isEmpty);
    },
    tags: ['proof_router_container'],
  );

  // ── proof_router_reset ────────────────────────────────────────────────────

  test(
    'router reset: clear all data and router remains usable without re-registration',
    () async {
      final router = PHiveDynamicRouter()
        ..register<ProofLesson>(primaryKey: (l) => l.lessonId)
        ..register<ProofCard>(primaryKey: (c) => c.cardId)
        ..createRef<ProofCard, ProofLesson>(resolve: (c) => c.lessonId);

      final lesson = ProofLesson(lessonId: 'L1', title: 'Before reset');
      await router.store(lesson);
      await router.store(ProofCard(cardId: 'C1', lessonId: 'L1'));

      await router.clear();

      expect(await router.get<ProofLesson>('L1'), isNull);
      expect(await router.get<ProofCard>('C1'), isNull);
      expect(await router.getAll<ProofLesson>(), isEmpty);
      expect(
        await router.getContainer<ProofCard>(
          router.containerOf<ProofCard, ProofLesson>(lesson),
        ),
        isEmpty,
      );

      // Schema survives: no re-registration needed.
      await router.store(ProofLesson(lessonId: 'L2', title: 'After reset'));
      expect((await router.get<ProofLesson>('L2'))!.title, 'After reset');
    },
    tags: ['proof_router_reset'],
  );

  // ── proof_router_static_layout ────────────────────────────────────────────

  test(
    'router static layout: schema locks after ensureOpen, CRUD works across BoxCollection',
    () async {
      final router = PHiveStaticRouter(
        collectionName: 'bdd_proof_static',
        path: _tempDir.path,
      )
        ..register<ProofLesson>(primaryKey: (l) => l.lessonId)
        ..register<ProofCard>(primaryKey: (c) => c.cardId)
        ..createRef<ProofCard, ProofLesson>(resolve: (c) => c.lessonId);

      await router.ensureOpen();

      // Registration after open throws.
      expect(
        () => router.register<ProofExpiringEntry>(
          primaryKey: (e) => e.entryId,
        ),
        throwsStateError,
      );

      // CRUD and container work normally.
      final lesson = ProofLesson(lessonId: 'L1', title: 'Static lesson');
      await router.store(lesson);
      await router.store(ProofCard(cardId: 'C1', lessonId: 'L1'));

      expect((await router.get<ProofLesson>('L1'))!.title, 'Static lesson');
      final cards = await router.getContainer<ProofCard>(
        router.containerOf<ProofCard, ProofLesson>(lesson),
      );
      expect(cards.length, 1);
    },
    tags: ['proof_router_static_layout'],
  );

  // ── proof_hook_metadata ───────────────────────────────────────────────────

  test(
    'hook metadata: global and per-field metadata round-trips through serialize/extract',
    () async {
      // PTypeAdapter.serializeMetadataHeader / extractMetadataHeader are the
      // public API hooks use to persist side-channel state.
      final adapter = _MockAdapter();

      final header = adapter.createMetadataHeader(
        globalMetadata: {'written_at': 1000, 'ttl_ms': 30000},
        perFieldMetadata: {
          'token': {'nonce': 'proof-nonce'},
        },
      );

      final encoded = adapter.serializeMetadataHeader(header);
      final decoded = adapter.extractMetadataHeader(encoded);

      expect(decoded.version, PHiveMetadataHeader.currentVersion);
      expect(decoded.globalMetadata['written_at'], 1000);
      expect(decoded.globalMetadata['ttl_ms'], 30000);
      expect(decoded.metadataForField('token')['nonce'], 'proof-nonce');
      expect(decoded.metadataForField('absent'), isEmpty);
    },
    tags: ['proof_hook_metadata'],
  );

  // ── proof_hook_action_exception ───────────────────────────────────────────

  test(
    'hook action exception: expiring entry returns null and is deleted on read',
    () async {
      final writeRouter = PHiveDynamicRouter()
        ..register<ProofExpiringEntry>(
          primaryKey: (e) => e.entryId,
          boxName: 'bdd_expiring',
        );
      await writeRouter.store(ProofExpiringEntry(entryId: 'E1'));

      // Re-open so the adapter fires on read (LazyBox defers deserialization).
      await Hive.close();
      Hive.init(_tempDir.path);

      final readRouter = PHiveDynamicRouter()
        ..register<ProofExpiringEntry>(
          primaryKey: (e) => e.entryId,
          boxName: 'bdd_expiring',
        );

      expect(await readRouter.get<ProofExpiringEntry>('E1'), isNull);

      final box = await Hive.openLazyBox<ProofExpiringEntry>('bdd_expiring');
      expect(box.containsKey('E1'), isFalse);
    },
    tags: ['proof_hook_action_exception'],
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _MockAdapter extends PTypeAdapter<String> {
  @override
  final int typeId = 99;
  @override
  String read(BinaryReader r) => '';
  @override
  void write(BinaryWriter w, String obj) {}
}
