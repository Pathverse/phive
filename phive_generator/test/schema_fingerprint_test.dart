import 'package:phive_generator/src/schema_fingerprint.dart';
import 'package:test/test.dart';

String _fp({
  int typeId = 10,
  String layout = 'tolerant',
  Map<String, int> tags = const {'id': 0, 'title': 1},
  Map<String, String> types = const {'id': 'String', 'title': 'String?'},
}) => computeSchemaFingerprint(
  typeId: typeId,
  layout: layout,
  tags: tags,
  types: types,
);

void main() {
  test('is a stable SHA-256 hex digest', () {
    expect(_fp(), matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(_fp(), _fp());
  });

  test('does not depend on field declaration order', () {
    expect(
      _fp(
        tags: const {'title': 1, 'id': 0},
        types: const {'title': 'String?', 'id': 'String'},
      ),
      _fp(),
    );
  });

  final base = _fp();
  final changes = <String, String>{
    'field added': _fp(
      tags: const {'id': 0, 'title': 1, 'body': 2},
      types: const {'id': 'String', 'title': 'String?', 'body': 'String?'},
    ),
    'field removed': _fp(
      tags: const {'id': 0},
      types: const {'id': 'String'},
    ),
    'field retyped': _fp(types: const {'id': 'String', 'title': 'int?'}),
    'field retagged': _fp(tags: const {'id': 0, 'title': 2}),
    'field renamed': _fp(
      tags: const {'id': 0, 'name': 1},
      types: const {'id': 'String', 'name': 'String?'},
    ),
    'type ID changed': _fp(typeId: 11),
    'layout changed': _fp(layout: 'positional'),
  };
  for (final entry in changes.entries) {
    test('changes when the ${entry.key}', () {
      expect(entry.value, isNot(base));
    });
  }
}
