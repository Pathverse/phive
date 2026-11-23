import 'package:source_gen_test/source_gen_test.dart';
import 'package:phive_generator/src/phive_generator.dart';
import 'package:phive_generator/src/annotation_helpers.dart';
import 'package:phive_generator/src/field_collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

/// Runs generator snapshot tests for PHive annotated fixtures.
Future<void> main() async {
  initializeBuildLogTracking();
  final reader = await initializeLibraryReaderForDirectory(
    'test/src',
    'simple_model.dart',
  );

  testAnnotatedElements(
    reader,
    PhiveGenerator(),
    expectedAnnotatedTests: [
      'SimpleModel',
      'AutoFieldModel',
      'HybridAutoFieldModel',
      'ClassHookModel',
      'RouterModel',
      'SingletonRouterModel',
    ],
  );

  final input = await initializeLibraryReader({
    'fixture.dart': '''
import 'package:phive/phive.dart';

const actualIndex = 8;
class Hook extends PHiveHook {
  const Hook(Object options);
}

@PHiveType(1, hooks: [
  Hook({'hooks: [wrong]': [1, 2]}),
], classHooks: [
  Hook(1),
])
class WithHooks {
  WithHooks(this.first, this.second, this.third);
  @PHiveField(actualIndex, hooks: [Hook([1, 2])])
  final String first;
  @PHiveField(1)
  final String second;
  final String third;
}

class UnresolvedIndex {
  UnresolvedIndex(this.value);
  @PHiveField(undefinedIndex)
  final String value;
}
''',
  }, 'fixture.dart');

  final example = input.classes.singleWhere((cls) => cls.name == 'WithHooks');
  final unresolved = input.classes.singleWhere(
    (cls) => cls.name == 'UnresolvedIndex',
  );

  test('field collection orders evaluated and inferred indices', () {
    final fields = collectMappedFields(
      element: example,
      cls: example,
      constr: example.constructors.single,
      autoFields: true,
    );
    expect(fields.map((field) => (field.name, field.index)), [
      ('third', 0),
      ('second', 1),
      ('first', 8),
    ]);
  });

  test('field collection rejects an unresolved explicit index', () {
    expect(
      () => collectMappedFields(
        element: unresolved,
        cls: unresolved,
        constr: unresolved.constructors.single,
        autoFields: true,
      ),
      throwsA(isA<InvalidGenerationSourceError>()),
    );
  });

  test(
    'field, model and class hook lists retain complete nested expressions',
    () {
      final fields = collectMappedFields(
        element: example,
        cls: example,
        constr: example.constructors.single,
        autoFields: true,
      );
      expect(
        fields.singleWhere((field) => field.name == 'first').hooksSource,
        '[Hook([1, 2])]',
      );
      expect(
        extractModelHooksSource(example),
        matches(r"^\[Hook\(\{'hooks: \[wrong\]'\s*:\s*\[1, 2\]\}\)\]$"),
      );
      expect(extractModelClassHooksSource(example), '[Hook(1)]');
    },
  );
}
