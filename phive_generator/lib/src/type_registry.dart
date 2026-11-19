import 'dart:convert';

/// Immutable mapping of Dart class names to their assigned Hive type identifiers.
///
/// The registry is the authoritative source of typeId assignments for
/// [PHiveAutoType]-annotated classes.  It is persisted to
/// `phive_type_registry.json` in the package root and committed to version
/// control so that `build_runner` can read it as a stable input.
///
/// Hive CE supports user-defined identifiers from 0 through 65439.
class TypeIdRegistry {
  static const int minUserTypeId = 0;
  static const int maxUserTypeId = 65439;

  final Map<String, int> _assignments;

  /// Creates a registry and validates the assignments.
  ///
  /// Prefer the named constructors [fromJson] and [empty] at call sites.
  TypeIdRegistry(Map<String, int> assignments)
    : _assignments = Map.unmodifiable(assignments) {
    final namesById = <int, String>{};
    for (final entry in _assignments.entries) {
      _validateId(entry.value);
      final previous = namesById[entry.value];
      if (previous != null) {
        throw StateError(
          'Duplicate typeId ${entry.value} for "$previous" and "${entry.key}".',
        );
      }
      namesById[entry.value] = entry.key;
    }
  }

  static void _validateId(int id) {
    if (id < minUserTypeId || id > maxUserTypeId) {
      throw StateError('TypeId $id must be in $minUserTypeId..$maxUserTypeId.');
    }
  }

  /// Creates an empty registry with no assignments.
  factory TypeIdRegistry.empty() => TypeIdRegistry({});

  /// Parses a JSON object string into a [TypeIdRegistry].
  ///
  /// Throws [FormatException] when [source] is not valid JSON, when the root
  /// value is not a JSON object, or when any value is not an integer.
  factory TypeIdRegistry.fromJson(String source) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      throw FormatException('Registry source is not valid JSON.', source);
    }

    if (decoded is! Map) {
      throw FormatException(
        'Registry JSON root must be an object, got ${decoded.runtimeType}.',
        source,
      );
    }

    final assignments = <String, int>{};
    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is! int) {
        throw FormatException(
          'Registry value for "${entry.key}" must be an integer, '
          'got ${value.runtimeType}.',
          source,
        );
      }
      assignments[entry.key as String] = value;
    }

    try {
      return TypeIdRegistry(assignments);
    } on StateError catch (error) {
      throw FormatException(error.message, source);
    }
  }

  // ── Queries ──────────────────────────────────────────────────────────────────

  /// Returns the typeId assigned to [className].
  ///
  /// Throws [StateError] if [className] is not registered.  Callers should
  /// check [contains] first when the absence of a class is an expected
  /// condition (e.g. in CLI scan loops).
  int lookupTypeId(String className) {
    final id = _assignments[className];
    if (id == null) {
      throw StateError(
        '"$className" is not in the phive type registry.  '
        'Run the assign_type_ids CLI tool to register it.',
      );
    }
    return id;
  }

  /// Returns true if [className] has an assigned typeId.
  bool contains(String className) => _assignments.containsKey(className);

  /// Returns the lowest available typeId at or above [startAt].
  ///
  /// The result is `max(startAt, maxAssignedId + 1)` when the registry is
  /// non-empty, or [startAt] when it is empty.
  int nextAvailableId({int startAt = 0}) {
    if (_assignments.isEmpty) {
      return startAt;
    }
    final maxId = _assignments.values.reduce((a, b) => a > b ? a : b);
    return maxId + 1 > startAt ? maxId + 1 : startAt;
  }

  /// Whether the registry contains no assignments.
  bool get isEmpty => _assignments.isEmpty;

  /// Whether the registry contains at least one assignment.
  bool get isNotEmpty => _assignments.isNotEmpty;

  // ── Mutations (return new instances) ─────────────────────────────────────────

  /// Returns a new registry with [className] assigned the next available id.
  ///
  /// The next id is computed from [nextAvailableId] with the given [startAt]
  /// floor.  Throws [StateError] if [className] is already registered.
  TypeIdRegistry assign(String className, {int startAt = 0}) {
    if (contains(className)) {
      throw StateError(
        '"$className" is already in the phive type registry '
        '(typeId ${_assignments[className]}).  '
        'Use lookupTypeId to retrieve it.',
      );
    }
    _validateId(startAt);
    final newId = nextAvailableId(startAt: startAt);
    if (newId > maxUserTypeId) {
      throw StateError('No sequential typeId remains for "$className".');
    }
    return TypeIdRegistry({..._assignments, className: newId});
  }

  /// Returns a new registry with all [classNames] that are not yet registered
  /// assigned sequential ids.  Already-registered names are skipped.
  TypeIdRegistry assignAll(Iterable<String> classNames, {int startAt = 0}) {
    var current = this;
    for (final name in classNames) {
      if (!current.contains(name)) {
        current = current.assign(name, startAt: startAt);
      }
    }
    return current;
  }

  // ── Serialisation ────────────────────────────────────────────────────────────

  /// Serialises the registry to a pretty-printed JSON string.
  ///
  /// The output is deterministic: entries are sorted by typeId so the diff
  /// is readable when new classes are added.
  String toJson() {
    final sorted = Map.fromEntries(
      _assignments.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
    );
    return const JsonEncoder.withIndent('  ').convert(sorted);
  }
}
