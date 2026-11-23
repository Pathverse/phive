@TestOn('browser')
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  test('web typed lists survive IndexedDB close and reopen', () async {
    final name = 'upgrade_${DateTime.now().microsecondsSinceEpoch}';
    final box = await Hive.openBox<dynamic>(name);
    await box.putAll({'doubles': <double>[1.25, 2.5], 'bools': <bool>[true, false], 'strings': <String>['a', 'b']});
    await box.close();
    final reopened = await Hive.openBox<dynamic>(name);
    expect(reopened.get('doubles'), isA<List<double>>());
    expect(reopened.get('doubles'), [1.25, 2.5]);
    expect(reopened.get('bools'), isA<List<bool>>());
    expect(reopened.get('bools'), [true, false]);
    expect(reopened.get('strings'), isA<List<String>>());
    expect(reopened.get('strings'), ['a', 'b']);
    await reopened.deleteFromDisk();
    await Hive.close();
  });
}
