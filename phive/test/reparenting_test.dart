import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

import 'router_test.dart'
    show
        TestCard,
        TestCardAdapter,
        TestDeck,
        TestDeckAdapter,
        TestLesson,
        TestLessonAdapter;

class _RejectingCardAdapter extends TestCardAdapter {
  @override
  TestCard read(BinaryReader reader) {
    final card = super.read(reader);
    if (card.content == 'expired') {
      // Any attempt to deserialize the old value must fail the overwrite.
      throw PHiveActionException('Expired old child');
    }
    return card;
  }
}

void main() {
  late Directory directory;

  setUpAll(() {
    Hive.registerAdapter(TestLessonAdapter());
    Hive.registerAdapter(_RejectingCardAdapter());
    Hive.registerAdapter(TestDeckAdapter());
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive_reparent_');
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  for (final backend in ['dynamic', 'static']) {
    group(backend, () {
      Future<PHiveRouter> open({bool secondRef = false}) async {
        final PHiveRouter router = backend == 'dynamic'
            ? PHiveDynamicRouter()
            : PHiveStaticRouter(
                collectionName: 'relations',
                path: directory.path,
              );
        router
          ..register<TestLesson>(primaryKey: (item) => item.lessonId)
          ..register<TestCard>(primaryKey: (item) => item.cardId)
          ..register<TestDeck>(primaryKey: (item) => item.deckId)
          ..createRef<TestCard, TestLesson>(resolve: (item) => item.lessonId);
        if (secondRef) {
          router.createRef<TestCard, TestDeck>(resolve: (item) => item.content);
        }
        await router.ensureOpen();
        return router;
      }

      final a = TestLesson(lessonId: 'A', title: 'Former parent');
      final b = TestLesson(lessonId: 'B', title: 'New parent');
      TestCard child(String parent, {String content = 'payload'}) =>
          TestCard(cardId: 'moving', lessonId: parent, content: content);

      test(
        'moving a child updates retained containers and preserves siblings',
        () async {
          final router = await open();
          final oldHandle = router.containerOf<TestCard, TestLesson>(a);
          final newHandle = router.containerOf<TestCard, TestLesson>(b);
          await router.store(child('A'));
          await router.store(
            TestCard(cardId: 'stay', lessonId: 'A', content: 'sibling'),
          );
          await router.store(child('B', content: 'updated'));
          await router.store(child('B', content: 'updated'));

          expect(
            (await router.getContainer(oldHandle)).map((item) => item.cardId),
            ['stay'],
          );
          final moved = await router.getContainer(newHandle);
          expect(moved.map((item) => item.cardId), ['moving']);
          expect(moved.single.content, 'updated');
        },
        tags: ['proof_router_reparenting'],
      );

      for (final cascadeParent in [false, true]) {
        test(
          'former ${cascadeParent ? 'parent cascade' : 'container deletion'} preserves moved child',
          () async {
            final router = await open();
            await router.store(a);
            await router.store(b);
            await router.store(child('A'));
            await router.store(child('B'));
            if (cascadeParent) {
              await router.deleteWithChildren(a);
              expect(await router.get<TestLesson>('A'), isNull);
            } else {
              await router.deleteContainer(
                router.containerOf<TestCard, TestLesson>(a),
              );
              expect(await router.get<TestLesson>('A'), isNotNull);
            }
            expect(await router.get<TestCard>('moving'), isNotNull);
            expect(
              (await router.getContainer(
                router.containerOf<TestCard, TestLesson>(b),
              )).map((item) => item.cardId),
              ['moving'],
            );
          },
          tags: ['proof_router_reparenting'],
        );
      }

      for (final removal in ['none', 'delete', 'clearType']) {
        test('reconciles persisted refs after reopen and $removal', () async {
          var router = await open();
          await router.store(child('A'));
          if (removal == 'delete') await router.delete<TestCard>('moving');
          if (removal == 'clearType') await router.clearType<TestCard>();
          await Hive.close();
          Hive.init(directory.path);
          router = await open();
          await router.store(child('B'));
          expect(
            await router.getContainer(
              router.containerOf<TestCard, TestLesson>(a),
            ),
            isEmpty,
          );
          expect(
            (await router.getContainer(
              router.containerOf<TestCard, TestLesson>(b),
            )).map((item) => item.cardId),
            ['moving'],
          );
        });
      }

      test(
        'reconciles all relationships without changing unrelated memberships',
        () async {
          final router = await open(secondRef: true);
          final deck1 = TestDeck(deckId: 'D1', lessonId: 'A');
          final deck2 = TestDeck(deckId: 'D2', lessonId: 'B');
          await router.store(child('A', content: 'D1'));
          await router.store(
            TestCard(cardId: 'stay', lessonId: 'A', content: 'D1'),
          );
          await router.store(child('B', content: 'D1'));
          expect(
            (await router.getContainer(
              router.containerOf<TestCard, TestDeck>(deck1),
            )).map((item) => item.cardId),
            unorderedEquals(['moving', 'stay']),
          );
          await router.store(child('B', content: 'D2'));
          expect(
            (await router.getContainer(
              router.containerOf<TestCard, TestDeck>(deck1),
            )).map((item) => item.cardId),
            ['stay'],
          );
          expect(
            (await router.getContainer(
              router.containerOf<TestCard, TestDeck>(deck2),
            )).map((item) => item.cardId),
            ['moving'],
          );
          expect(
            (await router.getContainer(
              router.containerOf<TestCard, TestLesson>(a),
            )).map((item) => item.cardId),
            ['stay'],
          );
          expect(
            (await router.getContainer(
              router.containerOf<TestCard, TestLesson>(b),
            )).map((item) => item.cardId),
            ['moving'],
          );
        },
      );

      test(
        'overwrites a read-rejected child without deserializing the old value',
        () async {
          final router = await open();
          await router.store(child('A', content: 'expired'));
          await router.store(child('B', content: 'fresh'));
          expect(
            await router.getContainer(
              router.containerOf<TestCard, TestLesson>(a),
            ),
            isEmpty,
          );
          expect((await router.get<TestCard>('moving'))!.content, 'fresh');
        },
      );
    });
  }
}
