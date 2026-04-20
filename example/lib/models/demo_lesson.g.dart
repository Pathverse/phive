// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_lesson.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class DemoLessonAdapter extends PTypeAdapter<DemoLesson> {
  @override
  final int typeId = 3;

  @override
  DemoLesson read(BinaryReader reader) {
    // lessonId (index 0)
    final raw_lessonId = reader.read();
    final ctx_lessonId = extractPayload(raw_lessonId);
    runPostRead(const [], ctx_lessonId);
    final res_lessonId = ctx_lessonId.value as String;
    // title (index 1)
    final raw_title = reader.read();
    final ctx_title = extractPayload(raw_title);
    runPostRead(const [], ctx_title);
    final res_title = ctx_title.value as String;
    return DemoLesson(lessonId: res_lessonId, title: res_title);
  }

  @override
  void write(BinaryWriter writer, DemoLesson obj) {
    // lessonId (index 0)
    final ctx_lessonId = PHiveCtx()..value = obj.lessonId;
    runPreWrite(const [], ctx_lessonId);
    writer.write(
      serializePayload(ctx_lessonId.value, ctx_lessonId.pendingMetadata),
    );
    runPostWrite(const [], ctx_lessonId);
    // title (index 1)
    final ctx_title = PHiveCtx()..value = obj.title;
    runPreWrite(const [], ctx_title);
    writer.write(serializePayload(ctx_title.value, ctx_title.pendingMetadata));
    runPostWrite(const [], ctx_title);
  }
}

/// Generated router descriptor for DemoLesson registration and refs.
class DemoLessonRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for DemoLesson.
  const DemoLessonRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<DemoLesson>(
      primaryKey: (item) => item.lessonId,
      boxName: 'demo_lessons',
    );
  }
}
