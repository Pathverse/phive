import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

// ─── Test Models ─────────────────────────────────────────────────────────────

class TestLesson {
  final String lessonId;
  final String title;
  TestLesson({required this.lessonId, required this.title});
}

class TestCard {
  final String cardId;
  final String lessonId;
  final String content;
  TestCard({required this.cardId, required this.lessonId, required this.content});
}

class TestDeck {
  final String deckId;
  final String lessonId;
  TestDeck({required this.deckId, required this.lessonId});
}

class TestLessonAdapter extends TypeAdapter<TestLesson> {
  @override
  final int typeId = 50;

  @override
  TestLesson read(BinaryReader reader) => TestLesson(
        lessonId: reader.read() as String,
        title: reader.read() as String,
      );

  @override
  void write(BinaryWriter writer, TestLesson obj) {
    writer.write(obj.lessonId);
    writer.write(obj.title);
  }
}

class TestCardAdapter extends TypeAdapter<TestCard> {
  @override
  final int typeId = 51;

  @override
  TestCard read(BinaryReader reader) => TestCard(
        cardId: reader.read() as String,
        lessonId: reader.read() as String,
        content: reader.read() as String,
      );

  @override
  void write(BinaryWriter writer, TestCard obj) {
    writer.write(obj.cardId);
    writer.write(obj.lessonId);
    writer.write(obj.content);
  }
}

class TestDeckAdapter extends TypeAdapter<TestDeck> {
  @override
  final int typeId = 52;

  @override
  TestDeck read(BinaryReader reader) => TestDeck(
        deckId: reader.read() as String,
        lessonId: reader.read() as String,
      );

  @override
  void write(BinaryWriter writer, TestDeck obj) {
    writer.write(obj.deckId);
    writer.write(obj.lessonId);
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

PHiveDynamicRouter _baseRouter() {
  final r = PHiveDynamicRouter();
  r.register<TestLesson>(primaryKey: (l) => l.lessonId);
  r.register<TestCard>(primaryKey: (c) => c.cardId);
  r.createRef<TestCard, TestLesson>(resolve: (c) => c.lessonId);
  return r;
}

// Builds a PHiveStaticRouter with TestLesson + TestCard + Card→Lesson ref.
// Must call ensureOpen() before any CRUD. Uses the tempDir set by setUp().
PHiveStaticRouter _baseStaticRouter(String path) => PHiveStaticRouter(
      collectionName: 'test_static',
      path: path,
    )
      ..register<TestLesson>(primaryKey: (l) => l.lessonId)
      ..register<TestCard>(primaryKey: (c) => c.cardId)
      ..createRef<TestCard, TestLesson>(resolve: (c) => c.lessonId);

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.registerAdapter(TestLessonAdapter());
    Hive.registerAdapter(TestCardAdapter());
    Hive.registerAdapter(TestDeckAdapter());
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phive_router_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ── 1. Type Registration ──────────────────────────────────────────────────

  group('register — type registration', () {
    test('store and get a registered type round-trips correctly', () async {
      final router = PHiveDynamicRouter();
      router.register<TestLesson>(primaryKey: (l) => l.lessonId);

      await router.store(TestLesson(lessonId: 'L001', title: 'Intro to Dart'));
      final result = await router.get<TestLesson>('L001');

      expect(result, isNotNull);
      expect(result!.lessonId, 'L001');
      expect(result.title, 'Intro to Dart');
    });

    test('get returns null for missing key', () async {
      final router = PHiveDynamicRouter();
      router.register<TestLesson>(primaryKey: (l) => l.lessonId);

      final result = await router.get<TestLesson>('does_not_exist');
      expect(result, isNull);
    });

    test('store throws StateError for unregistered type', () async {
      final router = PHiveDynamicRouter();
      expect(
        () => router.store(TestLesson(lessonId: 'L001', title: 'test')),
        throwsStateError,
      );
    });

    test('get throws StateError for unregistered type', () async {
      final router = PHiveDynamicRouter();
      expect(() => router.get<TestLesson>('L001'), throwsStateError);
    });

    test('custom boxName is used when provided', () async {
      final router = PHiveDynamicRouter();
      router.register<TestLesson>(
        primaryKey: (l) => l.lessonId,
        boxName: 'my_custom_lessons',
      );
      await router.store(TestLesson(lessonId: 'L001', title: 'Custom'));
      expect(Hive.isBoxOpen('my_custom_lessons'), isTrue);
    });

    test('two types can coexist independently', () async {
      final router = PHiveDynamicRouter();
      router.register<TestLesson>(primaryKey: (l) => l.lessonId);
      router.register<TestCard>(primaryKey: (c) => c.cardId);

      await router.store(TestLesson(lessonId: 'L001', title: 'Lesson'));
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'Card'));

      expect(await router.get<TestLesson>('L001'), isNotNull);
      expect(await router.get<TestCard>('C001'), isNotNull);
    });
  });

  // ── 2. delete ─────────────────────────────────────────────────────────────

  group('delete — primary item removal', () {
    test('delete removes a stored item', () async {
      final router = PHiveDynamicRouter();
      router.register<TestLesson>(primaryKey: (l) => l.lessonId);

      await router.store(TestLesson(lessonId: 'L001', title: 'Will be deleted'));
      await router.delete<TestLesson>('L001');

      expect(await router.get<TestLesson>('L001'), isNull);
    });

    test('delete on non-existent key does not throw', () async {
      final router = PHiveDynamicRouter();
      router.register<TestLesson>(primaryKey: (l) => l.lessonId);
      await expectLater(router.delete<TestLesson>('missing'), completes);
    });

    test('delete throws StateError for unregistered type', () async {
      final router = PHiveDynamicRouter();
      expect(() => router.delete<TestLesson>('L001'), throwsStateError);
    });
  });

  // ── 3. createRef + store interaction ─────────────────────────────────────

  group('createRef — ref store population on store()', () {
    test('storing a child updates its ref entry', () async {
      final router = _baseRouter();
      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      await router.store(lesson);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'Card 1'));

      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      final cards = await router.getContainer<TestCard>(handle);

      expect(cards.length, 1);
      expect(cards.first.cardId, 'C001');
    });

    test('multiple children accumulate under the same parent ref', () async {
      final router = _baseRouter();
      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      await router.store(lesson);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'A'));
      await router.store(TestCard(cardId: 'C002', lessonId: 'L001', content: 'B'));
      await router.store(TestCard(cardId: 'C003', lessonId: 'L001', content: 'C'));

      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      final cards = await router.getContainer<TestCard>(handle);

      expect(cards.length, 3);
      expect(cards.map((c) => c.cardId), containsAll(['C001', 'C002', 'C003']));
    });

    test('storing the same child twice does not duplicate the ref entry', () async {
      final router = _baseRouter();
      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      final card = TestCard(cardId: 'C001', lessonId: 'L001', content: 'Card 1');
      await router.store(lesson);
      await router.store(card);
      await router.store(card); // duplicate

      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      final cards = await router.getContainer<TestCard>(handle);
      expect(cards.length, 1);
    });

    test('children are scoped per parent — different parents have isolated refs', () async {
      final router = _baseRouter();
      final l1 = TestLesson(lessonId: 'L001', title: 'L1');
      final l2 = TestLesson(lessonId: 'L002', title: 'L2');
      await router.store(l1);
      await router.store(l2);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'for L1'));
      await router.store(TestCard(cardId: 'C002', lessonId: 'L002', content: 'for L2'));

      final cards1 = await router.getContainer<TestCard>(
          router.containerOf<TestCard, TestLesson>(l1));
      final cards2 = await router.getContainer<TestCard>(
          router.containerOf<TestCard, TestLesson>(l2));

      expect(cards1.length, 1);
      expect(cards1.first.cardId, 'C001');
      expect(cards2.length, 1);
      expect(cards2.first.cardId, 'C002');
    });
  });

  // ── 4. containerOf ────────────────────────────────────────────────────────

  group('containerOf — handle resolution', () {
    test('returns a handle with correct parentKey', () async {
      final router = _baseRouter();
      final lesson = TestLesson(lessonId: 'L001', title: 'L');
      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      expect(handle.parentKey, 'L001');
    });

    test('getContainer returns empty list when container has no children', () async {
      final router = _baseRouter();
      final lesson = TestLesson(lessonId: 'L001', title: 'Empty');
      await router.store(lesson);

      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      expect(await router.getContainer<TestCard>(handle), isEmpty);
    });

    test('throws StateError when ref for T→P is not registered', () {
      final router = PHiveDynamicRouter();
      router.register<TestLesson>(primaryKey: (l) => l.lessonId);
      router.register<TestCard>(primaryKey: (c) => c.cardId);
      // no createRef

      final lesson = TestLesson(lessonId: 'L001', title: 'L');
      expect(
        () => router.containerOf<TestCard, TestLesson>(lesson),
        throwsStateError,
      );
    });
  });

  // ── 5. deleteContainer ────────────────────────────────────────────────────

  group('deleteContainer — cascade child removal', () {
    test('removes all child items from their primary box', () async {
      final router = _baseRouter();
      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      await router.store(lesson);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'A'));
      await router.store(TestCard(cardId: 'C002', lessonId: 'L001', content: 'B'));

      await router.deleteContainer<TestCard>(
          router.containerOf<TestCard, TestLesson>(lesson));

      expect(await router.get<TestCard>('C001'), isNull);
      expect(await router.get<TestCard>('C002'), isNull);
    });

    test('clears the ref store entry after deletion', () async {
      final router = _baseRouter();
      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      await router.store(lesson);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'A'));

      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      await router.deleteContainer<TestCard>(handle);

      expect(await router.getContainer<TestCard>(handle), isEmpty);
    });

    test('does not affect other parent containers', () async {
      final router = _baseRouter();
      final l1 = TestLesson(lessonId: 'L001', title: 'L1');
      final l2 = TestLesson(lessonId: 'L002', title: 'L2');
      await router.store(l1);
      await router.store(l2);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'A'));
      await router.store(TestCard(cardId: 'C002', lessonId: 'L002', content: 'B'));

      await router.deleteContainer<TestCard>(
          router.containerOf<TestCard, TestLesson>(l1));

      final cards2 = await router.getContainer<TestCard>(
          router.containerOf<TestCard, TestLesson>(l2));
      expect(cards2.length, 1);
      expect(cards2.first.cardId, 'C002');
    });

    test('deleteContainer on empty container completes without error', () async {
      final router = _baseRouter();
      final lesson = TestLesson(lessonId: 'L001', title: 'Empty');
      await router.store(lesson);
      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      await expectLater(router.deleteContainer<TestCard>(handle), completes);
    });
  });

  // ── 6. deleteWithChildren ─────────────────────────────────────────────────

  group('deleteWithChildren — parent + cascade', () {
    test('removes parent item and all registered children', () async {
      final router = _baseRouter();
      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      await router.store(lesson);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'A'));
      await router.store(TestCard(cardId: 'C002', lessonId: 'L001', content: 'B'));

      await router.deleteWithChildren<TestLesson>(lesson);

      expect(await router.get<TestLesson>('L001'), isNull);
      expect(await router.get<TestCard>('C001'), isNull);
      expect(await router.get<TestCard>('C002'), isNull);
    });

    test('only deletes targeted parent and its children', () async {
      final router = _baseRouter();
      final l1 = TestLesson(lessonId: 'L001', title: 'L1');
      final l2 = TestLesson(lessonId: 'L002', title: 'L2');
      await router.store(l1);
      await router.store(l2);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'A'));
      await router.store(TestCard(cardId: 'C002', lessonId: 'L002', content: 'B'));

      await router.deleteWithChildren<TestLesson>(l1);

      expect(await router.get<TestLesson>('L001'), isNull);
      expect(await router.get<TestCard>('C001'), isNull);
      expect(await router.get<TestLesson>('L002'), isNotNull);
      expect(await router.get<TestCard>('C002'), isNotNull);
    });

    test('handles multiple child types registered against same parent', () async {
      final router = PHiveDynamicRouter();
      router.register<TestLesson>(primaryKey: (l) => l.lessonId);
      router.register<TestCard>(primaryKey: (c) => c.cardId);
      router.register<TestDeck>(primaryKey: (d) => d.deckId);
      router.createRef<TestCard, TestLesson>(resolve: (c) => c.lessonId);
      router.createRef<TestDeck, TestLesson>(resolve: (d) => d.lessonId);

      final lesson = TestLesson(lessonId: 'L001', title: 'L');
      await router.store(lesson);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'Card'));
      await router.store(TestDeck(deckId: 'D001', lessonId: 'L001'));

      await router.deleteWithChildren<TestLesson>(lesson);

      expect(await router.get<TestLesson>('L001'), isNull);
      expect(await router.get<TestCard>('C001'), isNull);
      expect(await router.get<TestDeck>('D001'), isNull);
    });
  });

  // ── 7. PHiveStaticRouter ──────────────────────────────────────────────────

  group('PHiveStaticRouter — registration lock + full CRUD', () {
    // ── Registration lock ────────────────────────────────────────────────────

    test('register throws StateError after ensureOpen', () async {
      final router = PHiveStaticRouter(
        collectionName: 'test_static_lock',
        path: tempDir.path,
      )..register<TestLesson>(primaryKey: (l) => l.lessonId);

      await router.ensureOpen();

      expect(
        () => router.register<TestCard>(primaryKey: (c) => c.cardId),
        throwsStateError,
      );
    });

    test('createRef throws StateError after ensureOpen', () async {
      final router = PHiveStaticRouter(
        collectionName: 'test_static_reflock',
        path: tempDir.path,
      )
        ..register<TestLesson>(primaryKey: (l) => l.lessonId)
        ..register<TestCard>(primaryKey: (c) => c.cardId);

      await router.ensureOpen();

      expect(
        () => router.createRef<TestCard, TestLesson>(resolve: (c) => c.lessonId),
        throwsStateError,
      );
    });

    test('ensureOpen is idempotent — multiple calls do not throw', () async {
      final router = _baseStaticRouter(tempDir.path);
      await router.ensureOpen();
      await expectLater(router.ensureOpen(), completes);
    });

    // ── Store / Get / Delete ─────────────────────────────────────────────────

    test('store and get a registered type round-trips correctly', () async {
      final router = _baseStaticRouter(tempDir.path);
      await router.ensureOpen();

      await router.store(TestLesson(lessonId: 'L001', title: 'Static Lesson'));
      final result = await router.get<TestLesson>('L001');

      expect(result, isNotNull);
      expect(result!.lessonId, 'L001');
      expect(result.title, 'Static Lesson');
    });

    test('get returns null for missing key', () async {
      final router = _baseStaticRouter(tempDir.path);
      await router.ensureOpen();

      expect(await router.get<TestLesson>('does_not_exist'), isNull);
    });

    test('delete removes a stored item', () async {
      final router = _baseStaticRouter(tempDir.path);
      await router.ensureOpen();

      await router.store(TestLesson(lessonId: 'L001', title: 'Will be deleted'));
      await router.delete<TestLesson>('L001');

      expect(await router.get<TestLesson>('L001'), isNull);
    });

    // ── Ref system ───────────────────────────────────────────────────────────

    test('storing a child updates its ref entry', () async {
      final router = _baseStaticRouter(tempDir.path);
      await router.ensureOpen();

      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      await router.store(lesson);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'Card 1'));

      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      final cards = await router.getContainer<TestCard>(handle);

      expect(cards.length, 1);
      expect(cards.first.cardId, 'C001');
    });

    test('storing the same child twice does not duplicate the ref entry', () async {
      final router = _baseStaticRouter(tempDir.path);
      await router.ensureOpen();

      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      final card = TestCard(cardId: 'C001', lessonId: 'L001', content: 'Card');
      await router.store(lesson);
      await router.store(card);
      await router.store(card); // duplicate

      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      expect((await router.getContainer<TestCard>(handle)).length, 1);
    });

    // ── deleteContainer ──────────────────────────────────────────────────────

    test('deleteContainer removes children and clears the ref entry', () async {
      final router = _baseStaticRouter(tempDir.path);
      await router.ensureOpen();

      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      await router.store(lesson);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'A'));
      await router.store(TestCard(cardId: 'C002', lessonId: 'L001', content: 'B'));

      final handle = router.containerOf<TestCard, TestLesson>(lesson);
      await router.deleteContainer<TestCard>(handle);

      expect(await router.get<TestCard>('C001'), isNull);
      expect(await router.get<TestCard>('C002'), isNull);
      expect(await router.getContainer<TestCard>(handle), isEmpty);
    });

    // ── deleteWithChildren ───────────────────────────────────────────────────

    test('deleteWithChildren removes parent and all children', () async {
      final router = _baseStaticRouter(tempDir.path);
      await router.ensureOpen();

      final lesson = TestLesson(lessonId: 'L001', title: 'Lesson');
      await router.store(lesson);
      await router.store(TestCard(cardId: 'C001', lessonId: 'L001', content: 'A'));
      await router.store(TestCard(cardId: 'C002', lessonId: 'L001', content: 'B'));

      await router.deleteWithChildren<TestLesson>(lesson);

      expect(await router.get<TestLesson>('L001'), isNull);
      expect(await router.get<TestCard>('C001'), isNull);
      expect(await router.get<TestCard>('C002'), isNull);
    });
  });
}
