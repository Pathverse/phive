import 'dart:convert';
import 'dart:io';

import 'package:phive_generator/src/auto_type_generator.dart';
import 'package:phive_generator/src/phive_generator.dart';
import 'package:phive_generator/src/type_registry.dart';
import 'package:source_gen/source_gen.dart';
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

TypeIdRegistry _registry(Map<String, dynamic> types) =>
    TypeIdRegistry.fromJson(jsonEncode({'format': 2, 'types': types}));

final _tolerantTypes = <String, dynamic>{
  'TolerantModel': {
    'typeId': 50,
    'layout': 'tolerant',
    'fields': {
      'id': 0,
      'title': 1,
      'count': 2,
      'labels': 3,
      'scores': 4,
      'secret': 9,
    },
  },
  'MigratedModel': {
    'typeId': 51,
    'layout': 'tolerant',
    'fields': {'id': 0, 'body': 1},
    'retiredFields': {'legacy': 2},
    'positionalFields': ['id', 'legacy', 'body'],
  },
};

Future<void> main() async {
  initializeBuildLogTracking();
  final reader = await initializeLibraryReaderForDirectory(
    'test/src',
    'tolerant_model.dart',
  );
  final auto = PhiveAutoTypeGenerator(testRegistry: _registry(_tolerantTypes));

  test('tolerant model emits the tagged adapter', () async {
    _expectGolden(
      await generateForElement(auto, reader, 'TolerantModel'),
      'tolerant_model',
    );
  });

  test('migrated model reads version-2 records through its snapshot', () async {
    final output = await generateForElement(auto, reader, 'MigratedModel');
    expect(output, contains('reader.read(); // retired: legacy'));
    _expectGolden(output, 'migrated_model');
  });

  test('explicit-ID tolerant model uses its indexes as tags', () async {
    final output = await generateForElement(
      PhiveGenerator(),
      reader,
      'ExplicitTolerant',
    );
    expect(output, contains('3: write_obj.id'));
    _expectGolden(output, 'explicit_tolerant');
  });

  test('explicit-ID tolerant model requires explicit indexes', () async {
    await expectLater(
      generateForElement(PhiveGenerator(), reader, 'ExplicitTolerantMissingIndex'),
      throwsA(
        isA<InvalidGenerationSourceError>().having(
          (e) => e.message,
          'message',
          contains('explicit @PHiveField index'),
        ),
      ),
    );
  });

  test('a tolerant type without registry tags is rejected', () async {
    final generator = PhiveAutoTypeGenerator(
      testRegistry: TypeIdRegistry.fromJson('{"TolerantModel": 50}'),
    );
    await expectLater(
      generateForElement(generator, reader, 'TolerantModel'),
      throwsA(
        isA<InvalidGenerationSourceError>().having(
          (e) => e.message,
          'message',
          contains('no tolerant field tags'),
        ),
      ),
    );
  });

  test('registry tags for fields the model no longer declares are rejected', () async {
    final types = Map<String, dynamic>.of(_tolerantTypes);
    types['TolerantModel'] = {
      'typeId': 50,
      'layout': 'tolerant',
      'fields': {
        'id': 0,
        'title': 1,
        'count': 2,
        'labels': 3,
        'scores': 4,
        'secret': 9,
        'gone': 10,
      },
    };
    final generator = PhiveAutoTypeGenerator(testRegistry: _registry(types));
    await expectLater(
      generateForElement(generator, reader, 'TolerantModel'),
      throwsA(isA<InvalidGenerationSourceError>()),
    );
  });
}
