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

    test('serializes and restores a tagged (version 3) header', () {
      final adapter = MockAdapter();
      final header = adapter.createMetadataHeader(
        version: PHiveMetadataHeader.taggedVersion,
        globalMetadata: {'written_at': 7},
      );

      final decoded = adapter.extractMetadataHeader(
        adapter.serializeMetadataHeader(header),
      );

      expect(decoded.version, PHiveMetadataHeader.taggedVersion);
      expect(decoded.isTagged, isTrue);
      expect(decoded.globalMetadata['written_at'], 7);
    });

    test('positional headers default to version 2 and report it', () {
      final adapter = MockAdapter();
      final decoded = adapter.extractMetadataHeader(
        adapter.serializeMetadataHeader(adapter.createMetadataHeader()),
      );

      expect(PHiveMetadataHeader.currentVersion, 2);
      expect(decoded.version, PHiveMetadataHeader.positionalVersion);
      expect(decoded.isTagged, isFalse);
    });

    test('rejects a header version newer than 3', () {
      final adapter = MockAdapter();

      expect(
        () => adapter.extractMetadataHeader({
          PTypeAdapter.metadataHeaderVersionKey: 4,
          PTypeAdapter.metadataHeaderGlobalKey: const <String, dynamic>{},
          PTypeAdapter.metadataHeaderPerFieldKey:
              const <String, Map<String, dynamic>>{},
        }),
        throwsStateError,
      );
    });

    test('rejects constructing a header with an unsupported version', () {
      expect(() => PHiveMetadataHeader(version: 1), throwsArgumentError);
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

  group('Tolerant layout hook', () {
    test('is a const hook that leaves the context unchanged', () {
      const hook = TolerantLayout();
      final ctx = PHiveCtx()
        ..value = {'a': 1}
        ..metadata['m'] = 1;

      hook.preWrite(ctx);
      hook.postWrite(ctx);
      hook.preRead(ctx);
      hook.postRead(ctx);

      expect(hook, isA<PHiveHook>());
      expect(ctx.value, {'a': 1});
      expect(ctx.metadata, {'m': 1});
      expect(ctx.pendingMetadata, isEmpty);
    });

    test('is canonical so const lists compare equal', () {
      expect(identical(const TolerantLayout(), const TolerantLayout()), isTrue);
    });
  });

  group('Schema drift signal', () {
    test('carries the type and field and requests no behavior', () {
      final drift = PHiveSchemaDriftException(
        typeName: 'Lesson',
        fieldName: 'title',
        reason: 'expected String, found int',
      );

      expect(drift, isA<PHiveActionException>());
      expect(drift.typeName, 'Lesson');
      expect(drift.fieldName, 'title');
      expect(drift.behaviors, isEmpty);
      expect(drift.toString(), contains('Lesson.title'));
    });

    test('allows a record-level drift without a field', () {
      final drift = PHiveSchemaDriftException(
        typeName: 'Lesson',
        reason: 'no positional snapshot for a version-2 record',
      );

      expect(drift.fieldName, isNull);
      expect(drift.toString(), contains('Lesson'));
    });

    test('is distinguishable from an expiry signal', () {
      final PHiveActionException expiry = PHiveActionException(
        'TTLExpired',
        behaviors: {
          PHiveActionBehavior.deleteEntry,
          PHiveActionBehavior.returnNull,
        },
      );
      final PHiveActionException drift = PHiveSchemaDriftException(
        typeName: 'Lesson',
        reason: 'x',
      );

      expect(expiry, isNot(isA<PHiveSchemaDriftException>()));
      expect(drift, isA<PHiveSchemaDriftException>());
    });
  });
}
