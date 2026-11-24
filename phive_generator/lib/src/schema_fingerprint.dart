import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Computes the build-time schema fingerprint of one generated adapter.
///
/// The canonical input is `typeId|layout|tag:name:type,...` with fields sorted
/// by tag (positional adapters use their field index as the tag). It depends
/// only on the stored schema, so it is stable across machines and changes
/// whenever a field is added, removed, retyped or retagged, or the type ID or
/// layout changes.
String computeSchemaFingerprint({
  required int typeId,
  required String layout,
  required Map<String, int> tags,
  Map<String, String>? types,
}) {
  final fields = tags.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  final canonical = StringBuffer('$typeId|$layout|')
    ..writeAll([
      for (final field in fields)
        types == null
            ? '${field.value}:${field.key}'
            : '${field.value}:${field.key}:${types[field.key]}',
    ], ',');
  return sha256.convert(utf8.encode(canonical.toString())).toString();
}

/// Emits the `schemaFingerprint` getter override for a generated adapter.
String emitSchemaFingerprintGetter(String fingerprint) =>
    '''

  @override
  String? get schemaFingerprint => '$fingerprint';
''';
