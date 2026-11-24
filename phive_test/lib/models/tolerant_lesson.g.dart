// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tolerant_lesson.dart';

// **************************************************************************
// PhiveAutoTypeGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class TolerantLessonAdapter extends PTypeAdapter<TolerantLesson> {
  @override
  final int typeId = 26;

  @override
  String? get schemaFingerprint =>
      'bcf45e3b95bd2809af34a70933ceb2839f1f23ed3cd41187543e680d803e9d23';

  @override
  TolerantLesson read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantLesson',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TolerantLesson',
        reason: 'version-2 record without a recorded positional sequence',
      );
    }
    // id (tag 0)
    final String res_id;
    if (values.containsKey(0)) {
      final raw_id = values[0];
      try {
        res_id = castStored<String>(raw_id);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantLesson',
          fieldName: 'id',
          reason: 'stored ${raw_id.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TolerantLesson',
        fieldName: 'id',
        reason: 'required field is missing',
      );
    }
    // title (tag 1)
    final String? res_title;
    if (values.containsKey(1)) {
      final raw_title = values[1];
      try {
        res_title = castStored<String?>(raw_title);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantLesson',
          fieldName: 'title',
          reason: 'stored ${raw_title.runtimeType} does not match String?',
        );
      }
    } else {
      res_title = null;
    }
    // count (tag 2)
    final int res_count;
    if (values.containsKey(2)) {
      final raw_count = values[2];
      try {
        res_count = castStored<int>(raw_count);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantLesson',
          fieldName: 'count',
          reason: 'stored ${raw_count.runtimeType} does not match int',
        );
      }
    } else {
      res_count = 0;
    }
    // labels (tag 3)
    final List<String> res_labels;
    if (values.containsKey(3)) {
      final raw_labels = values[3];
      try {
        res_labels = castStored<List<dynamic>>(
          raw_labels,
        ).map<String>((e0) => castStored<String>(e0)).toList();
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantLesson',
          fieldName: 'labels',
          reason:
              'stored ${raw_labels.runtimeType} does not match List<String>',
        );
      }
    } else {
      res_labels = const [];
    }
    // scores (tag 4)
    final Map<String, int>? res_scores;
    if (values.containsKey(4)) {
      final raw_scores = values[4];
      try {
        res_scores = raw_scores == null
            ? null
            : castStored<Map<dynamic, dynamic>>(raw_scores).map<String, int>(
                (k0, v0) =>
                    MapEntry(castStored<String>(k0), castStored<int>(v0)),
              );
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantLesson',
          fieldName: 'scores',
          reason:
              'stored ${raw_scores.runtimeType} does not match Map<String, int>?',
        );
      }
    } else {
      res_scores = null;
    }
    // cards (tag 5)
    final List<TolerantCard> res_cards;
    if (values.containsKey(5)) {
      final raw_cards = values[5];
      try {
        res_cards = castStored<List<dynamic>>(
          raw_cards,
        ).map<TolerantCard>((e0) => castStored<TolerantCard>(e0)).toList();
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantLesson',
          fieldName: 'cards',
          reason:
              'stored ${raw_cards.runtimeType} does not match List<TolerantCard>',
        );
      }
    } else {
      res_cards = const [];
    }
    final result = TolerantLesson(
      id: res_id,
      title: res_title,
      count: res_count,
      labels: res_labels,
      scores: res_scores,
      cards: res_cards,
    );
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as TolerantLesson;
  }

  @override
  void write(BinaryWriter writer, TolerantLesson obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as TolerantLesson;

    final metadata_header = createMetadataHeader(
      version: PHiveMetadataHeader.taggedVersion,
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{},
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(<int, dynamic>{
      0: write_obj.id,
      1: write_obj.title,
      2: write_obj.count,
      3: write_obj.labels,
      4: write_obj.scores,
      5: write_obj.cards,
    });

    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}

// ignore_for_file: non_constant_identifier_names

class TolerantCardAdapter extends PTypeAdapter<TolerantCard> {
  @override
  final int typeId = 25;

  @override
  String? get schemaFingerprint =>
      '276895bba3b0ee857866a1ad86b616ba596cef22bfd01aff1fc99a044c5eb158';

  @override
  TolerantCard read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantCard',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TolerantCard',
        reason: 'version-2 record without a recorded positional sequence',
      );
    }
    // id (tag 0)
    final String res_id;
    if (values.containsKey(0)) {
      final raw_id = values[0];
      try {
        res_id = castStored<String>(raw_id);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantCard',
          fieldName: 'id',
          reason: 'stored ${raw_id.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TolerantCard',
        fieldName: 'id',
        reason: 'required field is missing',
      );
    }
    // body (tag 1)
    final String? res_body;
    if (values.containsKey(1)) {
      final raw_body = values[1];
      try {
        res_body = castStored<String?>(raw_body);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TolerantCard',
          fieldName: 'body',
          reason: 'stored ${raw_body.runtimeType} does not match String?',
        );
      }
    } else {
      res_body = null;
    }
    final result = TolerantCard(res_id, res_body);
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as TolerantCard;
  }

  @override
  void write(BinaryWriter writer, TolerantCard obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as TolerantCard;

    final metadata_header = createMetadataHeader(
      version: PHiveMetadataHeader.taggedVersion,
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{},
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(<int, dynamic>{0: write_obj.id, 1: write_obj.body});

    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}
