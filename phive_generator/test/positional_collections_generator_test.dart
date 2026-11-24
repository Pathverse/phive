import 'dart:io';

import 'package:phive_generator/src/phive_generator.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

/// Set `UPDATE_GOLDENS=1` to rewrite golden files after reviewing a change.
final bool _update = Platform.environment['UPDATE_GOLDENS'] == '1';

void _expectGolden(String actual, String name) {
  final file = File('test/goldens/$name.golden');
  if (_update || !file.existsSync()) {
    file.writeAsStringSync(actual);
    if (!_update) fail('Golden $name was missing and has been written.');
  }
  expect(actual, file.readAsStringSync());
}

Future<void> main() async {
  initializeBuildLogTracking();
  final reader = await initializeLibraryReaderForDirectory(
    'test/src',
    'positional_collections_model.dart',
  );

  test('positional collections convert element by element', () async {
    final output = await generateForElement(
      PhiveGenerator(),
      reader,
      'PositionalCollectionModel',
    );
    expect(output, isNot(contains('as List<CollectionItem>')));
    expect(output, contains('castStored<CollectionItem>(e0)'));
    expect(output, contains("fieldName: 'hooked'"));
    _expectGolden(output, 'positional_collections');
  });
}
