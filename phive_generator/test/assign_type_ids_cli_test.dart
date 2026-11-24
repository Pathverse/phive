import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:phive_generator/src/type_registry.dart';
import 'package:phive_generator/src/tombstone_emitter.dart';

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
    ..writeAsStringSync(
      relative.endsWith('.dart')
          ? "import 'package:phive/phive.dart';\n$content\n"
                'class Ttl extends PHiveHook { const Ttl([int? value]); }\n'
                'const kIndex = 7;\n'
          : content,
    );
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

  setUp(() async {
    root = Directory.systemTemp.createTempSync('phive-bands-');
    _write(root, 'pubspec.yaml', '''
name: scan_fixture
environment:
  sdk: ^3.11.0
dependencies:
  phive:
    path: ${Directory('../phive').absolute.path}
dev_dependencies:
  build_runner: ^2.12.1
  phive_generator:
    path: ${Directory.current.path}
dependency_overrides:
  phive:
    path: ${Directory('../phive').absolute.path}
''');
    final result = await Process.run('flutter', [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: root.path);
    expect(result.exitCode, 0, reason: result.stderr.toString());
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

  test(
    'default root and paths resolve bands from the package directory',
    () async {
      final generatorDir = Directory.current.absolute.path;
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=$generatorDir/.dart_tool/package_config.json',
        '$generatorDir/bin/assign_type_ids.dart',
      ], workingDirectory: root.path);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('(band api/v0)'));
      expect(
        (_registry(root)['types'] as Map).keys,
        containsAll(['api/v0/Choice', 'api/v1/Choice']),
      );
    },
  );

  test('dry run prints each class band and leaves the file alone', () async {
    final result = await _run(root, ['--dry-run']);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(
      result.stdout,
      contains('api/v0/Choice → typeId 10000 (band api/v0)'),
    );
    expect(
      result.stdout,
      contains('api/v1/Choice → typeId 11000 (band api/v1)'),
    );
    expect(_registry(root)['types'], isEmpty);
  });

  test(
    'a rerun without source changes leaves the registry unchanged',
    () async {
      await _run(root, []);
      final before = File(
        '${root.path}/phive_type_registry.json',
      ).readAsStringSync();
      final result = await _run(root, []);
      expect(result.stdout, contains('Registry unchanged.'));
      expect(
        File('${root.path}/phive_type_registry.json').readAsStringSync(),
        before,
      );
    },
  );

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

  test(
    'first run without options starts at zero and declares no bands',
    () async {
      File('${root.path}/phive_type_registry.json').deleteSync();
      Directory('${root.path}/lib/v1').deleteSync(recursive: true);
      final result = await _run(root, []);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(_registry(root)['bands'], isEmpty);
      expect(_registry(root)['types']['Choice']['typeId'], 0);
    },
  );

  test('inherited fields are accepted by the following build', () async {
    _write(
      root,
      'lib/v0/inherited.dart',
      "import 'package:hive_ce/hive.dart';\n"
          "part 'inherited.g.dart';\n"
          'class Base { @PHiveField(0) final String id; const Base(this.id); }\n'
          '@PHiveAutoType(classHooks: [TolerantLayout()])\n'
          'class Inherited extends Base { @PHiveField(1) final String title; const Inherited(super.id, this.title); }',
    );
    final assigned = await _run(root, []);
    expect(assigned.exitCode, 0, reason: assigned.stderr.toString());
    expect(_registry(root)['types']['api/v0/Inherited']['fields'], {
      'id': 0,
      'title': 1,
    });
    final built = await Process.run('dart', [
      'run',
      'build_runner',
      'build',
    ], workingDirectory: root.path);
    expect(built.exitCode, 0, reason: '${built.stdout} ${built.stderr}');
  });
  test('enum in a band retains removed case tags', () async {
    _write(
      root,
      'lib/v0/color.dart',
      '@PHiveAutoType() enum Color { red, blue }',
    );
    var result = await _run(root, []);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    var shape = _registry(root)['types']['api/v0/Color'];
    expect(shape['layout'], 'enum');
    expect(shape['fields'], {'red': 0, 'blue': 1});
    _write(
      root,
      'lib/v0/color.dart',
      '@PHiveAutoType() enum Color { red, green }',
    );
    result = await _run(root, []);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    shape = _registry(root)['types']['api/v0/Color'];
    expect(shape['retiredFields'], {'blue': 1});
    expect(shape['fields'], {'red': 0, 'green': 2});
  });

  test(
    'explicit retirements are applied before assignment and are idempotent',
    () async {
      final result = await _run(root, [
        '--retire-id',
        '0-2',
        '--retire-id',
        '7',
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('x 0-2 retired (explicit)'));
      expect(result.stdout, contains('x 7 retired (explicit)'));
      final retired = _registry(root)['retiredTypeIds'];
      for (final id in [0, 1, 2, 7]) {
        expect(retired['$id']['key'], 'legacy@$id');
      }
      final again = await _run(root, ['--retire-id', '0-2']);
      expect(again.exitCode, 0);
      expect(again.stdout, isNot(contains('retired (explicit)')));
    },
  );

  test('active ID retirement writes neither output', () async {
    await _run(root, []);
    final file = File('${root.path}/phive_type_registry.json');
    final before = file.readAsStringSync();
    final result = await _run(root, [
      '--retire-id',
      '10000',
      '--tombstones',
      '${root.path}/out.dart',
    ]);
    expect(result.exitCode, 1);
    expect(
      result.stderr,
      contains(
        'Cannot retire typeId 10000: it is assigned to "api/v0/Choice".',
      ),
    );
    expect(file.readAsStringSync(), before);
    expect(File('${root.path}/out.dart').existsSync(), isFalse);
  });

  for (final item in {
    '9-3': 'range start exceeds end',
    'a-3': 'expected N or N-M',
    '70000': 'typeId must be in 0..65439',
  }.entries) {
    test('rejects retirement ${item.key} before writing', () async {
      final file = File('${root.path}/phive_type_registry.json');
      final before = file.readAsStringSync();
      final result = await _run(root, [
        '--retire-id',
        item.key,
        '--tombstones',
        '${root.path}/out.dart',
      ]);
      expect(result.exitCode, 1);
      expect(result.stderr, contains('--retire-id ${item.key}: ${item.value}'));
      expect(file.readAsStringSync(), before);
      expect(File('${root.path}/out.dart').existsSync(), isFalse);
    });
  }

  test(
    'tombstones compile, register without warnings, and avoid rewriting',
    () async {
      final output = '${root.path}/lib/tombstones.dart';
      var result = await _run(root, [
        '--retire-id',
        '3-5',
        '--tombstones',
        output,
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final content = File(output).readAsStringSync();
      expect(
        content,
        emitTombstoneFile(
          TypeIdRegistry.fromJson(
            File('${root.path}/phive_type_registry.json').readAsStringSync(),
          ),
        ),
      );
      final analyzed = await Process.run('dart', [
        'analyze',
        output,
      ], workingDirectory: root.path);
      expect(
        analyzed.exitCode,
        0,
        reason: '${analyzed.stdout} ${analyzed.stderr}',
      );
      result = await _run(root, ['--tombstones', output]);
      expect(result.stdout, contains('Tombstones unchanged.'));
      _write(root, 'check.dart', """
import 'dart:async';
import 'lib/tombstones.dart';
void main() {
  final lines = <String>[];
  runZoned(() { registerPHiveTombstones(); registerPHiveTombstones(); },
      zoneSpecification: ZoneSpecification(print: (self, parent, zone, message) => lines.add(message)));
  if (lines.any((line) => line.contains('already a TypeAdapter for this type'))) {
    throw StateError(lines.join('\\n'));
  }
}
""");
      final checked = await Process.run('dart', [
        'run',
        'check.dart',
      ], workingDirectory: root.path);
      expect(
        checked.exitCode,
        0,
        reason: '${checked.stdout} ${checked.stderr}',
      );
      final dryOutput = '${root.path}/dry.dart';
      result = await _run(root, ['--tombstones', dryOutput, '--dry-run']);
      expect(
        result.stdout,
        contains('[dry-run] Tombstones NOT written to "$dryOutput".'),
      );
      expect(File(dryOutput).existsSync(), isFalse);
    },
  );
}
