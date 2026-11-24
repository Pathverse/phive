import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
// The detector is router-internal; this contract test pins its assumption.
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_writer_impl.dart';
import 'package:phive/src/router/base_router.dart';

class _Probe {
  final String value;
  _Probe(this.value);
}

class _ProbeAdapter extends TypeAdapter<_Probe> {
  @override
  final int typeId = 99;

  @override
  _Probe read(BinaryReader reader) => _Probe(reader.read() as String);

  @override
  void write(BinaryWriter writer, _Probe obj) => writer.write(obj.value);
}

/// Hive CE has no typed error for an unregistered type ID, so the drift
/// policy matches its message. Checked by source against hive_ce 2.19.3,
/// 2.20.0 and 2.24.0; this test pins it against the resolved version.
void main() {
  tearDown(Hive.resetAdapters);

  test("hive_ce's unknown type-ID error is recognized", () {
    Hive.registerAdapter<_Probe>(_ProbeAdapter());
    final writer = BinaryWriterImpl(Hive)..write(_Probe('x'));
    final bytes = writer.toBytes();
    Hive.resetAdapters();

    Object? caught;
    try {
      BinaryReaderImpl(bytes, Hive).read();
    } catch (error) {
      caught = error;
    }

    expect(caught, isA<HiveError>());
    expect(isUnknownTypeIdError(caught! as HiveError), isTrue);
  });

  test('other Hive errors are not treated as drift', () {
    expect(isUnknownTypeIdError(HiveError('Box has already been closed.')),
        isFalse);
  });
}
