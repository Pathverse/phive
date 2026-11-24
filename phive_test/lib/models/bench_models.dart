import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'bench_models.g.dart';

/// Benchmark twin stored positionally.
@PHiveAutoType(autoFields: true)
class BenchPositional {
  final String id;
  final String? title;
  final int count;
  final List<String> labels;
  final Map<String, int>? scores;

  const BenchPositional(this.id, this.title, this.count, this.labels, this.scores);
}

/// Benchmark twin stored with the tolerant layout.
@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
class BenchTolerant {
  final String id;
  final String? title;
  final int count;
  final List<String> labels;
  final Map<String, int>? scores;

  const BenchTolerant(this.id, this.title, this.count, this.labels, this.scores);
}
