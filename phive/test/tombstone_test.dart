import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_writer_impl.dart';
import 'package:phive/phive.dart';

class _Value {
  final Object? nested;
  _Value(this.nested);
}

class _Real extends TypeAdapter<_Value> {
  const _Real(this.typeId);
  @override
  final int typeId;
  @override
  _Value read(BinaryReader reader) => _Value(reader.read());
  @override
  void write(BinaryWriter writer, _Value obj) => writer.write(obj.nested);
}

class _Marker {}

class _Nested {}

void main() {
  tearDown(Hive.resetAdapters);

  test('top-level tombstone identifies the retired type', () {
    Hive.registerAdapter<_Value>(_Real(120));
    final writer = BinaryWriterImpl(Hive)..write(_Value('old'));
    Hive.resetAdapters();
    registerPHiveTombstone<_Marker>(120);
    expect(
      () => BinaryReaderImpl(writer.toBytes(), Hive).read(),
      throwsA(
        isA<PHiveSchemaDriftException>().having(
          (e) => e.typeName,
          'typeName',
          'retired type 120',
        ),
      ),
    );
  });

  test('nested tombstone fails the enclosing record', () {
    Hive.registerAdapter<_Value>(_Real(121));
    final writer = BinaryWriterImpl(Hive)..write([_Value('old')]);
    Hive.resetAdapters();
    registerPHiveTombstone<_Nested>(121);
    expect(
      () => BinaryReaderImpl(writer.toBytes(), Hive).read(),
      throwsA(isA<PHiveSchemaDriftException>()),
    );
  });

  test('writes are rejected', () {
    expect(
      () => PHiveTombstoneAdapter<_Marker>(
        120,
      ).write(BinaryWriterImpl(Hive), _Marker()),
      throwsStateError,
    );
  });

  test('registration is idempotent', () {
    expect(registerPHiveTombstone<_Marker>(120), isTrue);
    expect(registerPHiveTombstone<_Marker>(120), isFalse);
  });

  test('existing adapter is preserved', () {
    Hive.registerAdapter<_Value>(_Real(122));
    expect(registerPHiveTombstone<_Marker>(122), isFalse);
    final writer = BinaryWriterImpl(Hive)..write(_Value('kept'));
    expect(
      (BinaryReaderImpl(writer.toBytes(), Hive).read() as _Value).nested,
      'kept',
    );
  });
}
