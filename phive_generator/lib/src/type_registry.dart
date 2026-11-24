import 'dart:convert';

/// Layout recorded for a registered type.
enum RegistryLayout {
  /// Fields are stored by position; the field sequence must not change under
  /// the same type identifier.
  positional,

  /// Fields are stored under persisted tags and may evolve.
  tolerant,
}

/// A named, bounded range of type identifiers scoped to library paths.
class RegistryBand {
  /// Band name; also the prefix of registry keys for classes in this band.
  final String name;

  /// Lowest identifier in the band (inclusive).
  final int start;

  /// Highest identifier in the band (inclusive).
  final int end;

  /// Package-relative POSIX path globs selecting the band's libraries.
  ///
  /// `**` matches any characters including `/`; `*` matches any characters
  /// except `/`.
  final List<String> paths;

  /// Creates a band. Validation happens when it is added to a registry.
  RegistryBand({
    required this.name,
    required this.start,
    required this.end,
    required List<String> paths,
  }) : paths = List.unmodifiable(paths);

  /// Whether [id] lies inside this band.
  bool containsId(int id) => id >= start && id <= end;

  /// Whether the package-relative [path] belongs to this band.
  bool matchesPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    return paths.any((glob) => _globToRegExp(glob).hasMatch(normalized));
  }

  Map<String, dynamic> _toJson() => {
    'start': start,
    'end': end,
    'paths': paths,
  };
}

/// Field shape recorded for one registered type.
class RegistryShape {
  /// Stored layout of the type.
  final RegistryLayout layout;

  /// Active fields and their tags (tolerant) or positions (positional).
  final Map<String, int> fields;

  /// Removed fields and the tags they held; never reassigned to another field.
  final Map<String, int> retiredFields;

  /// Positional field order recorded when an existing hooked type opted into
  /// the tolerant layout, used to read its version-2 records.
  final List<String>? positionalFields;

  /// Creates an immutable shape.
  RegistryShape({
    required this.layout,
    required Map<String, int> fields,
    Map<String, int> retiredFields = const {},
    List<String>? positionalFields,
  }) : fields = Map.unmodifiable(fields),
       retiredFields = Map.unmodifiable(retiredFields),
       positionalFields = positionalFields == null
           ? null
           : List.unmodifiable(positionalFields);

  /// Field names ordered by tag or position.
  List<String> get orderedFields =>
      (fields.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
          .map((entry) => entry.key)
          .toList();
}

/// Raised when a field shape change needs an explicit decision.
class RegistryShapeChangeError extends StateError {
  /// Registry key of the affected type.
  final String key;

  /// Creates a shape-change error for [key].
  RegistryShapeChangeError(this.key, String message) : super(message);
}

/// Immutable registry of Hive type identifiers for `@PHiveAutoType` classes.
///
/// The registry is the authoritative source of typeId assignments. It is
/// persisted to `phive_type_registry.json` in the package root and committed
/// to version control so that `build_runner` can read it as a stable input.
///
/// A registry starts in the flat format: a JSON object of class name to type
/// identifier. It moves to the versioned format (`"format": 2`) only when it
/// declares bands, retired identifiers or field shapes. A flat registry is
/// written back byte-identically.
///
/// Hive CE supports user-defined identifiers from 0 through 65439.
class TypeIdRegistry {
  static const int minUserTypeId = 0;
  static const int maxUserTypeId = 65439;

  /// Format number written for versioned registries.
  static const int versionedFormat = 2;

  final Map<String, int> _assignments;
  final Map<String, RegistryBand> _bands;
  final Map<String, RegistryShape> _shapes;
  final Map<int, String> _retired;

  /// Creates a registry and validates it.
  ///
  /// Prefer the named constructors [fromJson] and [empty] at call sites.
  TypeIdRegistry(
    Map<String, int> assignments, {
    Map<String, RegistryBand> bands = const {},
    Map<String, RegistryShape> shapes = const {},
    Map<int, String> retired = const {},
  }) : _assignments = Map.unmodifiable(assignments),
       _bands = Map.unmodifiable(bands),
       _shapes = Map.unmodifiable(shapes),
       _retired = Map.unmodifiable(retired) {
    _validate();
  }

  /// Creates an empty registry with no assignments.
  factory TypeIdRegistry.empty() => TypeIdRegistry({});

  /// Parses a flat or versioned registry JSON document.
  ///
  /// Throws [FormatException] when [source] is not valid JSON, is not an
  /// object, or describes an invalid registry.
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

    try {
      if (decoded.containsKey('format')) {
        return _fromVersioned(decoded, source);
      }
      return _fromFlat(decoded, source);
    } on StateError catch (error) {
      throw FormatException(error.message, source);
    }
  }

  static TypeIdRegistry _fromFlat(Map<dynamic, dynamic> decoded, String source) {
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
    return TypeIdRegistry(assignments);
  }

  static TypeIdRegistry _fromVersioned(
    Map<dynamic, dynamic> decoded,
    String source,
  ) {
    if (decoded['format'] != versionedFormat) {
      throw FormatException(
        'Unsupported registry format: ${decoded['format']}.',
        source,
      );
    }

    T field<T>(Map<dynamic, dynamic> map, String key, String where) {
      final value = map[key];
      if (value is! T) {
        throw FormatException('$where: "$key" must be a $T.', source);
      }
      return value;
    }

    final bands = <String, RegistryBand>{};
    final rawBands = decoded['bands'] ?? const <String, dynamic>{};
    if (rawBands is! Map) {
      throw FormatException('"bands" must be an object.', source);
    }
    for (final entry in rawBands.entries) {
      final name = entry.key as String;
      final value = entry.value;
      if (value is! Map) {
        throw FormatException('Band "$name" must be an object.', source);
      }
      final paths = field<List<dynamic>>(value, 'paths', 'Band "$name"');
      bands[name] = RegistryBand(
        name: name,
        start: field<int>(value, 'start', 'Band "$name"'),
        end: field<int>(value, 'end', 'Band "$name"'),
        paths: [
          for (final path in paths)
            if (path is String)
              path
            else
              throw FormatException(
                'Band "$name": paths must be strings.',
                source,
              ),
        ],
      );
    }

    final assignments = <String, int>{};
    final shapes = <String, RegistryShape>{};
    final rawTypes = decoded['types'] ?? const <String, dynamic>{};
    if (rawTypes is! Map) {
      throw FormatException('"types" must be an object.', source);
    }
    for (final entry in rawTypes.entries) {
      final key = entry.key as String;
      final value = entry.value;
      if (value is! Map) {
        throw FormatException('Type "$key" must be an object.', source);
      }
      assignments[key] = field<int>(value, 'typeId', 'Type "$key"');
      final shape = _shapeFromJson(value, key, source);
      if (shape != null) shapes[key] = shape;
    }

    final retired = <int, String>{};
    final rawRetired = decoded['retiredTypeIds'] ?? const <String, dynamic>{};
    if (rawRetired is! Map) {
      throw FormatException('"retiredTypeIds" must be an object.', source);
    }
    for (final entry in rawRetired.entries) {
      final id = int.tryParse(entry.key as String);
      final value = entry.value;
      if (id == null || value is! Map) {
        throw FormatException(
          'Retired entry "${entry.key}" must map an integer to an object.',
          source,
        );
      }
      final key = field<String>(value, 'key', 'Retired ${entry.key}');
      retired[id] = key;
      final shape = _shapeFromJson(value, key, source);
      if (shape != null && !assignments.containsKey(key)) shapes[key] = shape;
    }

    return TypeIdRegistry(
      assignments,
      bands: bands,
      shapes: shapes,
      retired: retired,
    );
  }

  static RegistryShape? _shapeFromJson(
    Map<dynamic, dynamic> value,
    String key,
    String source,
  ) {
    final rawFields = value['fields'];
    if (rawFields == null) return null;

    Map<String, int> intMap(dynamic raw, String name) {
      if (raw == null) return const {};
      if (raw is! Map) {
        throw FormatException('Type "$key": "$name" must be an object.', source);
      }
      return {
        for (final entry in raw.entries)
          entry.key as String: entry.value is int
              ? entry.value as int
              : throw FormatException(
                  'Type "$key": "$name" values must be integers.',
                  source,
                ),
      };
    }

    final layoutName = value['layout'] ?? RegistryLayout.positional.name;
    final layout = RegistryLayout.values
        .where((it) => it.name == layoutName)
        .firstOrNull;
    if (layout == null) {
      throw FormatException('Type "$key": unknown layout "$layoutName".', source);
    }
    final rawPositional = value['positionalFields'];
    if (rawPositional != null && rawPositional is! List) {
      throw FormatException(
        'Type "$key": "positionalFields" must be a list.',
        source,
      );
    }

    return RegistryShape(
      layout: layout,
      fields: intMap(rawFields, 'fields'),
      retiredFields: intMap(value['retiredFields'], 'retiredFields'),
      positionalFields: (rawPositional as List?)?.cast<String>(),
    );
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  static void _validateId(int id) {
    if (id < minUserTypeId || id > maxUserTypeId) {
      throw StateError('TypeId $id must be in $minUserTypeId..$maxUserTypeId.');
    }
  }

  void _validate() {
    final bandList = _bands.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    for (final band in bandList) {
      _validateId(band.start);
      _validateId(band.end);
      if (band.start > band.end) {
        throw StateError('Band "${band.name}" starts after it ends.');
      }
      if (band.paths.isEmpty) {
        throw StateError('Band "${band.name}" declares no paths.');
      }
    }
    for (var i = 1; i < bandList.length; i++) {
      final previous = bandList[i - 1];
      final current = bandList[i];
      if (current.start <= previous.end) {
        throw StateError(
          'Bands "${previous.name}" (${previous.start}-${previous.end}) and '
          '"${current.name}" (${current.start}-${current.end}) overlap.',
        );
      }
    }

    final keysById = <int, String>{};
    void claim(int id, String key) {
      _validateId(id);
      final previous = keysById[id];
      if (previous != null) {
        throw StateError('Duplicate typeId $id for "$previous" and "$key".');
      }
      keysById[id] = key;
    }

    for (final entry in _assignments.entries) {
      claim(entry.value, entry.key);
    }
    for (final entry in _retired.entries) {
      if (_assignments.containsKey(entry.value)) {
        throw StateError(
          '"${entry.value}" is both assigned and retired (typeId ${entry.key}).',
        );
      }
      claim(entry.key, entry.value);
    }

    for (final entry in keysById.entries) {
      final band = bandOfKey(entry.value);
      if (band != null && !band.containsId(entry.key)) {
        throw StateError(
          'typeId ${entry.key} for "${entry.value}" lies outside band '
          '"${band.name}" (${band.start}-${band.end}).',
        );
      }
    }
  }

  // ── Bands and keys ───────────────────────────────────────────────────────────

  /// Declared bands by name.
  Map<String, RegistryBand> get bands => _bands;

  /// Retired identifiers and the key that last held each one.
  Map<int, String> get retiredTypeIds => _retired;

  /// Whether the registry uses any versioned-format feature.
  bool get isVersioned =>
      _bands.isNotEmpty || _retired.isNotEmpty || _shapes.isNotEmpty;

  /// Registry key for [className], qualified by [band] when given.
  static String keyFor(String className, {String? band}) =>
      band == null ? className : '$band/$className';

  /// Returns the band a registry [key] belongs to, or `null` when unbanded.
  RegistryBand? bandOfKey(String key) {
    for (final band in _bands.values) {
      final prefix = '${band.name}/';
      if (key.startsWith(prefix) && !key.substring(prefix.length).contains('/')) {
        return band;
      }
    }
    return null;
  }

  /// Returns the band whose paths match the package-relative [path].
  ///
  /// Returns `null` when no band matches. Throws [StateError] when more than
  /// one band matches.
  RegistryBand? bandForPath(String path) {
    final matches = _bands.values.where((band) => band.matchesPath(path));
    if (matches.length > 1) {
      throw StateError(
        '"$path" matches bands '
        '${matches.map((band) => '"${band.name}"').join(' and ')}.',
      );
    }
    return matches.firstOrNull;
  }

  /// Returns a new registry with [band] declared.
  TypeIdRegistry withBand(RegistryBand band) => _copy(
    bands: {..._bands, band.name: band},
  );

  // ── Queries ──────────────────────────────────────────────────────────────────

  /// Returns the typeId assigned to [key] (a class name or band-qualified key).
  ///
  /// Throws [StateError] if [key] is not registered.  Callers should
  /// check [contains] first when the absence of a class is an expected
  /// condition (e.g. in CLI scan loops).
  int lookupTypeId(String key) {
    final id = _assignments[key];
    if (id == null) {
      throw StateError(
        '"$key" is not in the phive type registry.  '
        'Run the assign_type_ids CLI tool to register it.',
      );
    }
    return id;
  }

  /// Returns true if [key] has an assigned typeId.
  bool contains(String key) => _assignments.containsKey(key);

  /// All active keys and their identifiers.
  Map<String, int> get assignments => _assignments;

  /// Recorded field shape for [key], including retired keys, or `null`.
  RegistryShape? shapeOf(String key) => _shapes[key];

  /// Returns the lowest available unbanded typeId at or above [startAt].
  ///
  /// The result is `max(startAt, maxAssignedId + 1)` over unbanded active and
  /// retired identifiers, skipping past any declared band. When the registry
  /// has no bands or retirements this is exactly the historical behavior.
  int nextAvailableId({int startAt = 0}) {
    final used = [
      for (final entry in _assignments.entries)
        if (bandOfKey(entry.key) == null) entry.value,
      for (final entry in _retired.entries)
        if (bandOfKey(entry.value) == null) entry.key,
    ];
    var candidate = startAt;
    if (used.isNotEmpty) {
      final maxId = used.reduce((a, b) => a > b ? a : b);
      if (maxId + 1 > candidate) candidate = maxId + 1;
    }
    var moved = true;
    while (moved) {
      moved = false;
      for (final band in _bands.values) {
        if (band.containsId(candidate)) {
          candidate = band.end + 1;
          moved = true;
        }
      }
    }
    return candidate;
  }

  /// Returns the next identifier for a new class in [bandName].
  ///
  /// Uses `max(start, maxUsedInBand + 1)`, counting retired identifiers as
  /// used, and falls back to the lowest unused identifier in the band. Throws
  /// [StateError] naming the band when every identifier is taken.
  int nextIdInBand(String bandName) {
    final band = _requireBand(bandName);
    final used = <int>{
      for (final id in _assignments.values)
        if (band.containsId(id)) id,
      for (final id in _retired.keys)
        if (band.containsId(id)) id,
    };
    if (used.isEmpty) return band.start;
    final next = used.reduce((a, b) => a > b ? a : b) + 1;
    if (next <= band.end) return next;
    for (var id = band.start; id <= band.end; id++) {
      if (!used.contains(id)) return id;
    }
    throw StateError(
      'Band "${band.name}" (${band.start}-${band.end}) is exhausted.',
    );
  }

  /// Whether the registry contains no assignments.
  bool get isEmpty => _assignments.isEmpty;

  /// Whether the registry contains at least one assignment.
  bool get isNotEmpty => _assignments.isNotEmpty;

  RegistryBand _requireBand(String name) {
    final band = _bands[name];
    if (band == null) throw StateError('Unknown band "$name".');
    return band;
  }

  // ── Mutations (return new instances) ─────────────────────────────────────────

  TypeIdRegistry _copy({
    Map<String, int>? assignments,
    Map<String, RegistryBand>? bands,
    Map<String, RegistryShape>? shapes,
    Map<int, String>? retired,
  }) => TypeIdRegistry(
    assignments ?? _assignments,
    bands: bands ?? _bands,
    shapes: shapes ?? _shapes,
    retired: retired ?? _retired,
  );

  /// Returns a new registry with [className] assigned an identifier.
  ///
  /// With [band], the class is keyed as `band/className` and receives
  /// [nextIdInBand]; otherwise it receives [nextAvailableId] with the given
  /// [startAt] floor. A key that was previously retired gets its original
  /// identifier back. Throws [StateError] if the key is already registered.
  TypeIdRegistry assign(String className, {int startAt = 0, String? band}) {
    final key = keyFor(className, band: band);
    if (contains(key)) {
      throw StateError(
        '"$key" is already in the phive type registry '
        '(typeId ${_assignments[key]}).  '
        'Use lookupTypeId to retrieve it.',
      );
    }

    final retiredId = _retired.entries
        .where((entry) => entry.value == key)
        .map((entry) => entry.key)
        .firstOrNull;
    if (retiredId != null) {
      return _copy(
        assignments: {..._assignments, key: retiredId},
        retired: {..._retired}..remove(retiredId),
      );
    }

    final int newId;
    if (band != null) {
      newId = nextIdInBand(band);
    } else {
      _validateId(startAt);
      newId = nextAvailableId(startAt: startAt);
      if (newId > maxUserTypeId) {
        throw StateError('No sequential typeId remains for "$className".');
      }
    }
    return _copy(assignments: {..._assignments, key: newId});
  }

  /// Returns a new registry with all [classNames] that are not yet registered
  /// assigned sequential ids.  Already-registered names are skipped.
  TypeIdRegistry assignAll(
    Iterable<String> classNames, {
    int startAt = 0,
    String? band,
  }) {
    var current = this;
    for (final name in classNames) {
      if (!current.contains(keyFor(name, band: band))) {
        current = current.assign(name, startAt: startAt, band: band);
      }
    }
    return current;
  }

  /// Returns a new registry with [key] retired.
  ///
  /// Its identifier is kept as retired and never given to another key. Its
  /// recorded shape is kept so the same key can be reactivated.
  TypeIdRegistry retire(String key) {
    final id = lookupTypeId(key);
    return _copy(
      assignments: {..._assignments}..remove(key),
      retired: {..._retired, id: key},
    );
  }

  /// Returns a new registry where [key] is retired under its old identifier
  /// and re-registered under a new one in the same band, recording [shape].
  TypeIdRegistry reidentify(String key, RegistryShape shape) {
    final oldId = lookupTypeId(key);
    final band = bandOfKey(key);
    final withoutKey = _copy(
      assignments: {..._assignments}..remove(key),
      retired: {..._retired, oldId: key},
    );
    final newId = band == null
        ? withoutKey.nextAvailableId()
        : withoutKey.nextIdInBand(band.name);
    _validateId(newId);
    // The old identifier stays retired under a tombstone key so the active key
    // can hold the new identifier.
    return TypeIdRegistry(
      {...withoutKey._assignments, key: newId},
      bands: _bands,
      shapes: {..._shapes, key: shape},
      retired: {...withoutKey._retired, oldId: '$key@$oldId'},
    );
  }

  /// Returns a new registry with [shape] recorded for [key].
  TypeIdRegistry withShape(String key, RegistryShape shape) =>
      _copy(shapes: {..._shapes, key: shape});

  /// Records the declared fields of [key] and returns the updated registry.
  ///
  /// [orderedFields] is the field sequence in stored order. [explicitTags]
  /// maps fields that declare an explicit index to it.
  ///
  /// Positional types:
  /// - the first record stores the sequence;
  /// - a later different sequence throws [RegistryShapeChangeError] unless
  ///   [reidentify] is true, which retires the identifier and allocates a new
  ///   one in the same band.
  ///
  /// Tolerant types:
  /// - fields keep their tags, new fields get unused tags, and removed fields'
  ///   tags are retired;
  /// - when a positional type first becomes tolerant, its recorded sequence is
  ///   kept as `positionalFields` if [hadOtherHooks] (its version-2 records
  ///   carry a header). That step must not also change fields.
  ///   [previouslyRegistered] says whether [key] existed before this run; a
  ///   type registered and made tolerant in the same run has no positional
  ///   records and gets no snapshot.
  TypeIdRegistry recordShape(
    String key,
    List<String> orderedFields, {
    required bool tolerant,
    Map<String, int> explicitTags = const {},
    bool reidentify = false,
    bool hadOtherHooks = false,
    bool previouslyRegistered = false,
  }) {
    lookupTypeId(key);
    final existing = _shapes[key];

    if (!tolerant) {
      final positional = RegistryShape(
        layout: RegistryLayout.positional,
        fields: {
          for (var i = 0; i < orderedFields.length; i++) orderedFields[i]: i,
        },
      );
      if (existing == null) return withShape(key, positional);
      final unchanged =
          existing.layout == RegistryLayout.positional &&
          _sameSequence(existing.orderedFields, orderedFields);
      if (unchanged) return this;
      if (!reidentify) {
        throw RegistryShapeChangeError(
          key,
          'The field shape of "$key" changed '
          '(${_describeChange(existing.orderedFields, orderedFields)}). '
          'Positional records cannot survive this under the same typeId; '
          're-run with --reidentify $key to retire it and allocate a new one, '
          'or adopt TolerantLayout.',
        );
      }
      return this.reidentify(key, positional);
    }

    if (existing == null || existing.layout == RegistryLayout.positional) {
      List<String>? snapshot;
      var startTags = <String, int>{};
      if (existing != null) {
        if (!_sameSequence(existing.orderedFields, orderedFields)) {
          throw RegistryShapeChangeError(
            key,
            '"$key" adopts TolerantLayout and changes fields in the same step '
            '(${_describeChange(existing.orderedFields, orderedFields)}). '
            'Adopt TolerantLayout first, run assign_type_ids, then change '
            'the fields.',
          );
        }
        startTags = Map.of(existing.fields);
        if (hadOtherHooks) snapshot = existing.orderedFields;
      } else if (hadOtherHooks && previouslyRegistered) {
        // No recorded shape yet: the current sequence is the positional order
        // of the records written before this step.
        snapshot = List.of(orderedFields);
        startTags = {
          for (var i = 0; i < orderedFields.length; i++) orderedFields[i]: i,
        };
      }
      final tags = _allocateTags(
        key,
        orderedFields,
        explicitTags,
        current: startTags,
        retired: const {},
      );
      return withShape(
        key,
        RegistryShape(
          layout: RegistryLayout.tolerant,
          fields: tags,
          positionalFields: snapshot,
        ),
      );
    }

    final retiredFields = Map.of(existing.retiredFields);
    final current = <String, int>{};
    for (final entry in existing.fields.entries) {
      if (orderedFields.contains(entry.key)) {
        current[entry.key] = entry.value;
      } else {
        retiredFields[entry.key] = entry.value;
      }
    }
    for (final name in orderedFields) {
      final previous = retiredFields.remove(name);
      if (previous != null) current[name] = previous;
    }
    final tags = _allocateTags(
      key,
      orderedFields,
      explicitTags,
      current: current,
      retired: retiredFields,
    );
    final updated = RegistryShape(
      layout: RegistryLayout.tolerant,
      fields: tags,
      retiredFields: retiredFields,
      positionalFields: existing.positionalFields,
    );
    return withShape(key, updated);
  }

  Map<String, int> _allocateTags(
    String key,
    List<String> orderedFields,
    Map<String, int> explicitTags, {
    required Map<String, int> current,
    required Map<String, int> retired,
  }) {
    final tags = <String, int>{
      for (final name in orderedFields)
        if (current.containsKey(name)) name: current[name]!,
    };
    for (final entry in explicitTags.entries) {
      final existingTag = tags[entry.key];
      if (existingTag != null && existingTag != entry.value) {
        throw RegistryShapeChangeError(
          key,
          'Field "${entry.key}" of "$key" is tagged $existingTag; '
          'its explicit index ${entry.value} would retag it.',
        );
      }
    }
    final used = <int>{...tags.values, ...retired.values};
    for (final name in orderedFields) {
      if (tags.containsKey(name)) continue;
      final explicit = explicitTags[name];
      if (explicit != null) {
        if (used.contains(explicit)) {
          throw RegistryShapeChangeError(
            key,
            'Explicit index $explicit for "$name" of "$key" is already used '
            'or retired.',
          );
        }
        tags[name] = explicit;
        used.add(explicit);
      }
    }
    var next = used.isEmpty ? 0 : used.reduce((a, b) => a > b ? a : b) + 1;
    for (final name in orderedFields) {
      if (tags.containsKey(name)) continue;
      tags[name] = next;
      used.add(next);
      next += 1;
    }
    return tags;
  }

  static bool _sameSequence(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static String _describeChange(List<String> before, List<String> after) {
    final added = after.where((name) => !before.contains(name)).toList();
    final removed = before.where((name) => !after.contains(name)).toList();
    final parts = [
      if (added.isNotEmpty) 'added: ${added.join(', ')}',
      if (removed.isNotEmpty) 'removed: ${removed.join(', ')}',
      if (added.isEmpty && removed.isEmpty) 'reordered',
    ];
    return parts.join('; ');
  }

  // ── Serialisation ────────────────────────────────────────────────────────────

  /// Serialises the registry to a pretty-printed JSON string.
  ///
  /// The output is deterministic. A registry without bands, retirements or
  /// shapes is written in the flat format with entries sorted by typeId, so
  /// existing projects see no diff. Otherwise the versioned format is written.
  String toJson() {
    const encoder = JsonEncoder.withIndent('  ');
    if (!isVersioned) {
      final sorted = Map.fromEntries(
        _assignments.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value)),
      );
      return encoder.convert(sorted);
    }

    Map<String, dynamic> shapeJson(RegistryShape? shape) => {
      if (shape != null) ...{
        'layout': shape.layout.name,
        'fields': _sortedByValue(shape.fields),
        if (shape.retiredFields.isNotEmpty)
          'retiredFields': _sortedByValue(shape.retiredFields),
        if (shape.positionalFields != null)
          'positionalFields': shape.positionalFields,
      },
    };

    final bandEntries = _bands.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final typeEntries = _assignments.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final retiredEntries = _retired.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return encoder.convert({
      'format': versionedFormat,
      'bands': {for (final band in bandEntries) band.name: band._toJson()},
      'types': {
        for (final entry in typeEntries)
          entry.key: {'typeId': entry.value, ...shapeJson(_shapes[entry.key])},
      },
      'retiredTypeIds': {
        for (final entry in retiredEntries)
          '${entry.key}': {
            'key': entry.value,
            if (!_assignments.containsKey(entry.value))
              ...shapeJson(_shapes[entry.value]),
          },
      },
    });
  }

  static Map<String, int> _sortedByValue(Map<String, int> map) =>
      Map.fromEntries(
        map.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
      );
}

RegExp _globToRegExp(String glob) {
  final buffer = StringBuffer('^');
  for (var i = 0; i < glob.length; i++) {
    final char = glob[i];
    if (char == '*') {
      if (i + 1 < glob.length && glob[i + 1] == '*') {
        buffer.write('.*');
        i += 1;
      } else {
        buffer.write('[^/]*');
      }
    } else {
      buffer.write(RegExp.escape(char));
    }
  }
  buffer.write(r'$');
  return RegExp(buffer.toString());
}
