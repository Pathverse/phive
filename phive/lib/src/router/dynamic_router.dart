import 'package:hive_ce/hive.dart';

import 'router.dart';

/// A [PHiveRouter] implementation where types and refs are registered at runtime.
///
/// Each registered type gets its own [Box<T>]. Ref stores use a shared
/// [Box<dynamic>] per relationship, storing [List<String>] values keyed by
/// the parent's primary key.
///
/// Better for use-cases where the full type set is not known at compile time
/// (e.g., feature-flagged models, plugin architectures).
///
/// For web-optimised, compile-time-known type sets, prefer [PHiveStaticRouter].
class PHiveDynamicRouter implements PHiveRouter {
  final Map<Type, PHiveTypeRegistration> _types = {};
  final List<PHiveRefRegistration> _refs = [];

  /// Cache of open boxes, keyed by box name.
  final Map<String, BoxBase<dynamic>> _boxCache = {};

  // ── Registration ───────────────────────────────────────────────────────────

  @override
  void register<T>({
    required String Function(T item) primaryKey,
    String? boxName,
  }) {
    _types[T] = PHiveTypeRegistration(
      primaryKey: (dynamic item) => primaryKey(item as T),
      boxName: boxName ?? T.toString().toLowerCase(),
    );
  }

  @override
  void createRef<T, P>({
    required String Function(T item) resolve,
    String? refBoxName,
  }) {
    final name = refBoxName ?? '__ref_${P}_$T';
    _refs.add(PHiveRefRegistration(
      childType: T,
      parentType: P,
      resolve: (dynamic item) => resolve(item as T),
      refBoxName: name,
    ));
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  PHiveTypeRegistration _requireRegistration<T>() {
    final reg = _types[T];
    if (reg == null) {
      throw StateError(
        'Type $T is not registered with this PHiveDynamicRouter. '
        'Call register<$T>() before using it.',
      );
    }
    return reg;
  }

  Future<Box<T>> _openBox<T>(String boxName) async {
    final cached = _boxCache[boxName];
    if (cached != null && cached.isOpen) return cached as Box<T>;
    final box = await Hive.openBox<T>(boxName);
    _boxCache[boxName] = box;
    return box;
  }

  Future<Box<dynamic>> _openRefBox(String refBoxName) async {
    final cacheKey = '__ref_box__$refBoxName';
    final cached = _boxCache[cacheKey];
    if (cached != null && cached.isOpen) return cached as Box<dynamic>;
    final box = await Hive.openBox<dynamic>(refBoxName);
    _boxCache[cacheKey] = box;
    return box;
  }

  List<String> _readRefList(Box<dynamic> refBox, String parentKey) {
    final raw = refBox.get(parentKey);
    if (raw == null) return <String>[];
    return List<String>.from(raw as List);
  }

  // ── PHiveRouter implementation ─────────────────────────────────────────────

  @override
  Future<void> store<T>(T item) async {
    final reg = _requireRegistration<T>();
    final box = await _openBox<T>(reg.boxName);
    final key = reg.primaryKey(item);
    await box.put(key, item);

    // Update every ref store where T is the child type.
    for (final ref in _refs.where((r) => r.childType == T)) {
      final parentKey = ref.resolve(item);
      final refBox = await _openRefBox(ref.refBoxName);
      final keys = _readRefList(refBox, parentKey);
      if (!keys.contains(key)) {
        keys.add(key);
        await refBox.put(parentKey, keys);
      }
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    final reg = _requireRegistration<T>();
    final box = await _openBox<T>(reg.boxName);
    return box.get(key);
  }

  @override
  Future<void> delete<T>(String key) async {
    final reg = _requireRegistration<T>();
    final box = await _openBox<T>(reg.boxName);
    await box.delete(key);
    // Intentionally does not clean ref stores.
    // Use deleteContainer / deleteWithChildren for cascade behaviour.
  }

  @override
  PHiveContainerHandle<T> containerOf<T, P>(P parent) {
    final parentReg = _requireRegistration<P>();
    final parentKey = parentReg.primaryKey(parent);

    final ref = _refs.firstWhere(
      (r) => r.childType == T && r.parentType == P,
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
    final refBox = await _openRefBox(handle.refBoxName);
    final keys = _readRefList(refBox, handle.parentKey);
    if (keys.isEmpty) return [];

    final reg = _requireRegistration<T>();
    final box = await _openBox<T>(reg.boxName);

    final results = <T>[];
    for (final key in keys) {
      final item = box.get(key);
      if (item != null) results.add(item);
    }
    return results;
  }

  @override
  Future<void> deleteContainer<T>(PHiveContainerHandle<T> handle) async {
    final refBox = await _openRefBox(handle.refBoxName);
    final keys = _readRefList(refBox, handle.parentKey);

    if (keys.isNotEmpty) {
      final reg = _requireRegistration<T>();
      final box = await _openBox<T>(reg.boxName);
      for (final key in keys) {
        await box.delete(key);
      }
    }

    await refBox.delete(handle.parentKey);
  }

  @override
  Future<void> deleteWithChildren<T>(T item) async {
    final reg = _requireRegistration<T>();
    final primaryKey = reg.primaryKey(item);

    // Cascade into every ref where T is the parent type.
    final childRefs = _refs.where((r) => r.parentType == T).toList();
    for (final ref in childRefs) {
      final refBox = await _openRefBox(ref.refBoxName);
      final childKeys = _readRefList(refBox, primaryKey);

      if (childKeys.isNotEmpty) {
        final childReg = _types[ref.childType];
        if (childReg != null) {
          final childBox = await _openBox<dynamic>(childReg.boxName);
          for (final childKey in childKeys) {
            await childBox.delete(childKey);
          }
        }
      }

      await refBox.delete(primaryKey);
    }

    // Delete the parent item itself.
    final box = await _openBox<T>(reg.boxName);
    await box.delete(primaryKey);
  }

  @override
  Future<void> ensureOpen() async {
    for (final reg in _types.values) {
      await _openBox<dynamic>(reg.boxName);
    }
    for (final ref in _refs) {
      await _openRefBox(ref.refBoxName);
    }
  }
}
