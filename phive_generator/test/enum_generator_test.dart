import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:phive_generator/src/auto_type_generator.dart';
import 'package:phive_generator/src/phive_generator.dart';
import 'package:phive_generator/src/type_registry.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

TypeIdRegistry registry(
  String name,
  Map<String, int> tags, {
  bool shape = true,
}) => TypeIdRegistry.fromJson(
  jsonEncode({
    'format': 2,
    'types': {
      name: {
        'typeId': 80,
        if (shape) ...{
          'layout': 'enum',
          'fields': tags,
          'retiredFields': {'removed': 2},
        },
      },
    },
  }),
);

Future<void> main() async {
  initializeBuildLogTracking();
  final reader = await initializeLibraryReaderForDirectory(
    'test/src',
    'enum_model.dart',
  );
  Future<String> generate(
    String name,
    Map<String, int> tags, {
    bool shape = true,
  }) => generateForElement(
    PhiveAutoTypeGenerator(testRegistry: registry(name, tags, shape: shape)),
    reader,
    name,
  );
  void golden(String value, String name) {
    final file = File('test/goldens/$name.golden');
    if (Platform.environment['UPDATE_GOLDENS'] == '1') {
      file.writeAsStringSync(value);
    }
    expect(value, file.readAsStringSync());
  }

  test(
    'auto enum golden excludes retired tags and has canonical fingerprint',
    () async {
      final output = await generate('AutoEnum', {'survey': 0, 'quiz': 1});
      golden(output, 'auto_enum');
      expect(output, isNot(contains('case 2:')));
      expect(output, isNot(contains('castStored')));
      expect(
        output,
        contains(
          sha256.convert(utf8.encode('80|enum|0:survey,1:quiz')).toString(),
        ),
      );
    },
  );
  test('explicit enum golden supports tags larger than a byte', () async {
    golden(
      await generateForElement(PhiveGenerator(), reader, 'ExplicitEnum'),
      'explicit_enum',
    );
  });
  for (final item in {
    'MissingEnum': 'missing on a',
    'DuplicateEnum': 'Duplicate PHiveField tag 1 on cases a and b',
  }.entries) {
    test(item.key, () async {
      await expectLater(
        generateForElement(PhiveGenerator(), reader, item.key),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains(item.value),
          ),
        ),
      );
    });
  }
  test('hooks are rejected', () async {
    await expectLater(
      generate('HookedEnum', {'a': 0}),
      throwsA(
        isA<InvalidGenerationSourceError>().having(
          (e) => e.message,
          'message',
          contains(
            'Enum HookedEnum cannot declare hooks; enums are stored as a single tag.',
          ),
        ),
      ),
    );
  });
  test('missing shape and stale cases are rejected', () async {
    for (final shape in [true, false]) {
      await expectLater(
        generate('AutoEnum', {'survey': 0}, shape: shape),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    }
  });
}
