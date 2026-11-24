import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/tolerant_lesson.dart';
import 'package:phive_test/proofs/tolerant_proof.dart';

export 'package:phive_test/proofs/tolerant_proof.dart';

/// Builds a router of [backend] over [directory] with [register] applied.
PHiveRouter buildRouter(
  String backend,
  Directory directory,
  void Function(PHiveRouter router) register,
) {
  return buildTolerantRouter(backend, directory.path, register);
}

/// Closes storage and clears adapters, as if a new build started.
Future<void> restartBuild(Directory directory) async {
  await Hive.close();
  Hive.resetAdapters();
  Hive.init(directory.path);
}

/// Stores [sampleLesson] in the `lessons` store through the first build.
class RetiredCardWriter extends TolerantCardAdapter {
  @override
  int get typeId => 120;
}

Future<void> writeFirstBuild(
  String backend,
  Directory directory, {
  bool retiredCard = false,
}) async {
  Hive.registerAdapter<TolerantCard>(
    retiredCard ? RetiredCardWriter() : TolerantCardAdapter(),
  );
  Hive.registerAdapter<TolerantLesson>(TolerantLessonAdapter());
  final writer = buildRouter(
    backend,
    directory,
    (r) =>
        r.register<TolerantLesson>(primaryKey: (l) => l.id, boxName: 'lessons'),
  );
  await writer.ensureOpen();
  await writer.store(sampleLesson);
  await restartBuild(directory);
}
