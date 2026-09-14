import 'dart:convert';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:phive_generator/src/phive_generator.dart';
import 'package:phive_generator/src/auto_type_generator.dart';
import 'package:phive_generator/src/type_registry.dart';
import 'package:test/test.dart';

class _Names extends RecursiveAstVisitor<void> {
  final values = <String, String>{};
  @override
  void visitNamedExpression(NamedExpression node) {
    final name = node.name.label.name;
    if (name == 'boxName' || name == 'refBoxName') {
      expect(
        node.expression,
        isA<StringLiteral>(),
        reason: 'Storage identity must be emitted as a literal',
      );
      final literal = node.expression as StringLiteral;
      expect(
        literal.stringValue,
        isNotNull,
        reason: 'Storage names must not interpolate runtime values',
      );
      values[name] = literal.stringValue!;
    }
    super.visitNamedExpression(node);
  }
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
        final names = _Names();
        final parsed = parseString(content: output);
        expect(parsed.errors, isEmpty);
        parsed.unit.accept(names);
        final custom = switch (suffix) {
          'Custom' => ('cards_v1', 'links_v1'),
          'Constant' => (r'''cards_$'"\path''', 'relations_v1'),
          'BeforeRename' || 'AfterRename' => ('stable_cards', 'stable_links'),
          _ => (name.toLowerCase(), '__ref_NamingParent_$name'),
        };
        expect(names.values, {'boxName': custom.$1, 'refBoxName': custom.$2});
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
