import 'package:hive_ce/hive.dart';

import 'exception.dart';

/// Adapter registered under a retired type ID. Reading raises schema drift;
/// writing is rejected. Register through [registerPHiveTombstone].
class PHiveTombstoneAdapter<T> extends TypeAdapter<T> {
  /// Creates an adapter for the retired [typeId].
  const PHiveTombstoneAdapter(this.typeId);

  @override
  final int typeId;

  @override
  T read(BinaryReader reader) => throw PHiveSchemaDriftException(
    typeName: 'retired type $typeId',
    reason: 'type ID $typeId is retired in this build',
  );

  @override
  void write(BinaryWriter writer, T obj) =>
      throw StateError('Type ID $typeId is retired and cannot be written.');
}

/// Registers a tombstone for [typeId] using marker type [T], unless an
/// adapter is already registered for [typeId]. Returns whether it registered.
/// Each tombstone needs its own marker type [T] to avoid Hive CE's
/// duplicate-type warning; generated registration provides one per ID.
bool registerPHiveTombstone<T>(int typeId, {HiveInterface? hive}) {
  final target = hive ?? Hive;
  if (target.isAdapterRegistered(typeId)) return false;
  target.registerAdapter<T>(PHiveTombstoneAdapter<T>(typeId));
  return true;
}
