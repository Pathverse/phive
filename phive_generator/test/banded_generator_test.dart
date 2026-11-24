import 'dart:convert';

import 'package:phive_generator/src/auto_type_generator.dart';
import 'package:phive_generator/src/type_registry.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

TypeIdRegistry _registry({Map<String, dynamic> types = const {}}) =>
    TypeIdRegistry.fromJson(
      jsonEncode({
        'format': 2,
        'bands': {
          'a': {
            'start': 10000,
            'end': 10999,
            'paths': ['**/banded_a_*.dart'],
          },
          'b': {
            'start': 11000,
            'end': 11999,
            'paths': ['**/banded_b_*.dart'],
          },
        },
        'types': types,
      }),
    );

Future<void> main() async {
  initializeBuildLogTracking();

  final readerA = await initializeLibraryReaderForDirectory(
    'test/src',
    'banded_a_choice.dart',
  );
  final readerB = await initializeLibraryReaderForDirectory(
    'test/src',
    'banded_b_choice.dart',
  );

  final registry = _registry(
    types: {
      'a/Choice': {'typeId': 10000},
      'b/Choice': {'typeId': 11000},
    },
  );

  test('same-named classes in two bands emit their own identifiers', () async {
    final generator = PhiveAutoTypeGenerator(testRegistry: registry);
    final a = await generateForElement(generator, readerA, 'Choice');
    final b = await generateForElement(generator, readerB, 'Choice');

    expect(a, contains('final int typeId = 10000;'));
    expect(b, contains('final int typeId = 11000;'));
  });

  test('an unregistered banded key names the qualified key', () async {
    final generator = PhiveAutoTypeGenerator(testRegistry: _registry());
    await expectLater(
      generateForElement(generator, readerA, 'Choice'),
      throwsA(
        isA<InvalidGenerationSourceError>().having(
          (e) => e.message,
          'message',
          contains('"a/Choice"'),
        ),
      ),
    );
  });

  test('resolved fields must match a recorded positional shape', () async {
    final generator = PhiveAutoTypeGenerator(
      testRegistry: _registry(
        types: {
          'a/Choice': {
            'typeId': 10000,
            'layout': 'positional',
            'fields': {'label': 0, 'id': 1},
          },
        },
      ),
    );
    await expectLater(
      generateForElement(generator, readerA, 'Choice'),
      throwsA(
        isA<InvalidGenerationSourceError>().having(
          (e) => e.message,
          'message',
          allOf(contains('do not match'), contains('assign_type_ids')),
        ),
      ),
    );
  });

  test('a matching recorded positional shape generates normally', () async {
    final generator = PhiveAutoTypeGenerator(
      testRegistry: _registry(
        types: {
          'a/Choice': {
            'typeId': 10000,
            'layout': 'positional',
            'fields': {'id': 0, 'label': 1},
          },
        },
      ),
    );
    final output = await generateForElement(generator, readerA, 'Choice');
    expect(output, contains('final int typeId = 10000;'));
  });
}
