// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_lesson_card.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class DemoLessonCardAdapter extends PTypeAdapter<DemoLessonCard> {
  @override
  final int typeId = 4;

  @override
  DemoLessonCard read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // cardId (index 0)
    final raw_cardId = reader.read();
    final ctx_cardId = PHiveCtx()..value = raw_cardId;
    applyMetadata(ctx_cardId, metadata_header.metadataForField('cardId'));
    applyMetadata(ctx_cardId, metadata_header.globalMetadata);
    runPreRead(const [GCMEncrypted()], ctx_cardId);
    runPostRead(const [GCMEncrypted()], ctx_cardId);
    final res_cardId = ctx_cardId.value as String;
    // lessonId (index 1)
    final res_lessonId = reader.read() as String;
    // prompt (index 2)
    final res_prompt = reader.read() as String;
    // answer (index 3)
    final res_answer = reader.read() as String;
    return DemoLessonCard(
      cardId: res_cardId,
      lessonId: res_lessonId,
      prompt: res_prompt,
      answer: res_answer,
    );
  }

  @override
  void write(BinaryWriter writer, DemoLessonCard obj) {
    final global_metadata = const <String, dynamic>{};
    // cardId (index 0)
    final ctx_cardId = PHiveCtx()..value = obj.cardId;
    runPreWrite(const [GCMEncrypted()], ctx_cardId);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_cardId.pendingMetadata.isNotEmpty)
          'cardId': Map<String, dynamic>.from(ctx_cardId.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_cardId.value);
    runPostWrite(const [GCMEncrypted()], ctx_cardId);
    writer.write(obj.lessonId);
    writer.write(obj.prompt);
    writer.write(obj.answer);
  }
}

/// Generated router descriptor for DemoLessonCard registration and refs.
class DemoLessonCardRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for DemoLessonCard.
  const DemoLessonCardRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<DemoLessonCard>(
      primaryKey: (item) => item.cardId,
      boxName: "demo_lesson_cards",
    );
    router.createRef<DemoLessonCard, DemoLesson>(
      resolve: (item) => item.lessonId,
      refBoxName: "demo_lesson_cards_by_lesson",
    );
  }
}
