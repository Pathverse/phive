import 'dart:io';

import 'package:phive_generator/src/resolved_scan.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  setUpAll(() async {
    root = Directory.systemTemp.createTempSync('phive-resolved-');
    File('${root.path}/pubspec.yaml').writeAsStringSync('''
name: resolved_fixture
environment:
  sdk: ^3.11.0
dependencies:
  phive:
    path: ${Directory('../phive').absolute.path}
''');
    final result = await Process.run('flutter', [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: root.path);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    Directory('${root.path}/lib').createSync();
  });
  tearDownAll(() => root.deleteSync(recursive: true));

  test(
    'resolved models include inherited fields and constant indexes',
    () async {
      File('${root.path}/lib/model.dart').writeAsStringSync('''
import 'package:phive/phive.dart';
const kTag = 4;
class Base { @PHiveField(0) final String id; const Base(this.id); }
@PHiveAutoType(classHooks: [TolerantLayout()])
class L extends Base {
  @PHiveField(1) final String t;
  const L(super.id, this.t);
}
@PHiveAutoType(classHooks: [TolerantLayout()])
class Constant { @PHiveField(kTag) final int x; const Constant(this.x); }
''');
      final result = await scanResolved(
        Directory('${root.path}/lib'),
        root: root,
      );
      final inherited = result.firstWhere((t) => t.className == 'L');
      expect(inherited.fields, ['id', 't']);
      expect(inherited.explicitTags, {'id': 0, 't': 1});
      expect(result.firstWhere((t) => t.className == 'Constant').explicitTags, {
        'x': 4,
      });
    },
  );

  test(
    'enums record declaration order and explicit tags, parts are skipped',
    () async {
      File('${root.path}/lib/enums.dart').writeAsStringSync('''
import 'package:phive/phive.dart';
part 'fragment.dart';
@PHiveAutoType() enum E { a, b }
@PHiveAutoType() enum Tagged { @PHiveField(3) a }
''');
      File(
        '${root.path}/lib/fragment.dart',
      ).writeAsStringSync("part of 'enums.dart';");
      final result = await scanResolved(
        Directory('${root.path}/lib'),
        root: root,
      );
      final e = result.firstWhere((t) => t.className == 'E');
      expect(e.kind, ScannedKind.enumeration);
      expect(e.fields, ['a', 'b']);
      expect(result.firstWhere((t) => t.className == 'Tagged').explicitTags, {
        'a': 3,
      });
    },
  );

  test('missing package config gives an actionable error', () async {
    final empty = Directory.systemTemp.createTempSync('phive-no-config-');
    try {
      await expectLater(
        scanResolved(empty, root: empty),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Run `dart pub get`'),
          ),
        ),
      );
    } finally {
      empty.deleteSync(recursive: true);
    }
  });
}
