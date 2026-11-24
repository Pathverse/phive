import 'dart:convert';

import 'package:hive_ce/hive.dart';

/// Implemented by adapters that can describe their stored schema.
///
/// Generated `PTypeAdapter`s expose a build-time fingerprint. Hand-written
/// `TypeAdapter`s may implement this interface to take part in
/// [phiveSchemaFingerprint].
abstract interface class PHiveFingerprinted {
  /// Deterministic description of this adapter's stored schema, or `null` when
  /// the adapter does not provide one.
  String? get schemaFingerprint;
}

final BigInt _fnvOffsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
final BigInt _fnvPrime = BigInt.parse('100000001b3', radix: 16);
final BigInt _mask64 = (BigInt.one << 64) - BigInt.one;

/// Combines the schema of [adapters] into one fingerprint.
///
/// The result is independent of the order [adapters] are supplied in. It
/// changes when any adapter's type ID or fingerprint changes, or when an
/// adapter is added or removed. Adapters without a fingerprint contribute
/// their type ID only.
///
/// The combination uses FNV-1a 64 over a canonical text form. It detects
/// schema drift; it is not a security boundary. `BigInt` arithmetic keeps the
/// value identical on native and web targets.
String phiveSchemaFingerprint(Iterable<TypeAdapter<dynamic>> adapters) {
  final entries = [
    for (final adapter in adapters)
      '${adapter.typeId}:'
          '${adapter is PHiveFingerprinted ? (adapter as PHiveFingerprinted).schemaFingerprint ?? '' : ''}',
  ]..sort();

  var hash = _fnvOffsetBasis;
  for (final byte in utf8.encode(entries.join('\n'))) {
    hash = ((hash ^ BigInt.from(byte)) * _fnvPrime) & _mask64;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
