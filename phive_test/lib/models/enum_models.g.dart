// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_models.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class PositionalPaletteAdapter extends PTypeAdapter<PositionalPalette> {
  @override
  final int typeId = 62;

  @override
  String? get schemaFingerprint =>
      'f7b0aed99b8fb4cc7c5bc3052fc4c1c6412f0c652fbd2927cf157cebf098e76c';

  @override
  PositionalPalette read(BinaryReader reader) {
    // primary (index 0)
    final raw_primary = reader.read();
    final ProofColor res_primary;
    try {
      res_primary = castStored<ProofColor>(raw_primary);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalPalette',
        fieldName: 'primary',
        reason: 'stored ${raw_primary.runtimeType} does not match ProofColor',
      );
    }
    return PositionalPalette(res_primary);
  }

  @override
  void write(BinaryWriter writer, PositionalPalette obj) {
    writer.write(obj.primary);
  }
}

// **************************************************************************
// PhiveAutoTypeGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class PaletteAdapter extends PTypeAdapter<Palette> {
  @override
  final int typeId = 121;

  @override
  String? get schemaFingerprint =>
      '6790362d9b7d2e9b29200a3b7ef7d9ba74dacb814acab2d8af2c004c79dd223d';

  @override
  Palette read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: 'Palette',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'Palette',
        reason: 'version-2 record without a recorded positional sequence',
      );
    }
    // primary (tag 0)
    final ProofColor res_primary;
    if (values.containsKey(0)) {
      final raw_primary = values[0];
      try {
        res_primary = castStored<ProofColor>(raw_primary);
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'Palette',
          fieldName: 'primary',
          reason: 'stored ${raw_primary.runtimeType} does not match ProofColor',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'Palette',
        fieldName: 'primary',
        reason: 'required field is missing',
      );
    }
    // extras (tag 1)
    final List<ProofColor> res_extras;
    if (values.containsKey(1)) {
      final raw_extras = values[1];
      try {
        res_extras = castStored<List<dynamic>>(
          raw_extras,
        ).map<ProofColor>((e0) => castStored<ProofColor>(e0)).toList();
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: 'Palette',
          fieldName: 'extras',
          reason:
              'stored ${raw_extras.runtimeType} does not match List<ProofColor>',
        );
      }
    } else {
      throw PHiveSchemaDriftException(
        typeName: 'Palette',
        fieldName: 'extras',
        reason: 'required field is missing',
      );
    }
    final result = Palette(res_primary, res_extras);
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [TolerantLayout()], ctx_obj);
    runPostRead(const [TolerantLayout()], ctx_obj);
    return ctx_obj.value as Palette;
  }

  @override
  void write(BinaryWriter writer, Palette obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [TolerantLayout()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as Palette;

    final metadata_header = createMetadataHeader(
      version: PHiveMetadataHeader.taggedVersion,
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{},
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(<int, dynamic>{0: write_obj.primary, 1: write_obj.extras});

    runPostWrite(const [TolerantLayout()], ctx_obj);
  }
}

// ignore_for_file: non_constant_identifier_names

class ProofColorAdapter extends PTypeAdapter<ProofColor> {
  @override
  final int typeId = 122;

  @override
  String? get schemaFingerprint =>
      '2295941b4947e0a456cce4a20a4471e38505865dd35a44c7cd3c2015a1051bfd';

  @override
  ProofColor read(BinaryReader reader) {
    final raw_tag = reader.read();
    if (raw_tag is! int) {
      throw PHiveSchemaDriftException(
        typeName: 'ProofColor',
        reason: 'stored ${raw_tag.runtimeType} is not an enum case tag',
      );
    }
    switch (raw_tag) {
      case 0:
        return ProofColor.red;
      case 1:
        return ProofColor.green;
      case 2:
        return ProofColor.blue;
      default:
        throw PHiveSchemaDriftException(
          typeName: 'ProofColor',
          reason: 'unknown case tag $raw_tag',
        );
    }
  }

  @override
  void write(BinaryWriter writer, ProofColor obj) {
    writer.write(switch (obj) {
      ProofColor.red => 0,
      ProofColor.green => 1,
      ProofColor.blue => 2,
    });
  }
}

// ignore_for_file: non_constant_identifier_names

class ProofColorReorderedAdapter extends PTypeAdapter<ProofColorReordered> {
  @override
  final int typeId = 123;

  @override
  String? get schemaFingerprint =>
      '14fbe5c00b75c567b6ca09618a425cd23fc4c9d608f20edbd25b89039ef6ae11';

  @override
  ProofColorReordered read(BinaryReader reader) {
    final raw_tag = reader.read();
    if (raw_tag is! int) {
      throw PHiveSchemaDriftException(
        typeName: 'ProofColorReordered',
        reason: 'stored ${raw_tag.runtimeType} is not an enum case tag',
      );
    }
    switch (raw_tag) {
      case 0:
        return ProofColorReordered.red;
      case 1:
        return ProofColorReordered.green;
      case 2:
        return ProofColorReordered.blue;
      default:
        throw PHiveSchemaDriftException(
          typeName: 'ProofColorReordered',
          reason: 'unknown case tag $raw_tag',
        );
    }
  }

  @override
  void write(BinaryWriter writer, ProofColorReordered obj) {
    writer.write(switch (obj) {
      ProofColorReordered.red => 0,
      ProofColorReordered.green => 1,
      ProofColorReordered.blue => 2,
    });
  }
}

// ignore_for_file: non_constant_identifier_names

class ProofColorTrimmedAdapter extends PTypeAdapter<ProofColorTrimmed> {
  @override
  final int typeId = 124;

  @override
  String? get schemaFingerprint =>
      '3866b3c520d560eef3b80da1606971298695036f2cf957408d26d5be0ce91d52';

  @override
  ProofColorTrimmed read(BinaryReader reader) {
    final raw_tag = reader.read();
    if (raw_tag is! int) {
      throw PHiveSchemaDriftException(
        typeName: 'ProofColorTrimmed',
        reason: 'stored ${raw_tag.runtimeType} is not an enum case tag',
      );
    }
    switch (raw_tag) {
      case 0:
        return ProofColorTrimmed.red;
      case 1:
        return ProofColorTrimmed.green;
      default:
        throw PHiveSchemaDriftException(
          typeName: 'ProofColorTrimmed',
          reason: 'unknown case tag $raw_tag',
        );
    }
  }

  @override
  void write(BinaryWriter writer, ProofColorTrimmed obj) {
    writer.write(switch (obj) {
      ProofColorTrimmed.red => 0,
      ProofColorTrimmed.green => 1,
    });
  }
}
