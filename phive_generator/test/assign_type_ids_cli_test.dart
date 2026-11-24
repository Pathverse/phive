import 'dart:convert';
import 'dart:io';

import 'package:phive_generator/src/source_scan.dart';
import 'package:test/test.dart';

/// Runs the CLI against [root] and returns the process result.
Future<ProcessResult> _run(Directory root, List<String> extra) {
  return Process.run(Platform.resolvedExecutable, [
    '--packages=.dart_tool/package_config.json',
    'bin/assign_type_ids.dart',
    '--root',
    root.path,
    '--dir',
    '${root.path}/lib',
    '--registry',
    '${root.path}/phive_type_registry.json',
    ...extra,
  ]);
}

void _write(Directory root, String relative, String content) {
  File('${root.path}/$relative')
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}

Map<String, dynamic> _registry(Directory root) =>
    jsonDecode(File('${root.path}/phive_type_registry.json').readAsStringSync())
        as Map<String, dynamic>;

const _bands = '''
{
  "format": 2,
  "bands": {
    "api/v0": {"start": 10000, "end": 10999, "paths": ["lib/v0/**"]},
    "api/v1": {"start": 11000, "end": 11999, "paths": ["lib/v1/**"]}
  },
  "types": {},
  "retiredTypeIds": {}
}
''';

const _choice = '''
@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
class Choice {
  final String id;
  final String? label;
  const Choice({required this.id, this.label});
}
''';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('phive-bands-');
    _write(root, 'phive_type_registry.json', _bands);
    _write(root, 'lib/v0/choice.dart', _choice);
    _write(root, 'lib/v1/choice.dart', _choice);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('same-named classes in two bands get distinct banded IDs', () async {
    final result = await _run(root, []);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    final types = _registry(root)['types'] as Map<String, dynamic>;
    expect(types['api/v0/Choice']['typeId'], 10000);
    expect(types['api/v1/Choice']['typeId'], 11000);
    expect(types['api/v0/Choice']['layout'], 'tolerant');
    expect(types['api/v0/Choice']['fields'], {'id': 0, 'label': 1});
  });

  test('default root and paths resolve bands from the package directory', () async {
    final generatorDir = Directory.current.absolute.path;
    final result = await Process.run(
      Platform.resolvedExecutable,
      [
        '--packages=$generatorDir/.dart_tool/package_config.json',
        '$generatorDir/bin/assign_type_ids.dart',
      ],
      workingDirectory: root.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('(band api/v0)'));
    expect(
      (_registry(root)['types'] as Map).keys,
      containsAll(['api/v0/Choice', 'api/v1/Choice']),
    );
  });

  test('dry run prints each class band and leaves the file alone', () async {
    final result = await _run(root, ['--dry-run']);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('api/v0/Choice → typeId 10000 (band api/v0)'));
    expect(result.stdout, contains('api/v1/Choice → typeId 11000 (band api/v1)'));
    expect(_registry(root)['types'], isEmpty);
  });

  test('a rerun without source changes leaves the registry unchanged', () async {
    await _run(root, []);
    final before = File('${root.path}/phive_type_registry.json').readAsStringSync();
    final result = await _run(root, []);
    expect(result.stdout, contains('Registry unchanged.'));
    expect(
      File('${root.path}/phive_type_registry.json').readAsStringSync(),
      before,
    );
  });

  test('a removed class is retired and its ID is not reused', () async {
    _write(root, 'lib/v0/extra.dart', '''
@PHiveAutoType(autoFields: true)
class Extra { final int n; const Extra(this.n); }
''');
    await _run(root, []);
    File('${root.path}/lib/v0/extra.dart').deleteSync();
    _write(root, 'lib/v0/later.dart', '''
@PHiveAutoType(autoFields: true)
class Later { final int n; const Later(this.n); }
''');

    final result = await _run(root, []);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('api/v0/Extra retired'));
    final registry = _registry(root);
    expect(registry['retiredTypeIds']['10001']['key'], 'api/v0/Extra');
    expect(registry['types']['api/v0/Later']['typeId'], 10002);
  });

  test('--band restricts assignment to one band', () async {
    final result = await _run(root, ['--band', 'api/v1']);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final types = _registry(root)['types'] as Map<String, dynamic>;
    expect(types.keys, ['api/v1/Choice']);
  });

  test('a positional shape change fails until it is re-identified', () async {
    _write(root, 'lib/v0/card.dart', '''
@PHiveAutoType(autoFields: true)
class Card { final String id; const Card(this.id); }
''');
    await _run(root, []);
    _write(root, 'lib/v0/card.dart', '''
@PHiveAutoType(autoFields: true)
class Card { final String id; final int n; const Card(this.id, this.n); }
''');

    final refused = await _run(root, []);
    expect(refused.exitCode, isNot(0));
    expect(refused.stderr, contains('api/v0/Card'));
    expect(refused.stderr, contains('--reidentify'));

    final accepted = await _run(root, ['--reidentify', 'api/v0/Card']);
    expect(accepted.exitCode, 0, reason: accepted.stderr.toString());
    final registry = _registry(root);
    expect(registry['types']['api/v0/Card']['fields'], {'id': 0, 'n': 1});
    expect(
      (registry['retiredTypeIds'] as Map).values.map((it) => it['key']),
      contains(startsWith('api/v0/Card')),
    );
  });

  test('a new hooked tolerant class is born without a snapshot', () async {
    _write(root, 'lib/v0/note.dart', '''
@PHiveAutoType(autoFields: true, hooks: [Ttl()], classHooks: [TolerantLayout()])
class Note { final String id; const Note(this.id); }
''');
    final result = await _run(root, []);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final note = _registry(root)['types']['api/v0/Note'] as Map;
    expect(note.containsKey('positionalFields'), isFalse);
  });

  test('an overlapping band declaration is reported', () async {
    _write(root, 'phive_type_registry.json', '''
{"format": 2, "bands": {
  "a": {"start": 1, "end": 10, "paths": ["lib/v0/**"]},
  "b": {"start": 5, "end": 20, "paths": ["lib/v1/**"]}}}
''');
    final result = await _run(root, []);
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('overlap'));
  });

  group('scanner', () {
    test('records tolerance, other hooks and explicit indexes', () {
      _write(root, 'lib/v0/model.dart', '''
@PHiveAutoType(autoFields: true, hooks: [Ttl(1)], classHooks: [const TolerantLayout()])
class Model {
  @PHiveField(5)
  final String a;
  final String b;
  @PHiveField(kIndex)
  final String c;
  const Model(this.a, this.b, this.c);
}
''');
      final scanned = scanAutoTypes(
        Directory('${root.path}/lib/v0'),
        root: root,
      ).firstWhere((it) => it.className == 'Model');

      expect(scanned.path, 'lib/v0/model.dart');
      expect(scanned.tolerant, isTrue);
      expect(scanned.hasOtherHooks, isTrue);
      expect(scanned.fields, ['a', 'b', 'c']);
      expect(scanned.explicitIndexes, {'a': 5});
      expect(scanned.unresolvedIndexes, ['c']);
    });

    test('positional order matches generator index inference', () {
      const scanned = ScannedAutoType(
        className: 'M',
        path: 'lib/m.dart',
        tolerant: false,
        hasOtherHooks: false,
        fields: ['a', 'b', 'c'],
        explicitIndexes: {'c': 0},
        unresolvedIndexes: [],
      );
      expect(scanned.positionalOrder, ['c', 'a', 'b']);
    });
  });
}
