import 'package:source_gen_test/source_gen_test.dart';
import 'package:phive_generator/src/phive_generator.dart';

Future<void> main() async {
  initializeBuildLogTracking();
  final reader = await initializeLibraryReaderForDirectory(
    'test/src',
    'simple_model.dart',
  );

  testAnnotatedElements(
    reader,
    PhiveGenerator(),
    expectedAnnotatedTests: ['SimpleModel'],
  );
}
