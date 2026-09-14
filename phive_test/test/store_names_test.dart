import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive_test/proofs/naming_proof.dart';

void main() {
  setUpAll(registerNamingAdapters);
  for (final backend in ['dynamic', 'static']) {
    test(
      '$backend generated names reopen without touching legacy stores',
      () async {
        final directory = await Directory.systemTemp.createTemp('phive_names_');
        final storagePath = '${directory.path}/boxes';
        Hive.init(storagePath);
        try {
          final legacy = await Hive.openBox<String>('xy');
          await legacy.put('old', 'legacy payload');
          var router = await openNamingRouter(backend, path: storagePath);
          await namingRoundTrip(router, write: true);
          await Hive.close();

          final names = directory
              .listSync(recursive: true)
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .toSet();
          for (final name in expectedNamingStores) {
            final physical = backend == 'static' ? 'naming_static_$name' : name;
            expect(names, contains('${physical.toLowerCase()}.hive'));
          }
          Hive.init(storagePath);
          router = await openNamingRouter(backend, path: storagePath);
          await namingRoundTrip(router, write: false);
          expect(
            (await Hive.openBox<String>('xy')).get('old'),
            'legacy payload',
          );
        } finally {
          await Hive.close();
          await directory.delete(recursive: true);
        }
      },
      tags: ['proof_generated_store_names'],
    );
  }
}
