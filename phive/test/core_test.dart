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
  });
}
