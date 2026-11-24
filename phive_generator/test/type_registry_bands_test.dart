import 'dart:convert';

import 'package:phive_generator/src/type_registry.dart';
import 'package:test/test.dart';

RegistryBand _band(String name, int start, int end, [List<String>? paths]) =>
    RegistryBand(
      name: name,
      start: start,
      end: end,
      paths: paths ?? ['lib/$name/**'],
    );

TypeIdRegistry _banded() => TypeIdRegistry(
  {},
  bands: {'a': _band('a', 10000, 10999), 'b': _band('b', 11000, 11999)},
);

void main() {
  group('flat format compatibility', () {
    test('an existing flat registry re-emits byte-identically', () {
      // A registry as written by phive_generator 0.8.x.
      const source =
          '{\n'
          '  "AutoNote": 10,\n'
          '  "AutoMetadata": 12,\n'
          '  "AutoNamingCard": 22,\n'
          '  "AutoCustomNamingCard": 24\n'
          '}';
      final registry = TypeIdRegistry.fromJson(source);

      expect(registry.isVersioned, isFalse);
      expect(registry.toJson().trim(), source.trim());
    });

    test('assigning into a flat registry keeps the flat format', () {
      final registry = TypeIdRegistry.fromJson('{"A":0}').assign('B');
      expect(jsonDecode(registry.toJson()), {'A': 0, 'B': 1});
    });
  });

  group('versioned format', () {
    test('round-trips bands, types, shapes and retirements', () {
      var registry = _banded().assign('Lesson', band: 'a');
      registry = registry.recordShape('a/Lesson', [
        'id',
        'title',
      ], tolerant: true);
      registry = registry.assign('Old', band: 'a').retire('a/Old');

      final reloaded = TypeIdRegistry.fromJson(registry.toJson());

      expect(reloaded.toJson(), registry.toJson());
      expect(reloaded.lookupTypeId('a/Lesson'), 10000);
      expect(reloaded.retiredTypeIds, {10001: 'a/Old'});
      expect(reloaded.shapeOf('a/Lesson')!.layout, RegistryLayout.tolerant);
      expect(reloaded.shapeOf('a/Lesson')!.fields, {'id': 0, 'title': 1});
      expect(jsonDecode(registry.toJson())['format'], 2);
    });

    test('guarded format preserves active, historical and empty baselines', () {
      final original = _banded()
          .assign('Card', band: 'a')
          .assign('Empty', band: 'a')
          .withShape(
            'a/Card',
            RegistryShape(
              layout: RegistryLayout.tolerant,
              fields: {'x': 2},
              retiredFields: {'legacy': 0, 'known': 1},
              fieldTypes: {2: 'String?', 1: 'int'},
            ),
          )
          .withShape(
            'a/Empty',
            RegistryShape(
              layout: RegistryLayout.tolerant,
              fields: {},
              fieldTypes: {},
            ),
          );
      final encoded = original.toJson();
      expect(jsonDecode(encoded)['format'], 3);
      final restored = TypeIdRegistry.fromJson(encoded);
      expect(restored.toJson(), encoded);
      expect(restored.shapeOf('a/Card')!.fieldTypes, {1: 'int', 2: 'String?'});
      expect(restored.shapeOf('a/Empty')!.fieldTypes, isEmpty);
      for (final invalid in [
        null,
        [],
        {'1': 'int'},
        {'2': ''},
        {'2': 'String?', '8': 'int'},
      ]) {
        final data = jsonDecode(encoded);
        data['types']['a/Card']['fieldTypes'] = invalid;
        expect(
          () => TypeIdRegistry.fromJson(jsonEncode(data)),
          throwsFormatException,
        );
      }
      expect(
        () => TypeIdRegistry.fromJson(
          encoded.replaceFirst('"format": 3', '"format": 2'),
        ),
        throwsFormatException,
      );
    });
    test(
      'known returning tags enforce their baseline and unknown retired tags enroll on return',
      () {
        var registry = _banded()
            .assign('Card', band: 'a')
            .withShape(
              'a/Card',
              RegistryShape(
                layout: RegistryLayout.tolerant,
                fields: {'text': 0},
                retiredFields: {'legacy': 1},
              ),
            );
        TypeIdRegistry assign(Map<String, String> types) =>
            registry.recordShape(
              'a/Card',
              types.keys.toList(),
              tolerant: true,
              resolvedTypes: types,
            );
        registry = assign({'text': 'String'});
        registry = assign({'extra': 'int', 'legacy': 'bool'});
        expect(registry.shapeOf('a/Card')!.fields, {'extra': 2, 'legacy': 1});
        registry = TypeIdRegistry.fromJson(registry.toJson());
        expect(
          () => assign({'text': 'int'}),
          throwsA(isA<RegistryShapeChangeError>()),
        );
        registry = assign({'text': 'String', 'legacy': 'bool', 'extra': 'int'});
        expect(registry.lookupTypeId('a/Card'), 10000);
        expect(registry.shapeOf('a/Card')!.fields, {
          'text': 0,
          'extra': 2,
          'legacy': 1,
        });
      },
    );
    test('rejects an unsupported format number', () {
      expect(
        () => TypeIdRegistry.fromJson('{"format": 4}'),
        throwsFormatException,
      );
    });

    test('rejects an identifier outside its band', () {
      final json = jsonEncode({
        'format': 2,
        'bands': {
          'a': {
            'start': 10000,
            'end': 10999,
            'paths': ['lib/a/**'],
          },
        },
        'types': {
          'a/X': {'typeId': 5},
        },
      });
      expect(() => TypeIdRegistry.fromJson(json), throwsFormatException);
    });
  });

  group('bands', () {
    test('allocation inside a band ignores other bands', () {
      var registry = _banded();
      for (final name in ['A0', 'A1', 'A2', 'A3', 'A4']) {
        registry = registry.assign(name, band: 'a');
      }
      registry = registry.assign('B0', band: 'b').assign('B1', band: 'b');

      expect(registry.lookupTypeId('a/A4'), 10004);
      expect(registry.assign('A5', band: 'a').lookupTypeId('a/A5'), 10005);
    });

    test('band exhaustion fails naming the band', () {
      var registry = TypeIdRegistry({}, bands: {'s': _band('s', 10, 11)});
      registry = registry.assign('X', band: 's').assign('Y', band: 's');

      expect(
        () => registry.assign('Z', band: 's'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('"s"'),
          ),
        ),
      );
    });

    test('exhaustion counts retired identifiers as taken', () {
      var registry = TypeIdRegistry({}, bands: {'s': _band('s', 10, 11)});
      registry = registry
          .assign('X', band: 's')
          .assign('Y', band: 's')
          .retire('s/X');

      expect(() => registry.assign('Z', band: 's'), throwsStateError);
    });

    test('overlapping bands are rejected naming both', () {
      expect(
        () => TypeIdRegistry(
          {},
          bands: {'a': _band('a', 10000, 10999), 'b': _band('b', 10500, 11499)},
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('"a"'), contains('"b"')),
          ),
        ),
      );
    });

    test('a path matched by two bands is rejected', () {
      final registry = TypeIdRegistry(
        {},
        bands: {
          'a': _band('a', 10000, 10999, ['lib/**']),
          'b': _band('b', 11000, 11999, ['lib/x/**']),
        },
      );
      expect(() => registry.bandForPath('lib/x/m.dart'), throwsStateError);
      expect(registry.bandForPath('lib/y/m.dart')!.name, 'a');
      expect(registry.bandForPath('test/m.dart'), isNull);
    });

    test('single-star globs do not cross directories', () {
      final band = _band('a', 0, 9, ['lib/*.dart']);
      expect(band.matchesPath('lib/m.dart'), isTrue);
      expect(band.matchesPath('lib/sub/m.dart'), isFalse);
    });

    test('the same simple name in two bands gets distinct identifiers', () {
      final registry = _banded()
          .assign('Choice', band: 'a')
          .assign('Choice', band: 'b');

      expect(registry.lookupTypeId('a/Choice'), 10000);
      expect(registry.lookupTypeId('b/Choice'), 11000);
    });

    test('unbanded allocation skips past declared bands', () {
      final registry = TypeIdRegistry(
        {'Low': 9999},
        bands: {'a': _band('a', 10000, 10999)},
      );
      expect(registry.nextAvailableId(), 11000);
    });
  });

  group('retirement', () {
    test('a retired identifier is never reassigned', () {
      final registry = _banded()
          .assign('Kept', band: 'a')
          .assign('Gone', band: 'a')
          .retire('a/Gone')
          .assign('Fresh', band: 'a');

      expect(registry.retiredTypeIds, {10001: 'a/Gone'});
      expect(registry.lookupTypeId('a/Fresh'), 10002);
    });

    test('restoring the same key reactivates its identifier', () {
      final registry = _banded()
          .assign('Gone', band: 'a')
          .assign('Other', band: 'a')
          .retire('a/Gone')
          .assign('Gone', band: 'a');

      expect(registry.lookupTypeId('a/Gone'), 10000);
      expect(registry.retiredTypeIds, isEmpty);
    });
  });

  group('positional shapes', () {
    TypeIdRegistry withPositional() => _banded()
        .assign('Card', band: 'a')
        .recordShape('a/Card', ['id', 'body'], tolerant: false);

    test('an unchanged shape is accepted', () {
      final registry = withPositional();
      expect(
        registry.recordShape('a/Card', ['id', 'body'], tolerant: false),
        same(registry),
      );
    });

    test('a shape change is refused naming the type and fields', () {
      expect(
        () => withPositional().recordShape('a/Card', [
          'id',
          'body',
          'extra',
        ], tolerant: false),
        throwsA(
          isA<RegistryShapeChangeError>()
              .having((e) => e.key, 'key', 'a/Card')
              .having((e) => e.message, 'message', contains('extra')),
        ),
      );
    });

    test('explicit re-identification retires and reallocates in the band', () {
      final registry = withPositional().recordShape(
        'a/Card',
        ['id', 'body', 'extra'],
        tolerant: false,
        reidentify: true,
      );

      expect(registry.lookupTypeId('a/Card'), 10001);
      expect(registry.retiredTypeIds.keys, contains(10000));
      expect(registry.shapeOf('a/Card')!.orderedFields, [
        'id',
        'body',
        'extra',
      ]);
      // The retired identifier survives a reload and is still not reusable.
      final reloaded = TypeIdRegistry.fromJson(registry.toJson());
      expect(reloaded.assign('Next', band: 'a').lookupTypeId('a/Next'), 10002);
    });
  });

  group('tolerant shapes', () {
    TypeIdRegistry withTolerant() => _banded()
        .assign('Lesson', band: 'a')
        .recordShape('a/Lesson', ['id', 'title'], tolerant: true);

    test('born-tolerant types get tags without a positional snapshot', () {
      final shape = withTolerant().shapeOf('a/Lesson')!;
      expect(shape.fields, {'id': 0, 'title': 1});
      expect(shape.positionalFields, isNull);
    });

    test('adding a field keeps the identifier and uses an unused tag', () {
      final registry = withTolerant().recordShape('a/Lesson', [
        'id',
        'title',
        'image',
      ], tolerant: true);
      expect(registry.lookupTypeId('a/Lesson'), 10000);
      expect(registry.shapeOf('a/Lesson')!.fields['image'], 2);
    });

    test('reordering fields keeps their tags', () {
      final registry = withTolerant().recordShape('a/Lesson', [
        'title',
        'id',
      ], tolerant: true);
      expect(registry.shapeOf('a/Lesson')!.fields, {'id': 0, 'title': 1});
    });

    test('a removed field tag is retired and not reused', () {
      final registry = withTolerant()
          .recordShape('a/Lesson', ['id'], tolerant: true)
          .recordShape('a/Lesson', ['id', 'summary'], tolerant: true);

      final shape = registry.shapeOf('a/Lesson')!;
      expect(shape.retiredFields, {'title': 1});
      expect(shape.fields['summary'], 2);
    });

    test('a field that returns gets its original tag back', () {
      final registry = withTolerant()
          .recordShape('a/Lesson', ['id'], tolerant: true)
          .recordShape('a/Lesson', ['id', 'title'], tolerant: true);

      expect(registry.shapeOf('a/Lesson')!.fields['title'], 1);
      expect(registry.shapeOf('a/Lesson')!.retiredFields, isEmpty);
    });

    test('explicit indexes are used as tags and may not retag', () {
      final registry = _banded()
          .assign('Lesson', band: 'a')
          .recordShape(
            'a/Lesson',
            ['id', 'title'],
            tolerant: true,
            explicitTags: {'title': 7},
          );
      expect(registry.shapeOf('a/Lesson')!.fields, {'title': 7, 'id': 8});

      expect(
        () => registry.recordShape(
          'a/Lesson',
          ['id', 'title'],
          tolerant: true,
          explicitTags: {'title': 3},
        ),
        throwsA(isA<RegistryShapeChangeError>()),
      );
    });

    test('opting in a hooked positional type records its order', () {
      final registry = _banded()
          .assign('Card', band: 'a')
          .recordShape('a/Card', ['id', 'body'], tolerant: false)
          .recordShape(
            'a/Card',
            ['id', 'body'],
            tolerant: true,
            hadOtherHooks: true,
          );

      final shape = registry.shapeOf('a/Card')!;
      expect(registry.lookupTypeId('a/Card'), 10000);
      expect(shape.layout, RegistryLayout.tolerant);
      expect(shape.positionalFields, ['id', 'body']);
      expect(shape.fields, {'id': 0, 'body': 1});
    });

    test('opting in a hookless positional type records no snapshot', () {
      final registry = _banded()
          .assign('Card', band: 'a')
          .recordShape('a/Card', ['id', 'body'], tolerant: false)
          .recordShape('a/Card', ['id', 'body'], tolerant: true);

      expect(registry.shapeOf('a/Card')!.positionalFields, isNull);
    });

    test('opting in and changing fields in one step is refused', () {
      expect(
        () => _banded()
            .assign('Card', band: 'a')
            .recordShape('a/Card', ['id', 'body'], tolerant: false)
            .recordShape(
              'a/Card',
              ['id', 'body', 'extra'],
              tolerant: true,
              hadOtherHooks: true,
            ),
        throwsA(isA<RegistryShapeChangeError>()),
      );
    });

    test('an already registered type without a shape snapshots its order', () {
      final registry = TypeIdRegistry.fromJson('{"Card":3}').recordShape(
        'Card',
        ['id', 'body'],
        tolerant: true,
        hadOtherHooks: true,
        previouslyRegistered: true,
      );
      expect(registry.shapeOf('Card')!.positionalFields, ['id', 'body']);
      expect(registry.isVersioned, isTrue);
    });

    test('a type registered in the same run gets no snapshot', () {
      final registry = TypeIdRegistry.empty()
          .assign('Card')
          .recordShape(
            'Card',
            ['id', 'body'],
            tolerant: true,
            hadOtherHooks: true,
          );
      expect(registry.shapeOf('Card')!.positionalFields, isNull);
    });
  });
  group('enum shapes', () {
    test('tags survive reorder, removal and re-add and serialize as enum', () {
      var registry = _banded()
          .assign('E', band: 'a')
          .recordShape('a/E', ['a', 'b'], tolerant: false, enumeration: true);
      registry = registry.recordShape(
        'a/E',
        ['b', 'a'],
        tolerant: false,
        enumeration: true,
      );
      expect(registry.shapeOf('a/E')!.fields, {'a': 0, 'b': 1});
      registry = registry.recordShape(
        'a/E',
        ['a', 'c'],
        tolerant: false,
        enumeration: true,
      );
      expect(registry.shapeOf('a/E')!.retiredFields, {'b': 1});
      expect(registry.shapeOf('a/E')!.fields['c'], 2);
      registry = registry.recordShape(
        'a/E',
        ['b', 'c', 'a'],
        tolerant: false,
        enumeration: true,
      );
      expect(registry.shapeOf('a/E')!.fields['b'], 1);
      expect(
        TypeIdRegistry.fromJson(registry.toJson()).shapeOf('a/E')!.layout,
        RegistryLayout.enumeration,
      );
      expect(registry.toJson(), contains('"layout": "enum"'));
      expect(registry.shapeOf('a/E')!.positionalFields, isNull);
    });
    test(
      'explicit tags cannot retag and model switches require reidentification',
      () {
        final registry = _banded()
            .assign('E', band: 'a')
            .recordShape(
              'a/E',
              ['a'],
              tolerant: false,
              enumeration: true,
              explicitTags: {'a': 42},
            );
        expect(registry.shapeOf('a/E')!.fields['a'], 42);
        expect(
          () => registry.recordShape(
            'a/E',
            ['a'],
            tolerant: false,
            enumeration: true,
            explicitTags: {'a': 43},
          ),
          throwsStateError,
        );
        expect(
          () => registry.recordShape('a/E', ['a'], tolerant: false),
          throwsStateError,
        );
        final changed = registry.recordShape(
          'a/E',
          ['a'],
          tolerant: false,
          reidentify: true,
        );
        expect(
          changed.lookupTypeId('a/E'),
          isNot(registry.lookupTypeId('a/E')),
        );
        expect(
          () => changed.recordShape(
            'a/E',
            ['a'],
            tolerant: false,
            enumeration: true,
          ),
          throwsStateError,
        );
      },
    );
  });
  test('explicit retirements reserve ranges before allocation', () {
    final registry = TypeIdRegistry.empty().retireIds(Iterable.generate(200));
    expect(registry.retiredTypeIds.length, 200);
    expect(registry.assign('A').lookupTypeId('A'), 200);
    expect(registry.retireIds([7]).toJson(), registry.toJson());
    expect(() => registry.assign('A').retireIds([200]), throwsStateError);
    expect(() => registry.retireIds([65440]), throwsStateError);
  });
}
