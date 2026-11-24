import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'bench_models.g.dart';

// The twins omit typed maps and lists of models: positional adapters cannot
// decode those (hive_ce restores them untyped), so they would not compare.

/// Benchmark twin stored positionally.
@PHiveAutoType(autoFields: true)
class BenchPositional {
  final String id;
  final String? title;
  final int count;
  final List<String> labels;

  const BenchPositional(this.id, this.title, this.count, this.labels);
}

/// Benchmark twin stored with the tolerant layout.
@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
class BenchTolerant {
  final String id;
  final String? title;
  final int count;
  final List<String> labels;

  const BenchTolerant(this.id, this.title, this.count, this.labels);
}
