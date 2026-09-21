import 'dart:convert';

import 'package:phive_generator/src/auto_type_generator.dart';
import 'package:phive_generator/src/phive_generator.dart';
import 'package:phive_generator/src/type_registry.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

/// Storage identity must be emitted as a compile-time literal, never an
/// interpolation that would resolve a box name at runtime.
///
/// This is asserted against the generated source text rather than the analyzer
/// AST on purpose: analyzer 14 removed `NamedExpression` in favour of
/// `NamedArgument`, so an AST-walking version of this test would compile only
/// against a single analyzer major and would narrow the range this package
/// supports. The text form holds across the whole `analyzer` constraint.
final _namedArgument = RegExp(
  r'^\s*(boxName|refBoxName):\s*(.*?),?\s*$',
  multiLine: true,
);

/// Decodes a Dart string literal, asserting it carries no live interpolation.
String _literalValue(String key, String source) {
  final quote = source.isEmpty ? '' : source[0];
  expect(
    (quote == '"' || quote == "'") && source.length >= 2 && source.endsWith(quote),
    isTrue,
    reason: 'Storage identity `$key` must be emitted as a literal, got: $source',
  );
  final body = source.substring(1, source.length - 1);
  final out = StringBuffer();
  for (var i = 0; i < body.length; i++) {
    final char = body[i];
    if (char == r'\' && i + 1 < body.length) {
      final escaped = body[++i];
      out.write(switch (escaped) {
        'n' => '\n',
        't' => '\t',
        'r' => '\r',
        _ => escaped,
      });
      continue;
    }
    expect(
      char,
      isNot(r'$'),
      reason: 'Storage identity `$key` must not interpolate a runtime value: $source',
    );
    out.write(char);
  }
  return out.toString();
}

Map<String, String> _storeNames(String output) {
  final names = <String, String>{};
  for (final match in _namedArgument.allMatches(output)) {
    final key = match.group(1)!;
    names[key] = _literalValue(key, match.group(2)!);
  }
  return names;
}

Future<void> main() async {
  initializeBuildLogTracking();
  final reader = await initializeLibraryReaderForDirectory(
    'test/src',
    'naming_model.dart',
  );
  const suffixes = [
    'Default',
    'Prefix',
    'Custom',
    'Constant',
    'Null',
    'BeforeRename',
    'AfterRename',
  ];
  final registry = TypeIdRegistry.fromJson(
    jsonEncode({
      for (var i = 0; i < suffixes.length; i++)
        'Automatic${suffixes[i]}': 80 + i,
    }),
  );
  for (final mode in ['Explicit', 'Automatic']) {
    for (final suffix in suffixes) {
      final name = '$mode$suffix';
      test('$name emits stable literal names with overrides intact', () async {
        final output = mode == 'Explicit'
            ? await generateForElement(PhiveGenerator(), reader, name)
            : await generateForElement(
                PhiveAutoTypeGenerator(testRegistry: registry),
                reader,
                name,
              );
        final custom = switch (suffix) {
          'Custom' => ('cards_v1', 'links_v1'),
          'Constant' => (r'''cards_$'"\path''', 'relations_v1'),
          'BeforeRename' || 'AfterRename' => ('stable_cards', 'stable_links'),
          _ => (name.toLowerCase(), '__ref_NamingParent_$name'),
        };
        expect(_storeNames(output), {
          'boxName': custom.$1,
          'refBoxName': custom.$2,
        });
        expect(
          output,
          contains(
            'createRef<$name, ${suffix == 'Prefix' ? 'second' : 'first'}.NamingParent>',
          ),
        );
      });
    }
  }
}
