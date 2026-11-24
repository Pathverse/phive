import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../exception.dart';
import '../policy.dart';
import 'router.dart';

/// Shared routing operations over the two Hive storage backends.
abstract class PHiveBaseRouter implements PHiveRouter {
  /// Creates a router whose registrations default to [driftPolicy].
  PHiveBaseRouter({this.driftPolicy = PHiveDriftPolicy.propagate});

  /// Drift policy applied to registrations that do not supply their own.
  final PHiveDriftPolicy driftPolicy;

  final _types = <Type, PHiveTypeRegistration>{};
  final _refs = <PHiveRefRegistration>[];

  Iterable<PHiveTypeRegistration> get typeRegistrations => _types.values;
  Iterable<String> get refBoxNames => _refs.map((ref) => ref.refBoxName);

  void checkRegistration(String operation) {}
  Future<BoxBase<dynamic>> openRegisteredBox<T>(String name);
  Future<void> writePrimary<T>(PHiveTypeRegistration reg, String key, T item);
  Future<T?> readPrimary<T>(PHiveTypeRegistration reg, String key);
  Future<List<T>> readAllPrimary<T>(PHiveTypeRegistration reg);
  Future<void> deletePrimary(PHiveTypeRegistration reg, Iterable<String> keys);
  Future<void> clearPrimary(PHiveTypeRegistration reg);
  Future<Map<String, List<String>>> readRefMemberships(String name);
  Future<List<String>> readRefList(String name, String parentKey);
  Future<void> writeRefList(String name, String parentKey, List<String> keys);
  Future<void> deleteRefEntry(String name, String parentKey);
  Future<void> clearRefBox(String name);

  @override
  void register<T>({
    required String Function(T item) primaryKey,
    String? boxName,
    PHiveDriftPolicy? driftPolicy,
  }) {
    checkRegistration('register types');
    final name = boxName ?? T.toString().toLowerCase();
    _types[T] = PHiveTypeRegistration(
      primaryKey: (dynamic item) => primaryKey(item as T),
      boxName: name,
      openBox: () => openRegisteredBox<T>(name),
      driftPolicy: driftPolicy ?? this.driftPolicy,
    );
  }

  @override
  void createRef<T, P>({
    required String Function(T item) resolve,
    String? refBoxName,
  }) {
    checkRegistration('register refs');
    _refs.add(
      PHiveRefRegistration(
        childType: T,
        parentType: P,
        resolve: (dynamic item) => resolve(item as T),
        refBoxName: refBoxName ?? '__ref_${P}_$T',
      ),
    );
  }

  PHiveTypeRegistration _requireRegistration<T>() {
    final reg = _types[T];
    if (reg == null) {
      throw StateError('Type $T is not registered. Call register<$T>() first.');
    }
    return reg;
  }

  @override
  Future<void> store<T>(T item) async {
    final reg = _requireRegistration<T>();
    final key = reg.primaryKey(item);
    await writePrimary(reg, key, item);

    // The previous primary value can be expired or missing.
    for (final ref in _refs.where((ref) => ref.childType == T)) {
      final parentKey = ref.resolve(item);
      final name = ref.refBoxName;
      final memberships = await readRefMemberships(name);
      for (final entry in memberships.entries) {
        final previousParent = entry.key;
        if (previousParent == parentKey) continue;
        final keys = entry.value;
        if (!keys.contains(key)) continue;
        keys.removeWhere((candidate) => candidate == key);
        if (keys.isEmpty) {
          await deleteRefEntry(name, previousParent);
        } else {
          await writeRefList(name, previousParent, keys);
        }
      }
      final keys = memberships[parentKey] ?? <String>[];
      if (keys.where((candidate) => candidate == key).length != 1) {
        keys.removeWhere((candidate) => candidate == key);
        keys.add(key);
        await writeRefList(name, parentKey, keys);
      }
    }
  }

  Future<(T?, bool)> readWithPolicy<T>(
    PHiveTypeRegistration reg,
    String key,
    FutureOr<T?> Function() read,
  ) async {
    try {
      return (await read(), false);
    } on PHiveSchemaDriftException {
      if (reg.driftPolicy != PHiveDriftPolicy.deleteAndMiss) rethrow;
      await deletePrimary(reg, [key]);
      return (null, false);
    } on HiveError catch (error) {
      if (reg.driftPolicy != PHiveDriftPolicy.deleteAndMiss ||
          !isUnknownTypeIdError(error)) {
        rethrow;
      }
      await deletePrimary(reg, [key]);
      return (null, false);
    } on PHiveActionException catch (error) {
      final cleared = error.behaviors.contains(PHiveActionBehavior.clearBox);
      if (cleared) {
        await clearPrimary(reg);
      }
      if (error.behaviors.contains(PHiveActionBehavior.deleteEntry)) {
        await deletePrimary(reg, [key]);
      }
      if (error.behaviors.contains(PHiveActionBehavior.returnNull)) {
        return (null, cleared);
      }
      rethrow;
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    final reg = _requireRegistration<T>();
    final (item, _) = await readWithPolicy(
      reg,
      key,
      () => readPrimary<T>(reg, key),
    );
    return item;
  }

  @override
  Future<List<T>> getAll<T>() async =>
      readAllPrimary<T>(_requireRegistration<T>());

  Future<List<T>> readKeys<T>(
    PHiveTypeRegistration reg,
    Iterable<String> keys,
  ) async {
    final items = <T>[];
    for (final key in keys) {
      final (item, cleared) = await readWithPolicy(
        reg,
        key,
        () => readPrimary<T>(reg, key),
      );
      if (cleared) break;
      if (item != null) items.add(item);
    }
    return items;
  }

  @override
  Future<void> delete<T>(String key) async =>
      deletePrimary(_requireRegistration<T>(), [key]);

  @override
  Future<void> clear() async {
    for (final reg in typeRegistrations) {
      await clearPrimary(reg);
    }
    for (final name in refBoxNames) {
      await clearRefBox(name);
    }
  }

  @override
  Future<void> clearType<T>() async => clearPrimary(_requireRegistration<T>());

  @override
  PHiveContainerHandle<T> containerOf<T, P>(P parent) {
    final reg = _requireRegistration<P>();
    final parentKey = reg.primaryKey(parent);
    final ref = _refs.firstWhere(
      (ref) => ref.childType == T && ref.parentType == P,
      orElse: () => throw StateError(
        'No ref registered for child type $T with parent type $P. '
        'Call createRef<$T, $P>() first.',
      ),
    );
    return PHiveContainerHandle<T>(
      refBoxName: ref.refBoxName,
      parentKey: parentKey,
    );
  }

  @override
  Future<List<T>> getContainer<T>(PHiveContainerHandle<T> handle) async {
    final keys = await readRefList(handle.refBoxName, handle.parentKey);
    if (keys.isEmpty) return [];
    return readKeys<T>(_requireRegistration<T>(), keys);
  }

  @override
  Future<void> deleteContainer<T>(PHiveContainerHandle<T> handle) async {
    final keys = await readRefList(handle.refBoxName, handle.parentKey);
    if (keys.isNotEmpty) {
      await deletePrimary(_requireRegistration<T>(), keys);
    }
    await deleteRefEntry(handle.refBoxName, handle.parentKey);
  }

  @override
  Future<void> deleteWithChildren<T>(T item) async {
    final reg = _requireRegistration<T>();
    await _deleteWithDescendants(T, reg.primaryKey(item), {});
  }

  Future<void> _deleteWithDescendants(
    Type type,
    String key,
    Set<(Type, String)> visited,
  ) async {
    if (!visited.add((type, key))) return;

    final relationships = _refs.where((ref) => ref.parentType == type).toList();
    for (final ref in relationships) {
      final childKeys = await readRefList(ref.refBoxName, key);
      for (final childKey in childKeys) {
        await _deleteWithDescendants(ref.childType, childKey, visited);
      }
      await deleteRefEntry(ref.refBoxName, key);
    }

    final reg = _types[type];
    if (reg != null) await deletePrimary(reg, [key]);
  }
}

/// Whether [error] is Hive CE's unknown type-identifier read error.
///
/// Hive CE exposes no typed error for this case, so the message prefix is
/// matched. A contract test pins it across the supported Hive CE range; if the
/// wording changes, detection fails safe and the error propagates.
bool isUnknownTypeIdError(HiveError error) =>
    error.message.trimLeft().startsWith('Cannot read, unknown typeId:');
