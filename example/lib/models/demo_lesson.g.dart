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
    final res_lessonId = reader.read() as String;
    // title (index 1)
    final res_title = reader.read() as String;
    return DemoLesson(lessonId: res_lessonId, title: res_title);
  }

  @override
  void write(BinaryWriter writer, DemoLesson obj) {
    writer.write(obj.lessonId);
    writer.write(obj.title);
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
      boxName: "demo_lessons",
    );
  }
}
