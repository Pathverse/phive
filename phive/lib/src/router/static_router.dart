// ignore_for_file: implementation_imports

import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
import 'package:hive_ce/src/binary/binary_writer_impl.dart';

import 'base_router.dart';
import 'router.dart';

/// A [PHiveRouter] implementation backed by Hive CE's [BoxCollection] API.
///
/// ## Storage strategy
/// All registered types and ref stores live inside a single [BoxCollection]
/// (one physical Hive database). On web this maps to **one IndexedDB database**
/// with multiple object stores — dramatically cheaper than opening many
/// independent boxes. On native it is a single directory with multiple files.
///
/// ## Registration window
/// Types and refs MUST be registered before the first [ensureOpen] call using
/// [register] and [createRef], exactly as with [PHiveDynamicRouter].
/// Once [ensureOpen] is called, [BoxCollection.open] is invoked with the full
/// set of box names. After that point the schema is **frozen** — [register]
/// and [createRef] throw [StateError] because [BoxCollection] cannot accept
/// new stores after it has been opened.
///
/// ## Typical setup
/// ```dart
/// final router = PHiveStaticRouter()
///   ..register<Lesson>(primaryKey: (l) => l.lessonId)
///   ..register<Card>(primaryKey: (c) => c.cardId)
///   ..createRef<Card, Lesson>(resolve: (c) => c.lessonId);
///
/// await router.ensureOpen();   // opens BoxCollection — schema now frozen
/// await router.store(lesson);
/// ```
///
/// ## Web / TypeAdapter note
/// `CollectionBox` on web stores JSON values and does not automatically route
/// non-primitive payloads through Hive adapters. PHiveStaticRouter therefore
/// serialises every primary and ref payload into a primitive base64 string
/// using Hive's binary reader/writer path before handing it to BoxCollection.
/// This preserves generated adapter behavior, including PHive hook execution,
/// across native and web storage backends.
class PHiveStaticRouter extends PHiveBaseRouter {
  static const _usesIndexedDb = bool.fromEnvironment('dart.library.js_interop');

  /// Name of the [BoxCollection].
  final String collectionName;

  /// Optional filesystem path for the collection on native platforms.
  final String? path;

  final Map<String, CollectionBox<String>> _boxCache = {};
  BoxCollection? _collection;

  /// Creates a static router whose registrations default to [driftPolicy].
  PHiveStaticRouter({
    this.collectionName = 'phive_static',
    this.path,
    super.driftPolicy,
  });

  @override
  void checkRegistration(String operation) {
    if (_collection != null) {
      throw StateError(
        'Cannot $operation after PHiveStaticRouter has been opened. '
        'All types and refs must be registered before calling ensureOpen().',
      );
    }
  }

  @override
  Future<BoxBase<dynamic>> openRegisteredBox<T>(String name) =>
      Hive.openBox<T>(name);

  @override
  Future<void> ensureOpen() async {
    if (_collection != null) return;
    _collection = await BoxCollection.open(collectionName, {
      for (final reg in typeRegistrations) reg.boxName,
      ...refBoxNames,
    }, path: path);
  }

  /// Returns one open storage box that holds primitive string payloads.
  Future<CollectionBox<String>> _getBox(String boxName) async {
    final cached = _boxCache[boxName];
    if (cached != null) return cached;
    if (_collection == null) {
      throw StateError(
        'PHiveStaticRouter is not open. Call ensureOpen() first.',
      );
    }
    final box = await _collection!.openBox<String>(boxName);
    _boxCache[boxName] = box;
    return box;
  }

  /// Serializes one value through Hive's adapter pipeline into base64 text.
  String _encodeValue(Object? value) {
    final writer = BinaryWriterImpl(Hive);
    writer.write(value);
    return base64Encode(writer.toBytes());
  }

  /// Deserializes one base64 payload through Hive's adapter pipeline.
  T? _decodeValue<T>(String? payload) {
    if (payload == null) return null;
    final reader = BinaryReaderImpl(base64Decode(payload), Hive);
    return reader.read() as T?;
  }

  /// Reads one ref payload and normalizes it into a string list.
  List<String> _parseRefList(String? raw) {
    final decoded = _decodeValue<List<dynamic>>(raw);
    if (decoded == null) return <String>[];
    return decoded.cast<String>();
  }

  @override
  Future<void> writePrimary<T>(
    PHiveTypeRegistration reg,
    String key,
    T item,
  ) async {
    await (await _getBox(reg.boxName)).put(key, _encodeValue(item));
  }

  @override
  Future<T?> readPrimary<T>(PHiveTypeRegistration reg, String key) async =>
      _decodeValue<T>(await (await _getBox(reg.boxName)).get(key));

  @override
  Future<List<T>> readAllPrimary<T>(PHiveTypeRegistration reg) async {
    final payloads = await _readAllPayloads(reg.boxName);
    final items = <T>[];
    for (final entry in payloads.entries) {
      final (item, cleared) = await readWithPolicy(
        reg,
        entry.key,
        () => _decodeValue<T>(entry.value),
      );
      // The snapshot still contains records removed by the hook.
      if (cleared) break;
      if (item != null) items.add(item);
    }
    return items;
  }

  Future<Map<String, String>> _readAllPayloads(String name) async {
    final box = await _getBox(name);
    final values = await box.getAllValues();
    if (_usesIndexedDb) return values;

    // Native Hive can return hashed backing keys from getAllValues().
    // Resolve the public keys before using them in writes or read policies.
    final keys = await box.getAllKeys();
    if (keys.length == values.length && keys.every(values.containsKey)) {
      return values;
    }
    final resolved = await box.getAll(keys);
    return {for (var i = 0; i < keys.length; i++) keys[i]: ?resolved[i]};
  }

  @override
  Future<void> deletePrimary(
    PHiveTypeRegistration reg,
    Iterable<String> keys,
  ) async {
    final box = await _getBox(reg.boxName);
    for (final key in keys) {
      await box.delete(key);
    }
  }

  @override
  Future<void> clearPrimary(PHiveTypeRegistration reg) async {
    await (await _getBox(reg.boxName)).clear();
  }

  @override
  Future<Map<String, List<String>>> readRefMemberships(String name) async =>
      (await _readAllPayloads(
        name,
      )).map((key, payload) => MapEntry(key, _parseRefList(payload)));

  @override
  Future<List<String>> readRefList(String name, String parentKey) async {
    final box = await _getBox(name);
    // IndexedDB keyed reads can return a previous router's local snapshot.
    final payload = _usesIndexedDb
        ? (await box.getAllValues())[parentKey]
        : await box.get(parentKey);
    return _parseRefList(payload);
  }

  @override
  Future<void> writeRefList(
    String name,
    String parentKey,
    List<String> keys,
  ) async {
    await (await _getBox(name)).put(parentKey, _encodeValue(keys));
  }

  @override
  Future<void> deleteRefEntry(String name, String parentKey) async {
    await (await _getBox(name)).delete(parentKey);
  }

  @override
  Future<void> clearRefBox(String name) async {
    await (await _getBox(name)).clear();
  }
}
