import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:phive_generator/src/type_registry.dart';

/// Unit tests for [TypeIdRegistry] covering parse, lookup, assign, and serialise.
void main() {
  test('registry retains single-byte and extended Hive CE IDs', () {
    final registry = TypeIdRegistry.fromJson(
      '{"A":0,"B":223,"C":224,"D":65439}',
    );
    expect(jsonDecode(registry.toJson()), {
      'A': 0,
      'B': 223,
      'C': 224,
      'D': 65439,
    });
  });

  for (final json in ['{"A":5,"B":5}', '{"A":-1}', '{"A":65440}']) {
    test('registry rejects invalid assignments in $json', () {
      expect(() => TypeIdRegistry.fromJson(json), throwsFormatException);
    });
  }

  for (final floor in [-1, 65440]) {
    test('registry rejects allocation starting at $floor', () {
      expect(
        () => TypeIdRegistry.empty().assign('A', startAt: floor),
        throwsStateError,
      );
    });
  }

  test('registry rejects allocation after the last type ID', () {
    final registry = TypeIdRegistry.fromJson('{"A":65439}');
    expect(() => registry.assign('B'), throwsStateError);
  });

  test(
    'CLI assigns IDs only to annotated classes with nested arguments',
    () async {
      final dir = Directory.systemTemp.createTempSync('phive-type-ids-');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: nested_fixture
environment:
  sdk: ^3.11.0
dependencies:
  phive:
    path: ${Directory('../phive').absolute.path}
''');
      final get = await Process.run('flutter', [
        'pub',
        'get',
        '--offline',
      ], workingDirectory: dir.path);
      expect(get.exitCode, 0, reason: get.stderr.toString());
      File('${dir.path}/models.dart').writeAsStringSync('''
import 'package:phive/phive.dart';
class Hook extends PHiveHook { const Hook(Object value); }
class Other { const Other(Object value); }
// @PHiveAutoType() class LineComment {}
/* @PHiveAutoType() class BlockComment {} */
const text = r'@PHiveAutoType() class StringLiteral {}';
class Unannotated {}
@PHiveAutoType(autoFields: true, hooks: [Hook({'brace': [1, 2], 'text': ') class Wrong'})])
@Other({'key': 1})
class Model { final String id; const Model(this.id); }
''');
      final registry = File('${dir.path}/registry.json');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=.dart_tool/package_config.json',
        'bin/assign_type_ids.dart',
        '--root',
        dir.path,
        '--dir',
        dir.path,
        '--registry',
        registry.path,
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(jsonDecode(registry.readAsStringSync()), {'Model': 0});
    },
  );

  group('TypeIdRegistry.fromJson', () {
    test('parses an empty object as an empty registry', () {
      final registry = TypeIdRegistry.fromJson('{}');
      expect(registry.isEmpty, isTrue);
    });

    test('parses a populated registry and makes all entries available', () {
      final registry = TypeIdRegistry.fromJson(
        jsonEncode({'Alpha': 0, 'Beta': 7, 'Gamma': 42}),
      );
      expect(registry.lookupTypeId('Alpha'), equals(0));
      expect(registry.lookupTypeId('Beta'), equals(7));
      expect(registry.lookupTypeId('Gamma'), equals(42));
    });

    test('throws FormatException when the source is invalid JSON', () {
      expect(() => TypeIdRegistry.fromJson('not json'), throwsFormatException);
    });

    test('throws FormatException when the root is not a JSON object', () {
      expect(
        () => TypeIdRegistry.fromJson(jsonEncode([1, 2, 3])),
        throwsFormatException,
      );
    });

    test('throws FormatException when a value is not an integer', () {
      expect(
        () => TypeIdRegistry.fromJson(jsonEncode({'Alpha': 'oops'})),
        throwsFormatException,
      );
    });
  });

  group('TypeIdRegistry.lookupTypeId', () {
    test('returns the assigned id for a known class', () {
      final registry = TypeIdRegistry.fromJson(jsonEncode({'MyModel': 5}));
      expect(registry.lookupTypeId('MyModel'), equals(5));
    });

    test('throws StateError for an unknown class', () {
      final registry = TypeIdRegistry.fromJson('{}');
      expect(() => registry.lookupTypeId('Unknown'), throwsStateError);
    });
  });

  group('TypeIdRegistry.contains', () {
    test('returns true for a registered class', () {
      final registry = TypeIdRegistry.fromJson(jsonEncode({'Foo': 1}));
      expect(registry.contains('Foo'), isTrue);
    });

    test('returns false for an unregistered class', () {
      final registry = TypeIdRegistry.fromJson(jsonEncode({'Foo': 1}));
      expect(registry.contains('Bar'), isFalse);
    });
  });

  group('TypeIdRegistry.nextAvailableId', () {
    test('returns 0 for an empty registry', () {
      final registry = TypeIdRegistry.fromJson('{}');
      expect(registry.nextAvailableId(), equals(0));
    });

    test('returns one past the maximum assigned id', () {
      final registry = TypeIdRegistry.fromJson(
        jsonEncode({'A': 0, 'B': 3, 'C': 1}),
      );
      expect(registry.nextAvailableId(), equals(4));
    });

    test('respects an explicit startAt floor when all ids are below it', () {
      final registry = TypeIdRegistry.fromJson(jsonEncode({'A': 0, 'B': 1}));
      expect(registry.nextAvailableId(startAt: 10), equals(10));
    });

    test('startAt is ignored when max assigned id exceeds it', () {
      final registry = TypeIdRegistry.fromJson(jsonEncode({'A': 15, 'B': 16}));
      expect(registry.nextAvailableId(startAt: 5), equals(17));
    });
  });

  group('TypeIdRegistry.assign', () {
    test('adds a new class and returns an updated registry', () {
      final original = TypeIdRegistry.fromJson('{}');
      final updated = original.assign('NewModel');
      expect(updated.contains('NewModel'), isTrue);
      expect(updated.lookupTypeId('NewModel'), equals(0));
    });

    test('original registry is unchanged after assign (immutable)', () {
      final original = TypeIdRegistry.fromJson('{}');
      original.assign('NewModel');
      expect(original.contains('NewModel'), isFalse);
    });

    test('assigns sequential ids to multiple new classes', () {
      var registry = TypeIdRegistry.fromJson('{}');
      registry = registry.assign('Alpha');
      registry = registry.assign('Beta');
      registry = registry.assign('Gamma');
      expect(registry.lookupTypeId('Alpha'), equals(0));
      expect(registry.lookupTypeId('Beta'), equals(1));
      expect(registry.lookupTypeId('Gamma'), equals(2));
    });

    test('preserves existing entries when assigning a new class', () {
      final original = TypeIdRegistry.fromJson(jsonEncode({'Existing': 7}));
      final updated = original.assign('NewModel');
      expect(updated.lookupTypeId('Existing'), equals(7));
      expect(updated.lookupTypeId('NewModel'), equals(8));
    });

    test('throws StateError when the class is already registered', () {
      final registry = TypeIdRegistry.fromJson(jsonEncode({'Dupe': 3}));
      expect(() => registry.assign('Dupe'), throwsStateError);
    });

    test('respects startAt when assigning into an empty registry', () {
      final registry = TypeIdRegistry.fromJson('{}');
      final updated = registry.assign('Model', startAt: 32);
      expect(updated.lookupTypeId('Model'), equals(32));
    });

    test('startAt is ignored when existing ids already exceed it', () {
      final registry = TypeIdRegistry.fromJson(jsonEncode({'Existing': 40}));
      final updated = registry.assign('Model', startAt: 10);
      expect(updated.lookupTypeId('Model'), equals(41));
    });
  });

  group('TypeIdRegistry.assignAll', () {
    test('assigns ids to all unknown class names in order', () {
      var registry = TypeIdRegistry.fromJson(jsonEncode({'Alpha': 0}));
      registry = registry.assignAll(['Beta', 'Gamma']);
      expect(registry.lookupTypeId('Alpha'), equals(0));
      expect(registry.lookupTypeId('Beta'), equals(1));
      expect(registry.lookupTypeId('Gamma'), equals(2));
    });

    test('skips class names that are already registered', () {
      var registry = TypeIdRegistry.fromJson(jsonEncode({'Alpha': 5}));
      registry = registry.assignAll(['Alpha', 'Beta']);
      expect(registry.lookupTypeId('Alpha'), equals(5));
      expect(registry.lookupTypeId('Beta'), equals(6));
    });

    test('returns the same registry when all names are already registered', () {
      final registry = TypeIdRegistry.fromJson(jsonEncode({'A': 1, 'B': 2}));
      final updated = registry.assignAll(['A', 'B']);
      expect(updated.lookupTypeId('A'), equals(1));
      expect(updated.lookupTypeId('B'), equals(2));
    });
  });

  group('TypeIdRegistry.toJson', () {
    test('round-trips an empty registry', () {
      final registry = TypeIdRegistry.fromJson('{}');
      final decoded = jsonDecode(registry.toJson()) as Map<String, dynamic>;
      expect(decoded, isEmpty);
    });

    test('round-trips a populated registry', () {
      final source = {'Alpha': 0, 'Beta': 7};
      final registry = TypeIdRegistry.fromJson(jsonEncode(source));
      final decoded = jsonDecode(registry.toJson()) as Map<String, dynamic>;
      expect(decoded, equals(source));
    });

    test('output is pretty-printed (contains newlines)', () {
      final registry = TypeIdRegistry.fromJson(jsonEncode({'A': 1}));
      expect(registry.toJson(), contains('\n'));
    });
  });

  group('TypeIdRegistry.isEmpty / isNotEmpty', () {
    test('isEmpty is true for an empty registry', () {
      expect(TypeIdRegistry.fromJson('{}').isEmpty, isTrue);
    });

    test('isNotEmpty is true for a populated registry', () {
      expect(TypeIdRegistry.fromJson(jsonEncode({'X': 0})).isNotEmpty, isTrue);
    });
  });
}
