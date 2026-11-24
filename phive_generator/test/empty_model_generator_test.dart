import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:phive_generator/src/auto_type_generator.dart';
import 'package:phive_generator/src/phive_generator.dart';
import 'package:phive_generator/src/type_registry.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

Future<void> main() async {
  initializeBuildLogTracking();
  final reader = await initializeLibraryReaderForDirectory(
    'test/src',
    'empty_models.dart',
  );
  final registry = TypeIdRegistry.fromJson(
    jsonEncode({
      'format': 2,
      'types': {
        'AutoEmptyPositional': {
          'typeId': 72,
          'layout': 'positional',
          'fields': <String, int>{},
        },
        'AutoEmptyTolerant': {
          'typeId': 73,
          'layout': 'tolerant',
          'fields': <String, int>{},
        },
      },
    }),
  );
  final auto = PhiveAutoTypeGenerator(testRegistry: registry);
  for (final item in {
    'EmptyPositional': (70, 'positional', 'empty_positional'),
    'EmptyTolerant': (71, 'tolerant', 'empty_tolerant'),
    'AutoEmptyPositional': (72, 'positional', 'auto_empty_positional'),
    'AutoEmptyTolerant': (73, 'tolerant', 'auto_empty_tolerant'),
  }.entries) {
    test('${item.key} has an empty adapter and normal fingerprint', () async {
      final output = await generateForElement(
        item.key.startsWith('Auto') ? auto : PhiveGenerator(),
        reader,
        item.key,
      );
      final file = File('test/goldens/${item.value.$3}.golden');
      if (Platform.environment['UPDATE_GOLDENS'] == '1') {
        file.writeAsStringSync(output);
      }
      expect(output, file.readAsStringSync());
      expect(
        output,
        contains(
          sha256
              .convert(utf8.encode('${item.value.$1}|${item.value.$2}|'))
              .toString(),
        ),
      );
      expect(output, isNot(contains('final write_obj')));
      expect(output, isNot(contains('final Map<int, dynamic> values')));
      expect(output, contains('${item.key}('));
    });
  }
  for (final name in [
    'UnmappedLocal',
    'UnmappedInherited',
    'UnmappedMixin',
    'RequiredArgument',
    'OptionalArgument',
  ]) {
    test('$name retains the empty mapping error', () async {
      await expectLater(
        generateForElement(PhiveGenerator(), reader, name),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('No fields were mapped for $name'),
          ),
        ),
      );
    });
  }
  test(
    'empty positional class hooks retain their lifecycle and metadata',
    () async {
      final output = await generateForElement(
        PhiveGenerator(),
        reader,
        'HookedEmptyPositional',
      );
      expect(output, contains('runPreWrite(const [PassThrough()], ctx_obj)'));
      expect(output, contains('runPostRead(const [PassThrough()], ctx_obj)'));
      expect(output, contains('createMetadataHeader('));
      expect(output, isNot(contains('final write_obj')));
      expect(output, isNot(contains('final Map<int, dynamic> values')));
    },
  );
}
