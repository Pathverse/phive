// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tolerant_evolution.dart';

// **************************************************************************
// PhiveAutoTypeGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class EvolvedLessonAdapter extends PTypeAdapter<EvolvedLesson> {
  @override
  final int typeId = 27;

  @override
  String? get schemaFingerprint =>
      '231105e4b9ce2dff8154d610bbdf0124c95361cdc30e36cc08fbe1e732d7b384';

  @override
  EvolvedLesson read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'EvolvedLesson',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'EvolvedLesson',
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
          typeName: 'EvolvedLesson',
          fieldName: 'id',
          reason: 'stored ${raw_id.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'EvolvedLesson',
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
          typeName: 'EvolvedLesson',
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
          typeName: 'EvolvedLesson',
          fieldName: 'count',
          reason: 'stored ${raw_count.runtimeType} does not match int',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'EvolvedLesson',
        fieldName: 'count',
        reason: 'required field is missing',
      );
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
          typeName: 'EvolvedLesson',
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
          typeName: 'EvolvedLesson',
          fieldName: 'cards',
          reason:
              'stored ${raw_cards.runtimeType} does not match List<TolerantCard>',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'EvolvedLesson',
        fieldName: 'cards',
        reason: 'required field is missing',
      );
    }
    // summary (tag 6)
    final String? res_summary;
    if (values.containsKey(6)) {
      final raw_summary = values[6];
      try {
        res_summary = castStored<String?>(raw_summary);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'EvolvedLesson',
          fieldName: 'summary',
          reason: 'stored ${raw_summary.runtimeType} does not match String?',
        );
      }
    } else {
      res_summary = null;
    }
    final result = EvolvedLesson(
      cards: res_cards,
      count: res_count,
      summary: res_summary,
      title: res_title,
      id: res_id,
      scores: res_scores,
    );
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as EvolvedLesson;
  }

  @override
  void write(BinaryWriter writer, EvolvedLesson obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as EvolvedLesson;

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
      4: write_obj.scores,
      5: write_obj.cards,
      6: write_obj.summary,
    });

    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}

// ignore_for_file: non_constant_identifier_names

class RetypedLessonAdapter extends PTypeAdapter<RetypedLesson> {
  @override
  final int typeId = 31;

  @override
  String? get schemaFingerprint =>
      '7230ad525527bc934bbfe5cc3426007de407019f3e146cc4096559b8560c54ea';

  @override
  RetypedLesson read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'RetypedLesson',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'RetypedLesson',
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
          typeName: 'RetypedLesson',
          fieldName: 'id',
          reason: 'stored ${raw_id.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'RetypedLesson',
        fieldName: 'id',
        reason: 'required field is missing',
      );
    }
    // count (tag 2)
    final String res_count;
    if (values.containsKey(2)) {
      final raw_count = values[2];
      try {
        res_count = castStored<String>(raw_count);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'RetypedLesson',
          fieldName: 'count',
          reason: 'stored ${raw_count.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'RetypedLesson',
        fieldName: 'count',
        reason: 'required field is missing',
      );
    }
    final result = RetypedLesson(res_id, res_count);
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as RetypedLesson;
  }

  @override
  void write(BinaryWriter writer, RetypedLesson obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as RetypedLesson;

    final metadata_header = createMetadataHeader(
      version: PHiveMetadataHeader.taggedVersion,
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{},
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(<int, dynamic>{0: write_obj.id, 2: write_obj.count});

    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}

// ignore_for_file: non_constant_identifier_names

class RequiredAddedLessonAdapter extends PTypeAdapter<RequiredAddedLesson> {
  @override
  final int typeId = 30;

  @override
  String? get schemaFingerprint =>
      'a4f6c240f9cbed8c9c7282bd0e68f60ca7bfb579476c9b294f0e99478d10de1a';

  @override
  RequiredAddedLesson read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'RequiredAddedLesson',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'RequiredAddedLesson',
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
          typeName: 'RequiredAddedLesson',
          fieldName: 'id',
          reason: 'stored ${raw_id.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'RequiredAddedLesson',
        fieldName: 'id',
        reason: 'required field is missing',
      );
    }
    // region (tag 7)
    final String res_region;
    if (values.containsKey(7)) {
      final raw_region = values[7];
      try {
        res_region = castStored<String>(raw_region);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'RequiredAddedLesson',
          fieldName: 'region',
          reason: 'stored ${raw_region.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'RequiredAddedLesson',
        fieldName: 'region',
        reason: 'required field is missing',
      );
    }
    final result = RequiredAddedLesson(res_id, res_region);
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as RequiredAddedLesson;
  }

  @override
  void write(BinaryWriter writer, RequiredAddedLesson obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as RequiredAddedLesson;

    final metadata_header = createMetadataHeader(
      version: PHiveMetadataHeader.taggedVersion,
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{},
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(<int, dynamic>{0: write_obj.id, 7: write_obj.region});

    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}

// ignore_for_file: non_constant_identifier_names

class LegacyNoteAdapter extends PTypeAdapter<LegacyNote> {
  @override
  final int typeId = 28;

  @override
  String? get schemaFingerprint =>
      'cc8a29b4e4d20db3ea6fdf5b810f8d5a705fb4bd712c6cbeadb5c9379aa5fb0c';

  @override
  LegacyNote read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    applyMetadata(ctx_id, metadata_header.metadataForField('id'));
    applyMetadata(ctx_id, metadata_header.globalMetadata);
    runPreRead(const [PassThroughHook()], ctx_id);
    runPostRead(const [PassThroughHook()], ctx_id);
    final String res_id;
    try {
      res_id = castStored<String>(ctx_id.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'LegacyNote',
        fieldName: 'id',
        reason: 'stored ${ctx_id.value.runtimeType} does not match String',
      );
    }
    // legacy (index 1)
    final raw_legacy = reader.read();
    final ctx_legacy = PHiveCtx()..value = raw_legacy;
    applyMetadata(ctx_legacy, metadata_header.metadataForField('legacy'));
    applyMetadata(ctx_legacy, metadata_header.globalMetadata);
    runPreRead(const [PassThroughHook()], ctx_legacy);
    runPostRead(const [PassThroughHook()], ctx_legacy);
    final String res_legacy;
    try {
      res_legacy = castStored<String>(ctx_legacy.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'LegacyNote',
        fieldName: 'legacy',
        reason: 'stored ${ctx_legacy.value.runtimeType} does not match String',
      );
    }
    // body (index 2)
    final raw_body = reader.read();
    final ctx_body = PHiveCtx()..value = raw_body;
    applyMetadata(ctx_body, metadata_header.metadataForField('body'));
    applyMetadata(ctx_body, metadata_header.globalMetadata);
    runPreRead(const [PassThroughHook()], ctx_body);
    runPostRead(const [PassThroughHook()], ctx_body);
    final String res_body;
    try {
      res_body = castStored<String>(ctx_body.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'LegacyNote',
        fieldName: 'body',
        reason: 'stored ${ctx_body.value.runtimeType} does not match String',
      );
    }
    return LegacyNote(res_id, res_legacy, res_body);
  }

  @override
  void write(BinaryWriter writer, LegacyNote obj) {
    final global_metadata = const <String, dynamic>{};
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [PassThroughHook()], ctx_id);
    // legacy (index 1)
    final ctx_legacy = PHiveCtx()..value = obj.legacy;
    runPreWrite(const [PassThroughHook()], ctx_legacy);
    // body (index 2)
    final ctx_body = PHiveCtx()..value = obj.body;
    runPreWrite(const [PassThroughHook()], ctx_body);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_id.pendingMetadata.isNotEmpty)
          'id': Map<String, dynamic>.from(ctx_id.pendingMetadata),
        if (ctx_legacy.pendingMetadata.isNotEmpty)
          'legacy': Map<String, dynamic>.from(ctx_legacy.pendingMetadata),
        if (ctx_body.pendingMetadata.isNotEmpty)
          'body': Map<String, dynamic>.from(ctx_body.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_id.value);
    runPostWrite(const [PassThroughHook()], ctx_id);
    writer.write(ctx_legacy.value);
    runPostWrite(const [PassThroughHook()], ctx_legacy);
    writer.write(ctx_body.value);
    runPostWrite(const [PassThroughHook()], ctx_body);
  }
}

// ignore_for_file: non_constant_identifier_names

class MigratedNoteAdapter extends PTypeAdapter<MigratedNote> {
  @override
  final int typeId = 29;

  @override
  String? get schemaFingerprint =>
      '64cc250cc6b149b47a60a270ccb50ed08a759d5c009555cf1e6ee014e047dbf9';

  @override
  MigratedNote read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'MigratedNote',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
      values = <int, dynamic>{};
      values[0] = reader.read(); // id
      reader.read(); // retired: legacy
      values[2] = reader.read(); // body
    }
    // id (tag 0)
    final String res_id;
    if (values.containsKey(0)) {
      final ctx_id = PHiveCtx()..value = values[0];
      applyMetadata(ctx_id, metadata_header.metadataForField('id'));
      applyMetadata(ctx_id, metadata_header.globalMetadata);
      runPreRead(const [PassThroughHook()], ctx_id);
      runPostRead(const [PassThroughHook()], ctx_id);
      final raw_id = ctx_id.value;
      try {
        res_id = castStored<String>(raw_id);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'MigratedNote',
          fieldName: 'id',
          reason: 'stored ${raw_id.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'MigratedNote',
        fieldName: 'id',
        reason: 'required field is missing',
      );
    }
    // body (tag 2)
    final String res_body;
    if (values.containsKey(2)) {
      final ctx_body = PHiveCtx()..value = values[2];
      applyMetadata(ctx_body, metadata_header.metadataForField('body'));
      applyMetadata(ctx_body, metadata_header.globalMetadata);
      runPreRead(const [PassThroughHook()], ctx_body);
      runPostRead(const [PassThroughHook()], ctx_body);
      final raw_body = ctx_body.value;
      try {
        res_body = castStored<String>(raw_body);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'MigratedNote',
          fieldName: 'body',
          reason: 'stored ${raw_body.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'MigratedNote',
        fieldName: 'body',
        reason: 'required field is missing',
      );
    }
    final result = MigratedNote(res_id, res_body);
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as MigratedNote;
  }

  @override
  void write(BinaryWriter writer, MigratedNote obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as MigratedNote;
    // id (tag 0)
    final ctx_id = PHiveCtx()..value = write_obj.id;
    runPreWrite(const [PassThroughHook()], ctx_id);
    // body (tag 2)
    final ctx_body = PHiveCtx()..value = write_obj.body;
    runPreWrite(const [PassThroughHook()], ctx_body);
    final metadata_header = createMetadataHeader(
      version: PHiveMetadataHeader.taggedVersion,
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_id.pendingMetadata.isNotEmpty)
          'id': Map<String, dynamic>.from(ctx_id.pendingMetadata),
        if (ctx_body.pendingMetadata.isNotEmpty)
          'body': Map<String, dynamic>.from(ctx_body.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(<int, dynamic>{0: ctx_id.value, 2: ctx_body.value});
    runPostWrite(const [PassThroughHook()], ctx_id);
    runPostWrite(const [PassThroughHook()], ctx_body);
    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}
