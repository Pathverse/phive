import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'tolerant_lesson.g.dart';

/// Integration fixture for the tolerant layout: nullable, defaulted, typed
/// collection and nested tolerant fields, stored as tagged records.
@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
class TolerantLesson {
  /// Primary identifier.
  final String id;

  /// Optional title.
  final String? title;

  /// Defaulted counter.
  final int count;

  /// Typed list of primitives.
  final List<String> labels;

  /// Optional typed map.
  final Map<String, int>? scores;

  /// Nested tolerant records.
  final List<TolerantCard> cards;

  /// Creates a tolerant lesson.
  const TolerantLesson({
    required this.id,
    this.title,
    this.count = 0,
    this.labels = const [],
    this.scores,
    this.cards = const [],
  });
}

/// Nested tolerant fixture stored inside [TolerantLesson.cards].
@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
class TolerantCard {
  /// Card identifier.
  final String id;

  /// Optional body.
  final String? body;

  /// Creates a tolerant card.
  const TolerantCard(this.id, [this.body]);
}
