// Run from phive_test: flutter test --no-pub benchmark/tolerant_benchmark.dart
// ignore_for_file: avoid_print, implementation_imports

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
import 'package:hive_ce/src/binary/binary_writer_impl.dart';
import 'package:phive_test/models/bench_models.dart';
import 'package:phive_test/models/positional_collections.dart';
import 'package:phive_test/models/tolerant_lesson.dart';

const _iterations = 20000;

({double encodeUs, double decodeUs, int bytes}) _measure<T>(
  TypeAdapter<T> adapter,
  T value,
) {
  List<int> encode() {
    final writer = BinaryWriterImpl(Hive);
    adapter.write(writer, value);
    return writer.toBytes();
  }

  final bytes = encode();
  for (var i = 0; i < 2000; i++) {
    adapter.read(BinaryReaderImpl(encode() as dynamic, Hive));
  }

  final encodeWatch = Stopwatch()..start();
  for (var i = 0; i < _iterations; i++) {
    encode();
  }
  encodeWatch.stop();

  final decodeWatch = Stopwatch()..start();
  for (var i = 0; i < _iterations; i++) {
    adapter.read(BinaryReaderImpl(bytes as dynamic, Hive));
  }
  decodeWatch.stop();

  return (
    encodeUs: encodeWatch.elapsedMicroseconds / _iterations,
    decodeUs: decodeWatch.elapsedMicroseconds / _iterations,
    bytes: bytes.length,
  );
}

void main() {
  test('tagged versus positional encode/decode', () {
    Hive
      ..registerAdapter<TolerantCard>(TolerantCardAdapter())
      ..registerAdapter<TolerantLesson>(TolerantLessonAdapter())
      ..registerAdapter<PositionalItem>(PositionalItemAdapter());

    const labels = ['alpha', 'beta', 'gamma', 'delta'];
    const scores = {'a': 1, 'b': 2, 'c': 3};
    final rows = {
      'positional twin': _measure(
        BenchPositionalAdapter(),
        const BenchPositional('id-1', 'Title', 42, labels, scores),
      ),
      'tagged twin': _measure(
        BenchTolerantAdapter(),
        const BenchTolerant('id-1', 'Title', 42, labels, scores),
      ),
      'positional nested (20 items)': _measure(
        PositionalCollectionsAdapter(),
        PositionalCollections(
          items: [for (var i = 0; i < 20; i++) PositionalItem('item-$i')],
          scores: scores,
          tags: labels.toSet(),
          grid: const [],
          hooked: const [],
        ),
      ),
      'tagged nested (20 cards)': _measure(
        TolerantLessonAdapter(),
        TolerantLesson(
          id: 'lesson',
          title: 'Title',
          count: 42,
          labels: labels,
          scores: scores,
          cards: [
            for (var i = 0; i < 20; i++) TolerantCard('card-$i', 'body $i'),
          ],
        ),
      ),
    };

    print('| Model | Encode (µs/op) | Decode (µs/op) | Bytes |');
    print('|---|---|---|---|');
    for (final entry in rows.entries) {
      final r = entry.value;
      print(
        '| ${entry.key} | ${r.encodeUs.toStringAsFixed(2)} '
        '| ${r.decodeUs.toStringAsFixed(2)} | ${r.bytes} |',
      );
    }
  });
}
