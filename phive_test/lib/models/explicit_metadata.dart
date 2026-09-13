import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

import 'metadata_observation.dart';

part 'explicit_metadata.g.dart';

@PHiveType(11, classHooks: [GlobalMarker()])
class ExplicitMetadata implements MetadataObservation {
  @override
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'explicit_metadata')
  final String id;

  @override
  @PHiveField(1, hooks: [OverrideMarker(), ReadMarker()])
  final String overridden;

  @override
  @PHiveField(2, hooks: [ReadMarker()])
  final String inherited;

  @override
  @PHiveField(3, hooks: [NullMarker(), ReadMarker()])
  final String? nullable;

  @override
  String? observedGlobal;

  ExplicitMetadata({
    required this.id,
    required this.overridden,
    required this.inherited,
    required this.nullable,
  });
}
