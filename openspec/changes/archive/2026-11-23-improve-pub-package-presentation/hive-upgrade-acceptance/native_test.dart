import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  setUp(() => Hive.init('data'));
  tearDown(Hive.close);

  test('2.24 reads box written by 2.20', () async {
    final box = await Hive.openBox<dynamic>('legacy');
    expect(box.get('text'), 'written with Hive CE 2.20.0');
    expect(box.get('date'), DateTime.fromMillisecondsSinceEpoch(1700000000123, isUtc: true));
    expect(box.get('duration'), const Duration(milliseconds: 1234));
    expect(box.get('strings'), <String>['first', 'second']);
  });

  test('wrong cipher rejects without modifying old encrypted data', () async {
    final original = File('data/encrypted.hive').readAsBytesSync();
    await expectLater(Hive.openBox<dynamic>('encrypted',
      encryptionCipher: HiveAesCipher(List<int>.filled(32, 255))), throwsA(isA<HiveError>()));
    expect(File('data/encrypted.hive').readAsBytesSync(), original);
    final box = await Hive.openBox<dynamic>('encrypted',
      encryptionCipher: HiveAesCipher(List<int>.generate(32, (i) => i)));
    expect(box.get('secret'), 'retained legacy secret');
  });

  test('new timestamps and durations preserve microseconds after reopening', () async {
    final timestamp = DateTime.fromMicrosecondsSinceEpoch(1700000000123456, isUtc: true);
    const duration = Duration(microseconds: 1234567);
    final box = await Hive.openBox<dynamic>('precision');
    await box.putAll({'date': timestamp, 'duration': duration});
    await box.close();
    final reopened = await Hive.openBox<dynamic>('precision');
    expect(reopened.get('date'), timestamp);
    expect(reopened.get('duration'), duration);
  });
}
