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
    // cardId (index 0)
    final raw_cardId = reader.read();
    final ctx_cardId = extractPayload(raw_cardId);
    runPostRead(const [GCMEncrypted()], ctx_cardId);
    final res_cardId = ctx_cardId.value as String;
    // lessonId (index 1)
    final raw_lessonId = reader.read();
    final ctx_lessonId = extractPayload(raw_lessonId);
    runPostRead(const [], ctx_lessonId);
    final res_lessonId = ctx_lessonId.value as String;
    // prompt (index 2)
    final raw_prompt = reader.read();
    final ctx_prompt = extractPayload(raw_prompt);
    runPostRead(const [], ctx_prompt);
    final res_prompt = ctx_prompt.value as String;
    // answer (index 3)
    final raw_answer = reader.read();
    final ctx_answer = extractPayload(raw_answer);
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
    // cardId (index 0)
    final ctx_cardId = PHiveCtx()..value = obj.cardId;
    runPreWrite(const [GCMEncrypted()], ctx_cardId);
    writer.write(
      serializePayload(ctx_cardId.value, ctx_cardId.pendingMetadata),
    );
    runPostWrite(const [GCMEncrypted()], ctx_cardId);
    // lessonId (index 1)
    final ctx_lessonId = PHiveCtx()..value = obj.lessonId;
    runPreWrite(const [], ctx_lessonId);
    writer.write(
      serializePayload(ctx_lessonId.value, ctx_lessonId.pendingMetadata),
    );
    runPostWrite(const [], ctx_lessonId);
    // prompt (index 2)
    final ctx_prompt = PHiveCtx()..value = obj.prompt;
    runPreWrite(const [], ctx_prompt);
    writer.write(
      serializePayload(ctx_prompt.value, ctx_prompt.pendingMetadata),
    );
    runPostWrite(const [], ctx_prompt);
    // answer (index 3)
    final ctx_answer = PHiveCtx()..value = obj.answer;
    runPreWrite(const [], ctx_answer);
    writer.write(
      serializePayload(ctx_answer.value, ctx_answer.pendingMetadata),
    );
    runPostWrite(const [], ctx_answer);
  }
}
