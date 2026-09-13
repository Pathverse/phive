// The static router uses the same Hive binary boundary.
// ignore_for_file: implementation_imports
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
import 'package:hive_ce/src/binary/binary_writer_impl.dart';
import 'package:phive_test/models/auto_metadata.dart';
import 'package:phive_test/models/explicit_metadata.dart';
import 'package:phive_test/models/metadata_observation.dart';
import 'package:phive_test/models/plain_record.dart';

void main() {
  test('both regenerated adapters read fixed pre-fix version-2 bytes', () {
    final bytes = base64Decode(
      File(
        'test/fixtures/explicit_metadata_v2.base64',
      ).readAsStringSync().trim(),
    );
    final explicit = ExplicitMetadataAdapter().read(
      BinaryReaderImpl(bytes, Hive),
    );
    final automatic = AutoMetadataAdapter().read(BinaryReaderImpl(bytes, Hive));
    for (final value in <MetadataObservation>[explicit, automatic]) {
      // The two generated fixture classes share the same persisted layout.
      expect(value.id, 'record');
      expect(value.overridden, 'field');
      expect(value.inherited, 'global');
      expect(value.nullable, isNull);
      expect(value.observedGlobal, 'global');
    }
  });

  test('hookless adapters keep their existing header-free field sequence', () {
    final writer = BinaryWriterImpl(Hive);
    PlainRecordAdapter().write(writer, PlainRecord(id: 'plain', count: 7));
    final reader = BinaryReaderImpl(writer.toBytes(), Hive);
    expect(reader.read(), 'plain');
    expect(reader.read(), 7);
    expect(reader.availableBytes, 0);
    final restored = PlainRecordAdapter().read(
      BinaryReaderImpl(writer.toBytes(), Hive),
    );
    expect(restored.id, 'plain');
    expect(restored.count, 7);
  });
}
