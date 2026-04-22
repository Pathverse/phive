import 'package:flutter_test/flutter_test.dart';
import 'package:phive/phive.dart';

/// Minimal adapter used to exercise shared PHive runtime helpers in tests.
class MockAdapter extends PTypeAdapter<String> {
  @override
  final int typeId = 0;

  @override
  /// Returns one placeholder value because these tests target helper methods.
  String read(reader) => '';

  @override
  /// Intentionally does nothing because these tests do not write full objects.
  void write(writer, obj) {}
}

/// Verifies PHive metadata-header helpers preserve runtime metadata semantics.
void main() {
  group('PHive metadata header', () {
    test('serializes and restores global and per-field metadata', () {
      final adapter = MockAdapter();
      final header = adapter.createMetadataHeader(
        globalMetadata: {'ttl_ms': 60000, 'written_at': 123},
        perFieldMetadata: {
          'token': {'nonce': 'abc'},
          'count': {'precision': 2},
        },
      );

      final encoded = adapter.serializeMetadataHeader(header);
      final decoded = adapter.extractMetadataHeader(encoded);

      expect(decoded.version, PHiveMetadataHeader.currentVersion);
      expect(decoded.globalMetadata['ttl_ms'], 60000);
      expect(decoded.globalMetadata['written_at'], 123);
      expect(decoded.metadataForField('token')['nonce'], 'abc');
      expect(decoded.metadataForField('count')['precision'], 2);
    });

    test('drops empty per-field metadata entries during normalization', () {
      final adapter = MockAdapter();
      final header = adapter.createMetadataHeader(
        globalMetadata: const {},
        perFieldMetadata: {
          'token': {'nonce': 'abc'},
          'empty': const {},
        },
      );

      expect(header.perFieldMetadata.containsKey('token'), isTrue);
      expect(header.perFieldMetadata.containsKey('empty'), isFalse);
      expect(header.isEmpty, isFalse);
    });

    test('returns empty metadata for unknown fields', () {
      final adapter = MockAdapter();
      final header = adapter.createMetadataHeader();

      expect(header.metadataForField('missing'), isEmpty);
      expect(header.isEmpty, isTrue);
    });

    test('throws when decoding a non-header payload', () {
      final adapter = MockAdapter();

      expect(
        () => adapter.extractMetadataHeader('plain-value'),
        throwsStateError,
      );
    });

    test('throws when decoding an unsupported header version', () {
      final adapter = MockAdapter();

      expect(
        () => adapter.extractMetadataHeader({
          PTypeAdapter.metadataHeaderVersionKey: 1,
          PTypeAdapter.metadataHeaderGlobalKey: const <String, dynamic>{},
          PTypeAdapter.metadataHeaderPerFieldKey:
              const <String, Map<String, dynamic>>{},
        }),
        throwsStateError,
      );
    });

    test('applies metadata without overwriting existing keys', () {
      final adapter = MockAdapter();
      final ctx = PHiveCtx()..metadata['nonce'] = 'field-nonce';

      adapter.applyMetadata(ctx, {
        'ttl_ms': 60000,
        'nonce': 'global-nonce',
      });

      expect(ctx.metadata['ttl_ms'], 60000);
      expect(ctx.metadata['nonce'], 'field-nonce');
    });
  });
}
