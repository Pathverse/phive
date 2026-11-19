import 'package:hive_ce/hive.dart';

import 'base_router.dart';
import 'router.dart';

/// A [PHiveRouter] implementation where types and refs are registered at runtime.
///
/// Each registered type gets its own [LazyBox<T>] so values deserialize on
/// keyed reads instead of box open. Ref stores use a shared [Box<dynamic>] per
/// relationship, storing [List<String>] values keyed by the parent's primary
/// key.
///
/// Better for use-cases where the full type set is not known at compile time
/// (e.g., feature-flagged models, plugin architectures).
///
/// For web-optimised, compile-time-known type sets, prefer [PHiveStaticRouter].
class PHiveDynamicRouter extends PHiveBaseRouter {
  final Map<String, BoxBase<dynamic>> _primaryBoxes = {};
  final Map<String, Box<dynamic>> _refBoxes = {};

  @override
  Future<BoxBase<dynamic>> openRegisteredBox<T>(String name) =>
      Hive.openLazyBox<T>(name);

  Future<BoxBase<dynamic>> _primaryBox(PHiveTypeRegistration reg) async {
    final cached = _primaryBoxes[reg.boxName];
    if (cached != null && cached.isOpen) return cached;
    final box = await reg.openBox();
    _primaryBoxes[reg.boxName] = box;
    return box;
  }

  Future<Box<dynamic>> _refBox(String name) async {
    final cached = _refBoxes[name];
    if (cached != null && cached.isOpen) return cached;
    final box = await Hive.openBox<dynamic>(name);
    _refBoxes[name] = box;
    return box;
  }

  @override
  Future<void> ensureOpen() async {
    for (final reg in typeRegistrations) {
      await _primaryBox(reg);
    }
    for (final name in refBoxNames) {
      await _refBox(name);
    }
  }

  @override
  Future<void> writePrimary<T>(
    PHiveTypeRegistration reg,
    String key,
    T item,
  ) async {
    final box = await _primaryBox(reg) as LazyBox<T>;
    await box.put(key, item);
  }

  @override
  Future<T?> readPrimary<T>(PHiveTypeRegistration reg, String key) async {
    final box = await _primaryBox(reg) as LazyBox<T>;
    return box.get(key);
  }

  @override
  Future<List<String>> primaryKeys(PHiveTypeRegistration reg) async =>
      (await _primaryBox(reg)).keys.map((key) => key.toString()).toList();

  @override
  Future<void> deletePrimary(
    PHiveTypeRegistration reg,
    Iterable<String> keys,
  ) async {
    final box = await _primaryBox(reg);
    for (final key in keys) {
      await box.delete(key);
    }
  }

  @override
  Future<void> clearPrimary(PHiveTypeRegistration reg) async {
    await (await _primaryBox(reg)).clear();
  }

  @override
  Future<List<String>> refParentKeys(String name) async =>
      (await _refBox(name)).keys.cast<String>().toList();

  @override
  Future<List<String>> readRefList(String name, String parentKey) async {
    final raw = (await _refBox(name)).get(parentKey);
    return raw == null ? <String>[] : List<String>.from(raw as List);
  }

  @override
  Future<void> writeRefList(
    String name,
    String parentKey,
    List<String> keys,
  ) async {
    await (await _refBox(name)).put(parentKey, keys);
  }

  @override
  Future<void> deleteRefEntry(String name, String parentKey) async {
    await (await _refBox(name)).delete(parentKey);
  }

  @override
  Future<void> clearRefBox(String name) async {
    await (await _refBox(name)).clear();
  }
}
