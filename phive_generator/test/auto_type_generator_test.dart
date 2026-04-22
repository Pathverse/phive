import 'dart:convert';

import 'package:source_gen_test/source_gen_test.dart';
import 'package:phive_generator/src/auto_type_generator.dart';
import 'package:phive_generator/src/type_registry.dart';

/// Snapshot tests for [PhiveAutoTypeGenerator] using an injected [TypeIdRegistry].
///
/// The registry maps each fixture class to a fixed typeId so the expected
/// snapshot strings are deterministic without requiring an actual
/// `phive_type_registry.json` file on disk.
Future<void> main() async {
  initializeBuildLogTracking();

  final reader = await initializeLibraryReaderForDirectory(
    'test/src',
    'auto_type_model.dart',
  );

  // Inject a fixed registry so snapshots are deterministic.
  final registry = TypeIdRegistry.fromJson(
    jsonEncode({
      'AutoTypeSimple': 10,
      'AutoTypeAutoFields': 20,
      'AutoTypeWithHooks': 30,
      'AutoTypeRouter': 40,
    }),
  );

  testAnnotatedElements(
    reader,
    PhiveAutoTypeGenerator(testRegistry: registry),
    expectedAnnotatedTests: [
      'AutoTypeSimple',
      'AutoTypeAutoFields',
      'AutoTypeWithHooks',
      'AutoTypeRouter',
    ],
  );
}
