// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bench_models.dart';

// **************************************************************************
// PhiveAutoTypeGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class BenchPositionalAdapter extends PTypeAdapter<BenchPositional> {
  @override
  final int typeId = 34;

  @override
  String? get schemaFingerprint =>
      '2bf8cd3e3dfba7861b10b93b177c09188586a8f360b7f2057fa6b00be019e1b0';

  @override
  BenchPositional read(BinaryReader reader) {
    // id (index 0)
    final res_id = reader.read() as String;
    // title (index 1)
    final res_title = reader.read() as String?;
    // count (index 2)
    final res_count = reader.read() as int;
    // labels (index 3)
    final res_labels = reader.read() as List<String>;
    return BenchPositional(res_id, res_title, res_count, res_labels);
  }

  @override
  void write(BinaryWriter writer, BenchPositional obj) {
    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.count);
    writer.write(obj.labels);
  }
}

// ignore_for_file: non_constant_identifier_names

class BenchTolerantAdapter extends PTypeAdapter<BenchTolerant> {
  @override
  final int typeId = 33;

  @override
  String? get schemaFingerprint =>
      'c2110490f0d443f3b9d64ee16dc60586c439189a8440e9483f7700c158155809';

  @override
  BenchTolerant read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'BenchTolerant',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'BenchTolerant',
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
          typeName: 'BenchTolerant',
          fieldName: 'id',
          reason: 'stored ${raw_id.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'BenchTolerant',
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
          typeName: 'BenchTolerant',
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
          typeName: 'BenchTolerant',
          fieldName: 'count',
          reason: 'stored ${raw_count.runtimeType} does not match int',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'BenchTolerant',
        fieldName: 'count',
        reason: 'required field is missing',
      );
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
          typeName: 'BenchTolerant',
          fieldName: 'labels',
          reason:
              'stored ${raw_labels.runtimeType} does not match List<String>',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'BenchTolerant',
        fieldName: 'labels',
        reason: 'required field is missing',
      );
    }
    final result = BenchTolerant(res_id, res_title, res_count, res_labels);
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as BenchTolerant;
  }

  @override
  void write(BinaryWriter writer, BenchTolerant obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as BenchTolerant;

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
    });

    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}
