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
    applyMetadata(ctx_cardId, metadata_header.globalMetadata);
    applyMetadata(ctx_cardId, metadata_header.metadataForField('cardId'));
    runPostRead(const [GCMEncrypted()], ctx_cardId);
    final res_cardId = ctx_cardId.value as String;
    // lessonId (index 1)
    final raw_lessonId = reader.read();
    final ctx_lessonId = PHiveCtx()..value = raw_lessonId;
    applyMetadata(ctx_lessonId, metadata_header.globalMetadata);
    applyMetadata(ctx_lessonId, metadata_header.metadataForField('lessonId'));
    runPostRead(const [], ctx_lessonId);
    final res_lessonId = ctx_lessonId.value as String;
    // prompt (index 2)
    final raw_prompt = reader.read();
    final ctx_prompt = PHiveCtx()..value = raw_prompt;
    applyMetadata(ctx_prompt, metadata_header.globalMetadata);
    applyMetadata(ctx_prompt, metadata_header.metadataForField('prompt'));
    runPostRead(const [], ctx_prompt);
    final res_prompt = ctx_prompt.value as String;
    // answer (index 3)
    final raw_answer = reader.read();
    final ctx_answer = PHiveCtx()..value = raw_answer;
    applyMetadata(ctx_answer, metadata_header.globalMetadata);
    applyMetadata(ctx_answer, metadata_header.metadataForField('answer'));
    runPostRead(const [], ctx_answer);
    final res_answer = ctx_answer.value as String;
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
    // lessonId (index 1)
    final ctx_lessonId = PHiveCtx()..value = obj.lessonId;
    runPreWrite(const [], ctx_lessonId);
    // prompt (index 2)
    final ctx_prompt = PHiveCtx()..value = obj.prompt;
    runPreWrite(const [], ctx_prompt);
    // answer (index 3)
    final ctx_answer = PHiveCtx()..value = obj.answer;
    runPreWrite(const [], ctx_answer);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_cardId.pendingMetadata.isNotEmpty)
          'cardId': Map<String, dynamic>.from(ctx_cardId.pendingMetadata),
        if (ctx_lessonId.pendingMetadata.isNotEmpty)
          'lessonId': Map<String, dynamic>.from(ctx_lessonId.pendingMetadata),
        if (ctx_prompt.pendingMetadata.isNotEmpty)
          'prompt': Map<String, dynamic>.from(ctx_prompt.pendingMetadata),
        if (ctx_answer.pendingMetadata.isNotEmpty)
          'answer': Map<String, dynamic>.from(ctx_answer.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_cardId.value);
    runPostWrite(const [GCMEncrypted()], ctx_cardId);
    writer.write(ctx_lessonId.value);
    runPostWrite(const [], ctx_lessonId);
    writer.write(ctx_prompt.value);
    runPostWrite(const [], ctx_prompt);
    writer.write(ctx_answer.value);
    runPostWrite(const [], ctx_answer);
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
      boxName: 'demo_lesson_cards',
    );
    router.createRef<DemoLessonCard, DemoLesson>(
      resolve: (item) => item.lessonId,
      refBoxName: 'demo_lesson_cards_by_lesson',
    );
  }
}
