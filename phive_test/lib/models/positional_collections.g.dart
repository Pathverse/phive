// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'positional_collections.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class PositionalItemAdapter extends PTypeAdapter<PositionalItem> {
  @override
  final int typeId = 60;

  @override
  String? get schemaFingerprint =>
      '6c611ec7e2317aae7ea2e84479071d68d68df0135eacd3d02b3ccec18e40efa5';

  @override
  PositionalItem read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalItem',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    return PositionalItem(res_id);
  }

  @override
  void write(BinaryWriter writer, PositionalItem obj) {
    writer.write(obj.id);
  }
}

// ignore_for_file: non_constant_identifier_names

class PositionalCollectionsAdapter extends PTypeAdapter<PositionalCollections> {
  @override
  final int typeId = 61;

  @override
  String? get schemaFingerprint =>
      '797255a8a9ef6e478dd1af938669820f62b14c9f193c43df2f2ad19ab8612eae';

  @override
  PositionalCollections read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // items (index 0)
    final raw_items = reader.read();
    final List<PositionalItem> res_items;
    try {
      res_items = castStored<List<dynamic>>(
        raw_items,
      ).map<PositionalItem>((e0) => castStored<PositionalItem>(e0)).toList();
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalCollections',
        fieldName: 'items',
        reason:
            'stored ${raw_items.runtimeType} does not match List<PositionalItem>',
      );
    }
    // scores (index 1)
    final raw_scores = reader.read();
    final Map<String, int>? res_scores;
    try {
      res_scores = raw_scores == null
          ? null
          : castStored<Map<dynamic, dynamic>>(raw_scores).map<String, int>(
              (k0, v0) => MapEntry(castStored<String>(k0), castStored<int>(v0)),
            );
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalCollections',
        fieldName: 'scores',
        reason:
            'stored ${raw_scores.runtimeType} does not match Map<String, int>?',
      );
    }
    // tags (index 2)
    final raw_tags = reader.read();
    final Set<String> res_tags;
    try {
      res_tags = castStored<Iterable<dynamic>>(
        raw_tags,
      ).map<String>((e0) => castStored<String>(e0)).toSet();
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalCollections',
        fieldName: 'tags',
        reason: 'stored ${raw_tags.runtimeType} does not match Set<String>',
      );
    }
    // grid (index 3)
    final raw_grid = reader.read();
    final List<List<PositionalItem>> res_grid;
    try {
      res_grid = castStored<List<dynamic>>(raw_grid)
          .map<List<PositionalItem>>(
            (e0) => castStored<List<dynamic>>(e0)
                .map<PositionalItem>((e1) => castStored<PositionalItem>(e1))
                .toList(),
          )
          .toList();
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalCollections',
        fieldName: 'grid',
        reason:
            'stored ${raw_grid.runtimeType} does not match List<List<PositionalItem>>',
      );
    }
    // hooked (index 4)
    final raw_hooked = reader.read();
    final ctx_hooked = PHiveCtx()..value = raw_hooked;
    applyMetadata(ctx_hooked, metadata_header.metadataForField('hooked'));
    applyMetadata(ctx_hooked, metadata_header.globalMetadata);
    runPreRead(const [PassThroughHook()], ctx_hooked);
    runPostRead(const [PassThroughHook()], ctx_hooked);
    final List<PositionalItem> res_hooked;
    try {
      res_hooked = castStored<List<dynamic>>(
        ctx_hooked.value,
      ).map<PositionalItem>((e0) => castStored<PositionalItem>(e0)).toList();
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PositionalCollections',
        fieldName: 'hooked',
        reason:
            'stored ${ctx_hooked.value.runtimeType} does not match List<PositionalItem>',
      );
    }
    return PositionalCollections(
      items: res_items,
      scores: res_scores,
      tags: res_tags,
      grid: res_grid,
      hooked: res_hooked,
    );
  }

  @override
  void write(BinaryWriter writer, PositionalCollections obj) {
    final global_metadata = const <String, dynamic>{};
    // hooked (index 4)
    final ctx_hooked = PHiveCtx()..value = obj.hooked;
    runPreWrite(const [PassThroughHook()], ctx_hooked);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_hooked.pendingMetadata.isNotEmpty)
          'hooked': Map<String, dynamic>.from(ctx_hooked.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(obj.items);
    writer.write(obj.scores);
    writer.write(obj.tags);
    writer.write(obj.grid);
    writer.write(ctx_hooked.value);
    runPostWrite(const [PassThroughHook()], ctx_hooked);
  }
}
