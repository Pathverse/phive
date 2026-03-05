import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/phive_generator.dart';

Builder phiveBuilder(BuilderOptions options) => SharedPartBuilder(
      [PhiveGenerator()],
      'phive',
    );
