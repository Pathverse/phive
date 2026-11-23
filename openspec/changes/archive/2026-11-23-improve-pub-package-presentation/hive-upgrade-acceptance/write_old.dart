import 'dart:io';
import 'package:hive_ce/hive.dart';

Future<void> main() async {
  final directory = Directory('data')..createSync();
  Hive.init(directory.path);
  final box = await Hive.openBox<dynamic>('legacy');
  await box.putAll({
    'text': 'written with Hive CE 2.20.0',
    'date': DateTime.fromMillisecondsSinceEpoch(1700000000123, isUtc: true),
    'duration': const Duration(milliseconds: 1234),
    'strings': <String>['first', 'second'],
  });
  final encrypted = await Hive.openBox<dynamic>('encrypted',
      encryptionCipher: HiveAesCipher(List<int>.generate(32, (i) => i)));
  await encrypted.put('secret', 'retained legacy secret');
  await Hive.close();
  print('Old plain and encrypted boxes written.');
}
