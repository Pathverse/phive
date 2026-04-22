import 'package:flutter_test/flutter_test.dart';
import 'package:phive/phive.dart';

class MockAdapter extends PTypeAdapter<String> {
  @override
  final int typeId = 0;
  
  @override
  String read(reader) => '';
  
  @override
  void write(writer, obj) {}
}

void main() {
  group('PHive Payload formats', () {
    test('Serializes metadata mapping accurately', () {
      final adapter = MockAdapter();
      final payload = adapter.serializePayload('my_data', {'ttl': 50, 'key': 'secret'});
      
      final extract = adapter.extractPayload(payload);
      expect(extract.value, 'my_data');
      expect(extract.metadata['ttl'], 50);
      expect(extract.metadata['key'], 'secret');
    });

    test('gracefully ignores non metadata types', () {
      final adapter = MockAdapter();
      final payload = adapter.serializePayload('my_data', {});
      expect(payload, 'my_data');

      final extract = adapter.extractPayload(payload);
      expect(extract.value, 'my_data');
      expect(extract.metadata, isEmpty);
    });

    test('serializes and restores class metadata envelope accurately', () {
      final adapter = MockAdapter();
      final envelope = adapter.serializeClassMetadataEnvelope({
        'ttl_ms': 60000,
        'written_at': 123,
      });

      final extract = adapter.extractClassMetadataEnvelope(envelope);
      expect(extract['ttl_ms'], 60000);
      expect(extract['written_at'], 123);
    });

    test('treats a non-PAR value as missing class metadata', () {
      final adapter = MockAdapter();

      expect(adapter.isClassMetadataEnvelope('plain-value'), isFalse);
      expect(adapter.extractClassMetadataEnvelope('plain-value'), isEmpty);
    });

    test('applies shared metadata without overwriting field metadata', () {
      final adapter = MockAdapter();
      final ctx = adapter.extractPayload(
        adapter.serializePayload('value', {'nonce': 'field-nonce'}),
      );

      adapter.applySharedMetadata(ctx, {
        'ttl_ms': 60000,
        'nonce': 'class-nonce',
      });

      expect(ctx.metadata['ttl_ms'], 60000);
      expect(ctx.metadata['nonce'], 'field-nonce');
    });
  });

  group('Null value handling', () {
    test('serializePayload returns null when value is null (no metadata)', () {
      final adapter = MockAdapter();
      final payload = adapter.serializePayload(null, {});
      expect(payload, isNull,
          reason: 'null values must not be stringified to "null"');
    });

    test('serializePayload returns null when value is null (with metadata)', () {
      final adapter = MockAdapter();
      // Simulates TTL or other hooks having written pendingMetadata for a
      // nullable field whose value happens to be null.
      final payload =
          adapter.serializePayload(null, {'ttl_ms': 60000, 'written_at': 0});
      expect(payload, isNull,
          reason: 'metadata must be discarded rather than wrapping null');
    });

    test('extractPayload restores null as null (not the string "null")', () {
      final adapter = MockAdapter();
      final ctx = adapter.extractPayload(null);
      expect(ctx.value, isNull);
      expect(ctx.metadata, isEmpty);
    });

    test('null round-trips correctly — not stored as the string "null"', () {
      final adapter = MockAdapter();
      // Write path: value is null with no pending metadata.
      final payload = adapter.serializePayload(null, {});
      // Read path: Hive returns null; extractPayload must restore null.
      final ctx = adapter.extractPayload(payload);
      // The final cast `ctx.value as int?` must succeed (null is a valid int?).
      expect(() => ctx.value as int?, returnsNormally);
      expect(ctx.value as int?, isNull);
    });

    test(
        'null round-trips correctly — not stored as "null" even when hooks '
        'added metadata', () {
      final adapter = MockAdapter();
      // TTL.preWrite would add metadata, but after the null guard it no longer
      // does.  This test simulates what would happen if metadata were present
      // anyway, confirming serializePayload still returns null.
      final payload =
          adapter.serializePayload(null, {'ttl_ms': 60000, 'written_at': 0});
      final ctx = adapter.extractPayload(payload);
      expect(() => ctx.value as int?, returnsNormally);
      expect(ctx.value as int?, isNull);
    });
  });
}
