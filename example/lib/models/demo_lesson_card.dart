import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

part 'demo_lesson_card.g.dart';

/// Demo child record used to showcase router containership and cascade flows.
@PHiveType(4)
class DemoLessonCard {
  /// Creates one card record for the router relations demo.
  const DemoLessonCard({
    required this.cardId,
    required this.lessonId,
    required this.prompt,
    required this.answer,
  });

  /// Primary key used by the example router.
  @PHiveField(0, hooks: [GCMEncrypted()])
  final String cardId;

  /// Parent lesson key used by the ref registration.
  @PHiveField(1)
  final String lessonId;

  /// Prompt shown in the router relations UI.
  @PHiveField(2)
  final String prompt;

  /// Answer shown in the router relations UI.
  @PHiveField(3)
  final String answer;
}