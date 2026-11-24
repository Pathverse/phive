// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'empty_models.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class EmptyPositionalAdapter extends PTypeAdapter<EmptyPositional> {
  @override
  final int typeId = 80;

  @override
  String? get schemaFingerprint =>
      'd670aacb357285898989dc8d6f581bf4ae9f76e67b254489d22b16078956faac';

  @override
  EmptyPositional read(BinaryReader reader) {
    return EmptyPositional();
  }

  @override
  void write(BinaryWriter writer, EmptyPositional obj) {}
}

// ignore_for_file: non_constant_identifier_names

class EmptyTaggedAdapter extends PTypeAdapter<EmptyTagged> {
  @override
  final int typeId = 81;

  @override
  String? get schemaFingerprint =>
      'a8188291e55f5a82618d46dedaf430fcb2d8359b32259a82e0084e30363c2193';

  @override
  EmptyTagged read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'EmptyTagged',
          reason: 'tagged record body is not a map',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'EmptyTagged',
        reason: 'version-2 record without a recorded positional sequence',
      );
    }

    final result = EmptyTagged();
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as EmptyTagged;
  }

  @override
  void write(BinaryWriter writer, EmptyTagged obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);

    final metadata_header = createMetadataHeader(
      version: PHiveMetadataHeader.taggedVersion,
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{},
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(<int, dynamic>{});

    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}

// ignore_for_file: non_constant_identifier_names

class PositionalEmptyParentAdapter extends PTypeAdapter<PositionalEmptyParent> {
  @override
  final int typeId = 82;

  @override
  String? get schemaFingerprint =>
      '40660cd9485ec9a3ff27af5085853fdd8d1267c428d1b522f9f7eb8ac3fe2429';

  @override
  PositionalEmptyParent read(BinaryReader reader) {
    // before (index 0)
    final raw_before = reader.read();
    final String res_before;
    try {
      res_before = castStored<String>(raw_before);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalEmptyParent',
        fieldName: 'before',
        reason: 'stored ${raw_before.runtimeType} does not match String',
      );
    }
    // positional (index 1)
    final raw_positional = reader.read();
    final EmptyPositional res_positional;
    try {
      res_positional = castStored<EmptyPositional>(raw_positional);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalEmptyParent',
        fieldName: 'positional',
        reason:
            'stored ${raw_positional.runtimeType} does not match EmptyPositional',
      );
    }
    // between (index 2)
    final raw_between = reader.read();
    final String res_between;
    try {
      res_between = castStored<String>(raw_between);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalEmptyParent',
        fieldName: 'between',
        reason: 'stored ${raw_between.runtimeType} does not match String',
      );
    }
    // tagged (index 3)
    final raw_tagged = reader.read();
    final EmptyTagged res_tagged;
    try {
      res_tagged = castStored<EmptyTagged>(raw_tagged);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalEmptyParent',
        fieldName: 'tagged',
        reason: 'stored ${raw_tagged.runtimeType} does not match EmptyTagged',
      );
    }
    // after (index 4)
    final raw_after = reader.read();
    final String res_after;
    try {
      res_after = castStored<String>(raw_after);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalEmptyParent',
        fieldName: 'after',
        reason: 'stored ${raw_after.runtimeType} does not match String',
      );
    }
    return PositionalEmptyParent(
      res_before,
      res_positional,
      res_between,
      res_tagged,
      res_after,
    );
  }

  @override
  void write(BinaryWriter writer, PositionalEmptyParent obj) {
    writer.write(obj.before);
    writer.write(obj.positional);
    writer.write(obj.between);
    writer.write(obj.tagged);
    writer.write(obj.after);
  }
}

// ignore_for_file: non_constant_identifier_names

class TaggedEmptyParentAdapter extends PTypeAdapter<TaggedEmptyParent> {
  @override
  final int typeId = 83;

  @override
  String? get schemaFingerprint =>
      '2800811412fb450c3b580009b4d2ce037b5b7f58ed3a6c42a196531f48ec3886';

  @override
  TaggedEmptyParent read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'TaggedEmptyParent',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TaggedEmptyParent',
        reason: 'version-2 record without a recorded positional sequence',
      );
    }
    // before (tag 0)
    final String res_before;
    if (values.containsKey(0)) {
      final raw_before = values[0];
      try {
        res_before = castStored<String>(raw_before);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TaggedEmptyParent',
          fieldName: 'before',
          reason: 'stored ${raw_before.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TaggedEmptyParent',
        fieldName: 'before',
        reason: 'required field is missing',
      );
    }
    // positional (tag 1)
    final EmptyPositional res_positional;
    if (values.containsKey(1)) {
      final raw_positional = values[1];
      try {
        res_positional = castStored<EmptyPositional>(raw_positional);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TaggedEmptyParent',
          fieldName: 'positional',
          reason:
              'stored ${raw_positional.runtimeType} does not match EmptyPositional',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TaggedEmptyParent',
        fieldName: 'positional',
        reason: 'required field is missing',
      );
    }
    // between (tag 2)
    final String res_between;
    if (values.containsKey(2)) {
      final raw_between = values[2];
      try {
        res_between = castStored<String>(raw_between);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TaggedEmptyParent',
          fieldName: 'between',
          reason: 'stored ${raw_between.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TaggedEmptyParent',
        fieldName: 'between',
        reason: 'required field is missing',
      );
    }
    // tagged (tag 3)
    final EmptyTagged res_tagged;
    if (values.containsKey(3)) {
      final raw_tagged = values[3];
      try {
        res_tagged = castStored<EmptyTagged>(raw_tagged);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TaggedEmptyParent',
          fieldName: 'tagged',
          reason: 'stored ${raw_tagged.runtimeType} does not match EmptyTagged',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TaggedEmptyParent',
        fieldName: 'tagged',
        reason: 'required field is missing',
      );
    }
    // after (tag 4)
    final String res_after;
    if (values.containsKey(4)) {
      final raw_after = values[4];
      try {
        res_after = castStored<String>(raw_after);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'TaggedEmptyParent',
          fieldName: 'after',
          reason: 'stored ${raw_after.runtimeType} does not match String',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'TaggedEmptyParent',
        fieldName: 'after',
        reason: 'required field is missing',
      );
    }
    final result = TaggedEmptyParent(
      res_before,
      res_positional,
      res_between,
      res_tagged,
      res_after,
    );
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as TaggedEmptyParent;
  }

  @override
  void write(BinaryWriter writer, TaggedEmptyParent obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as TaggedEmptyParent;

    final metadata_header = createMetadataHeader(
      version: PHiveMetadataHeader.taggedVersion,
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{},
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(<int, dynamic>{
      0: write_obj.before,
      1: write_obj.positional,
      2: write_obj.between,
      3: write_obj.tagged,
      4: write_obj.after,
    });

    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}
