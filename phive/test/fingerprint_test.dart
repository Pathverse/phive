import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

/// Adapter whose generated fingerprint is supplied by the test.
class _Fp extends PTypeAdapter<String> {
  _Fp(this.typeId, this._fingerprint);

  @override
  final int typeId;
  final String? _fingerprint;

  @override
  String? get schemaFingerprint => _fingerprint;

  @override
  String read(BinaryReader reader) => '';

  @override
  void write(BinaryWriter writer, String obj) {}
}

/// Hand-written Hive adapter that exposes a fingerprint through the interface.
class _Plain extends TypeAdapter<int> implements PHiveFingerprinted {
  const _Plain(this.typeId, this.schemaFingerprint);

  @override
  final int typeId;

  @override
  final String? schemaFingerprint;

  @override
  int read(BinaryReader reader) => 0;

  @override
  void write(BinaryWriter writer, int obj) {}
}

/// Hand-written Hive adapter without any fingerprint.
class _Bare extends TypeAdapter<bool> {
  const _Bare(this.typeId);

  @override
  final int typeId;

  @override
  bool read(BinaryReader reader) => false;

  @override
  void write(BinaryWriter writer, bool obj) {}
}

void main() {
  group('PTypeAdapter.schemaFingerprint', () {
    test('defaults to null for hand-written adapters', () {
      expect(_Fp(1, null).schemaFingerprint, isNull);
    });
  });

  group('phiveSchemaFingerprint', () {
    test('is a 16-character lowercase hex string', () {
      final value = phiveSchemaFingerprint([_Fp(1, 'aa')]);
      expect(value, matches(RegExp(r'^[0-9a-f]{16}$')));
    });

    test('is independent of adapter order', () {
      final a = phiveSchemaFingerprint([_Fp(1, 'aa'), _Fp(2, 'bb')]);
      final b = phiveSchemaFingerprint([_Fp(2, 'bb'), _Fp(1, 'aa')]);
      expect(a, b);
    });

    test('changes when any adapter fingerprint changes', () {
      final a = phiveSchemaFingerprint([_Fp(1, 'aa'), _Fp(2, 'bb')]);
      final b = phiveSchemaFingerprint([_Fp(1, 'aa'), _Fp(2, 'bc')]);
      expect(a, isNot(b));
    });

    test('changes when an adapter is added or its type id changes', () {
      final base = phiveSchemaFingerprint([_Fp(1, 'aa')]);
      expect(phiveSchemaFingerprint([_Fp(1, 'aa'), _Fp(2, 'bb')]), isNot(base));
      expect(phiveSchemaFingerprint([_Bare(1)]), isNot(phiveSchemaFingerprint([_Bare(2)])));
    });

    test('accepts plain Hive adapters with and without fingerprints', () {
      final value = phiveSchemaFingerprint([_Plain(5, 'cc'), _Bare(6)]);
      expect(value, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(
        phiveSchemaFingerprint([_Plain(5, 'cc')]),
        isNot(phiveSchemaFingerprint([_Plain(5, 'cd')])),
      );
    });

    test('matches the known FNV-1a 64 value for a fixed input', () {
      // FNV-1a 64 of the empty string is the offset basis.
      expect(phiveSchemaFingerprint(const []), 'cbf29ce484222325');
    });

    test('matches an independently computed value on every platform', () {
      // Reference: FNV-1a 64 over "1:aa\n2:bb", computed outside Dart.
      expect(
        phiveSchemaFingerprint([_Fp(2, 'bb'), _Fp(1, 'aa')]),
        'cc0eef96f6ca7b26',
      );
    });
  });
}
