import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

import 'metadata_observation.dart';

part 'auto_metadata.g.dart';

@PHiveAutoType(classHooks: [GlobalMarker()])
class AutoMetadata implements MetadataObservation {
  @override
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'auto_metadata')
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

  AutoMetadata({
    required this.id,
    required this.overridden,
    required this.inherited,
    required this.nullable,
  });
}
