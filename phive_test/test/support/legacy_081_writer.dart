// Verbatim generated code: keep its identifiers unchanged.
// ignore_for_file: non_constant_identifier_names

import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/positional_collections.dart';
import 'package:phive_test/models/tolerant_evolution.dart';

/// Write path of PositionalCollectionsAdapter exactly as phive_generator
/// 0.8.1 emitted it, frozen before the positional collection fix. Records it
/// writes are the bytes existing 0.8.x stores hold.
class Legacy081PositionalCollectionsWriter
    extends PTypeAdapter<PositionalCollections> {
  @override
  final int typeId = 61;

  @override
  PositionalCollections read(BinaryReader reader) =>
      throw UnsupportedError('Write-only 0.8.1 fixture');

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
