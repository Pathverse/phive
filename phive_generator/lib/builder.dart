import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/phive_generator.dart';
import 'src/auto_type_generator.dart';

/// Builder factory for `@PHiveType`-annotated models.
///
/// Registered as `phive_generator|phive` in `build.yaml`.
Builder phiveBuilder(BuilderOptions options) => SharedPartBuilder(
      [PhiveGenerator()],
      'phive',
    );

/// Builder factory for `@PHiveAutoType`-annotated models.
///
/// Reads typeIds from `phive_type_registry.json` in the consuming package.
/// Registered as `phive_generator|phive_auto` in `build.yaml`.
Builder phiveAutoBuilder(BuilderOptions options) => SharedPartBuilder(
      [PhiveAutoTypeGenerator.fromFile()],
      'phive_auto',
    );
