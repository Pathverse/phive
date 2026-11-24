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

  test(
    'band enrollment, D5 rejection and recovery preserve other outputs',
    () async {
      const key = 'api/v0/Choice';
      final registryFile = File('${root.path}/phive_type_registry.json');
      final tombstones = File('${root.path}/tombstones.dart');
      final output = ['--tombstones', tombstones.path];
      Future<void> success(List<String> args) async {
        final result = await _run(root, [...args, ...output]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
      }

      await success([]);
      final legacy = registryFile.readAsStringSync();
      await success(['--band', 'api/v0', '--guard-field-types', '--dry-run']);
      expect(registryFile.readAsStringSync(), legacy);
      await success(['--band', 'api/v0', '--guard-field-types']);
      final baseline = registryFile.readAsStringSync();
      final before = tombstones.readAsStringSync();
      final data = _registry(root);
      expect(data['types'][key]['fieldTypes'], {'0': 'String', '1': 'String?'});
      expect(data['types']['api/v1/Choice'].containsKey('fieldTypes'), isFalse);
      _write(
        root,
        'lib/v0/choice.dart',
        _choice.replaceFirst('String? label', 'int? label'),
      );
      for (final flags in [
        <String>[],
        ['--reidentify', 'api/v1/Choice'],
      ]) {
        final result = await _run(root, [...flags, ...output]);
        expect(result.exitCode, isNot(0));
        for (final detail in [
          '$key.label',
          'String?',
          'int?',
          '--reidentify $key',
        ]) {
          expect(result.stderr, contains(detail));
        }
        expect(registryFile.readAsStringSync(), baseline);
        expect(tombstones.readAsStringSync(), before);
      }
      await success(['--reidentify', key, '--dry-run']);
      expect(registryFile.readAsStringSync(), baseline);
      expect(tombstones.readAsStringSync(), before);
      final full = jsonDecode(baseline);
      full['bands']['api/v0']['end'] = 10000;
      registryFile.writeAsStringSync(jsonEncode(full));
      final exhausted = await _run(root, ['--reidentify', key, ...output]);
      expect(exhausted.exitCode, isNot(0));
      expect(registryFile.readAsStringSync(), jsonEncode(full));
      expect(tombstones.readAsStringSync(), before);
      registryFile.writeAsStringSync(baseline);
      await success(['--reidentify', key]);
      final accepted = registryFile.readAsStringSync();
      final updated = _registry(root);
      expect(updated['types'][key]['typeId'], 10001);
      expect(updated['types'][key]['fieldTypes']['1'], 'int?');
      expect(updated['retiredTypeIds'].containsKey('10000'), isTrue);
      expect(tombstones.readAsStringSync(), contains('10000'));
      await success(['--reidentify', key]);
      await success([]);
      expect(registryFile.readAsStringSync(), accepted);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
  test(
    'D5 rejects a retyped field in both entry points and rebuilds after recovery',
    () async {
      const key = 'api/v0/Sample';
      const registryPath = 'phive_type_registry.json';
      final file = File('${root.path}/$registryPath');
      _write(
        root,
        'build.yaml',
        'additional_public_assets: [phive_type_registry.json]\n',
      );
      for (final band in ['v0', 'v1']) {
        File('${root.path}/lib/$band/choice.dart').deleteSync();
      }
      void model(String type) => _write(root, 'lib/v0/sample.dart', """
import 'package:hive_ce/hive.dart';
part 'sample.g.dart';
@PHiveAutoType(autoFields:true,classHooks:[TolerantLayout()])
class Sample {
  final $type? value;
  const Sample(this.value);
}
""");
      Future<ProcessResult> dart(List<String> args) => Process.run(
        Platform.resolvedExecutable,
        args,
        workingDirectory: root.path,
      );
      Future<void> ok(Future<ProcessResult> command) async {
        final r = await command;
        expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
      }

      Future<ProcessResult> build() => dart(['run', 'build_runner', 'build']);
      File('${root.path}/roundtrip.dart').writeAsStringSync("""
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'lib/v0/sample.dart';
Future<void> main(List<String> args) async {
  Hive.init('data');
  final adapter = SampleAdapter();
  if (adapter.typeId != int.parse(args[1])) {
    throw StateError('Adapter has unexpected type ID \${adapter.typeId}');
  }
  Hive.registerAdapter(adapter);
  final box = await Hive.openLazyBox<Sample>('records');
  try {
    if (args.first == 'drift') {
      try {
        await box.get('old');
      } on PHiveSchemaDriftException catch (error) {
        if (error.fieldName == 'value') return;
        rethrow;
      }
      throw StateError('Expected schema drift');
    }
    final writingBaseline = args.first == 'write';
    final dynamic value = writingBaseline ? 42 : 'replacement';
    final key = writingBaseline ? 'old' : 'new';
    await box.put(key, Sample(value));
    if ((await box.get(key))?.value != value) throw StateError('Wrong value');
  } finally {
    await Hive.close();
  }
}
""");
      model('int');
      final flags = ['--band', 'api/v0', '--guard-field-types'];
      await ok(_run(root, flags));
      final baseline = file.readAsStringSync();
      final id = _registry(root)['types'][key]['typeId'] as int;
      await ok(build());
      await ok(dart(['run', 'roundtrip.dart', 'write', '$id']));
      model('String');
      final rejected = await _run(root, []);
      expect(rejected.exitCode, isNot(0));
      final failedBuild = await build();
      expect(failedBuild.exitCode, isNot(0));
      for (final r in [rejected, failedBuild]) {
        expect('${r.stdout}\n${r.stderr}', contains('$key.value'));
      }
      expect(file.readAsStringSync(), baseline);
      await ok(
        _run(root, [
          '--reidentify',
          key,
          '--tombstones',
          '${root.path}/lib/tombstones.dart',
        ]),
      );
      final accepted = file.readAsStringSync();
      final updated = _registry(root);
      final replacementId = updated['types'][key]['typeId'] as int;
      expect(replacementId, greaterThan(id));
      expect(updated['retiredTypeIds'].containsKey('$id'), isTrue);
      await ok(build());
      await ok(
        dart([
          'analyze',
          'lib/v0/sample.dart',
          'lib/v0/sample.g.dart',
          'roundtrip.dart',
        ]),
      );
      await ok(
        dart(['run', 'roundtrip.dart', 'replacement', '$replacementId']),
      );
      await ok(_run(root, []));
      expect(file.readAsStringSync(), accepted);

      // Replay the same old bytes using the original ID in an unenrolled registry.
      final legacy = jsonDecode(baseline);
      legacy['format'] = 2;
      for (final shape in legacy['types'].values) {
        shape.remove('fieldTypes');
      }
      file.writeAsStringSync(jsonEncode(legacy));
      await ok(_run(root, []));
      await ok(build());
      await ok(dart(['run', 'roundtrip.dart', 'drift', '$id']));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
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
  test('empty shapes assign, reload and generate without a rerun', () async {
    _write(root, 'lib/v0/empty.dart', """
import 'package:hive_ce/hive.dart';
part 'empty.g.dart';
@PHiveAutoType()
class Empty { const Empty(); }
@PHiveAutoType(classHooks: [TolerantLayout()])
class TaggedEmpty { const TaggedEmpty(); }
""");
    final assigned = await _run(root, []);
    expect(assigned.exitCode, 0, reason: assigned.stderr.toString());
    final reloaded = TypeIdRegistry.fromJson(
      File('${root.path}/phive_type_registry.json').readAsStringSync(),
    );
    expect(reloaded.shapeOf('api/v0/Empty')!.fields, isEmpty);
    expect(reloaded.shapeOf('api/v0/TaggedEmpty')!.fields, isEmpty);
    final built = await Process.run('dart', [
      'run',
      'build_runner',
      'build',
    ], workingDirectory: root.path);
    expect(built.exitCode, 0, reason: '${built.stdout} ${built.stderr}');
    final output = File('${root.path}/lib/v0/empty.g.dart').readAsStringSync();
    expect(output, contains('class EmptyAdapter'));
    expect(output, contains('class TaggedEmptyAdapter'));
    expect(output, contains('schemaFingerprint'));
    final analyzed = await Process.run('dart', [
      'analyze',
      'lib/v0/empty.dart',
      'lib/v0/empty.g.dart',
    ], workingDirectory: root.path);
    expect(
      analyzed.exitCode,
      0,
      reason: '${analyzed.stdout} ${analyzed.stderr}',
    );
  });
}
