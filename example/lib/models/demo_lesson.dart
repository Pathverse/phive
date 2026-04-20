import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'demo_lesson.g.dart';

/// Demo lesson model used to showcase router parent-child relationships.
@PHiveType(3)
class DemoLesson {
  /// Creates one lesson record for the router relations demo.
  const DemoLesson({required this.lessonId, required this.title});

  /// Primary key used by the example router.
  @PHiveField(0)
  final String lessonId;

  /// Human-readable lesson title displayed in the UI.
  @PHiveField(1)
  final String title;
}