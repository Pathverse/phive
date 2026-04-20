// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
import 'package:hive_ce/src/binary/binary_writer_impl.dart';

import '../exception.dart';
import '../policy.dart';
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
class PHiveStaticRouter implements PHiveRouter {
  /// Name of the [BoxCollection] (= IndexedDB database name on web).
  final String collectionName;

  /// Optional filesystem path for the collection on native platforms.
  /// Defaults to null, in which case the path set by [Hive.init] /
  /// [Hive.initFlutter] is used.
  final String? path;

  final Map<Type, PHiveTypeRegistration> _types = {};
  final List<PHiveRefRegistration> _refs = [];
  final Map<String, CollectionBox<String>> _boxCache = {};

  BoxCollection? _collection;
  bool _isOpen = false;

  PHiveStaticRouter({
    this.collectionName = 'phive_static',
    this.path,
  });

  // ── Registration guard ────────────────────────────────────────────────────

  void _assertMutable(String op) {
    if (_isOpen) {
      throw StateError(
        'Cannot $op after PHiveStaticRouter has been opened. '
        'All types and refs must be registered before calling ensureOpen().',
      );
    }
  }

  // ── Registration ──────────────────────────────────────────────────────────

  @override
  /// Registers one type in the static router before the collection is opened.
  void register<T>({
    required String Function(T item) primaryKey,
    String? boxName,
  }) {
    _assertMutable('register types');
    final resolvedBoxName = boxName ?? T.toString().toLowerCase();
    _types[T] = PHiveTypeRegistration(
      primaryKey: (dynamic item) => primaryKey(item as T),
      boxName: resolvedBoxName,
      openBox: () => Hive.openBox<T>(resolvedBoxName),
    );
  }

  @override
  void createRef<T, P>({
    required String Function(T item) resolve,
    String? refBoxName,
  }) {
    _assertMutable('register refs');
    final name = refBoxName ?? '__ref_${P}_$T';
    _refs.add(PHiveRefRegistration(
      childType: T,
      parentType: P,
      resolve: (dynamic item) => resolve(item as T),
      refBoxName: name,
    ));
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  PHiveTypeRegistration _requireRegistration<T>() {
    final reg = _types[T];
    if (reg == null) {
      throw StateError(
        'Type $T is not registered with this PHiveStaticRouter. '
        'Call register<$T>() before calling ensureOpen().',
      );
    }
    return reg;
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
    final bytes = Uint8List.fromList(base64Decode(payload));
    final reader = BinaryReaderImpl(bytes, Hive);
    return reader.read() as T?;
  }

  /// Reads one ref payload and normalizes it into a string list.
  List<String> _parseRefList(String? raw) {
    final decoded = _decodeValue<List<dynamic>>(raw);
    if (decoded == null) return <String>[];
    return decoded.cast<String>();
  }

  /// Applies one hook-driven read exception to the current static box state.
  Future<T?> _handleReadException<T>(
    CollectionBox<String> box,
    String key,
    PHiveActionException error,
  ) async {
    if (error.behaviors.contains(PHiveActionBehavior.clearBox)) {
      await box.clear();
    }
    if (error.behaviors.contains(PHiveActionBehavior.deleteEntry)) {
      await box.delete(key);
    }
    if (error.behaviors.contains(PHiveActionBehavior.returnNull)) {
      return null;
    }
    throw error;
  }

  /// Reads one primary value and applies composable exception behaviors.
  Future<T?> _readPrimaryValue<T>(PHiveTypeRegistration reg, String key) async {
    final box = await _getBox(reg.boxName);
    try {
      final raw = await box.get(key);
      return _decodeValue<T>(raw);
    } on PHiveActionException catch (error) {
      return _handleReadException(box, key, error);
    }
  }

  // ── PHiveRouter implementation ────────────────────────────────────────────

  /// Opens the [BoxCollection] with all registered box names.
  ///
  /// After this call the schema is frozen — [register] and [createRef] will
  /// throw [StateError]. Subsequent calls to [ensureOpen] are no-ops.
  @override
  Future<void> ensureOpen() async {
    if (_isOpen) return;

    // Collect every box name that needs to exist in the collection.
    final boxNames = <String>{};
    for (final reg in _types.values) {
      boxNames.add(reg.boxName);
    }
    for (final ref in _refs) {
      boxNames.add(ref.refBoxName);
    }

    _collection = await BoxCollection.open(
      collectionName,
      boxNames,
      path: path,
    );
    _isOpen = true;
  }

  @override
  Future<void> store<T>(T item) async {
    final reg = _requireRegistration<T>();
    final box = await _getBox(reg.boxName);
    final key = reg.primaryKey(item);
    await box.put(key, _encodeValue(item));

    // Update every ref store where T is the child type.
    for (final ref in _refs.where((r) => r.childType == T)) {
      final parentKey = ref.resolve(item);
      final refBox = await _getBox(ref.refBoxName);
      final keys = _parseRefList(await refBox.get(parentKey));
      if (!keys.contains(key)) {
        keys.add(key);
        await refBox.put(parentKey, _encodeValue(keys));
      }
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    final reg = _requireRegistration<T>();
    return _readPrimaryValue<T>(reg, key);
  }

  @override
  Future<void> delete<T>(String key) async {
    final reg = _requireRegistration<T>();
    final box = await _getBox(reg.boxName);
    await box.delete(key);
  }

  @override
  PHiveContainerHandle<T> containerOf<T, P>(P parent) {
    final parentReg = _requireRegistration<P>();
    final parentKey = parentReg.primaryKey(parent);

    final ref = _refs.firstWhere(
      (r) => r.childType == T && r.parentType == P,
      orElse: () => throw StateError(
        'No ref registered for child type $T with parent type $P. '
        'Call createRef<$T, $P>() before calling ensureOpen().',
      ),
    );

    return PHiveContainerHandle<T>(
      refBoxName: ref.refBoxName,
      parentKey: parentKey,
    );
  }

  @override
  Future<List<T>> getContainer<T>(PHiveContainerHandle<T> handle) async {
    final refBox = await _getBox(handle.refBoxName);
    final keys = _parseRefList(await refBox.get(handle.parentKey));
    if (keys.isEmpty) return [];

    final reg = _requireRegistration<T>();

    final results = <T>[];
    for (final key in keys) {
      final item = await _readPrimaryValue<T>(reg, key);
      if (item != null) results.add(item);
    }
    return results;
  }

  @override
  Future<void> deleteContainer<T>(PHiveContainerHandle<T> handle) async {
    final refBox = await _getBox(handle.refBoxName);
    final keys = _parseRefList(await refBox.get(handle.parentKey));

    if (keys.isNotEmpty) {
      final reg = _requireRegistration<T>();
      final box = await _getBox(reg.boxName);
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

    final childRefs = _refs.where((r) => r.parentType == T).toList();
    for (final ref in childRefs) {
      final refBox = await _getBox(ref.refBoxName);
      final childKeys = _parseRefList(await refBox.get(primaryKey));

      if (childKeys.isNotEmpty) {
        final childReg = _types[ref.childType];
        if (childReg != null) {
          final childBox = await _getBox(childReg.boxName);
          for (final childKey in childKeys) {
            await childBox.delete(childKey);
          }
        }
      }
      await refBox.delete(primaryKey);
    }

    final box = await _getBox(reg.boxName);
    await box.delete(primaryKey);
  }
}
