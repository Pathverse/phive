@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:phive/phive.dart';

void main() {
  test(
    'open IndexedDB routers reconcile moves using current memberships',
    () async {
      final name = 'phive_reparenting_${DateTime.now().microsecondsSinceEpoch}';
      Future<PHiveStaticRouter> open() async {
        final router = PHiveStaticRouter(collectionName: name)
          ..register<String>(primaryKey: (item) => item, boxName: 'parents')
          ..register<int>(
            primaryKey: (item) => '${item % 100}',
            boxName: 'children',
          )
          ..createRef<int, String>(
            resolve: (item) => 'p${item ~/ 100}',
            refBoxName: 'memberships',
          );
        await router.ensureOpen();
        return router;
      }

      final first = await open();
      final second = await open();
      addTearDown(first.clear);
      await first.store(101);
      await first.store(102);
      await second.store(201);
      final former = second.containerOf<int, String>('p2');
      expect(await second.getContainer(former), [201]);
      await first.store(301);

      final fresh = await open();
      expect(await fresh.getContainer(fresh.containerOf<int, String>('p1')), [
        102,
      ]);
      expect(
        await fresh.getContainer(fresh.containerOf<int, String>('p2')),
        isEmpty,
      );
      expect(await fresh.getContainer(fresh.containerOf<int, String>('p3')), [
        301,
      ]);
      expect(await second.getContainer(former), isEmpty);
      await second.deleteWithChildren('p2');
      expect(await (await open()).get<int>('1'), 301);
    },
  );
}
