import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:phive/phive.dart';
import 'package:phive_example/models/user_profile.dart';

import 'example_utils.dart';

Future<void> main() async {
  printStage(
    'bootstrap',
    'Initialize Flutter and Hive runtime before any adapter or box operation.',
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  printStage(
    'dependencies',
    'Create cipher, hooks, and context that adapters use for encryption/decryption and metadata resolution.',
  );
  final cipher = await createEncryptionCipher();
  final hookRegistry = createDemoHookRegistry();
  final baseCtx = createDemoCtx();

  printStage(
    'adapter-registration',
    'Register generated Hive adapters first, then PHive encrypted wrapper adapters.',
  );
  registerDemoAdapters(
    cipher: cipher,
    baseCtx: baseCtx,
    hookRegistry: hookRegistry,
  );

  printStage(
    'source-model',
    'Build source model and print wrapper values plus raw payload snapshots before writing.',
  );
  final demo = createDemoProfile();

  printProfileFlow('pre-write source', demo, cipher, baseCtx);

  printStage(
    'box-open',
    'Open box and attempt first read to validate persisted fetch path before writing new data.',
  );
  final box = await Hive.openBox<UserProfile>(userProfilesBoxName);

  final existing = box.get(primaryUserKey);
  if (existing == null) {
    print('Entry read: no existing record, continuing.');
  } else {
    printProfileFlow('entry-read fetched', existing, cipher, baseCtx);
  }

  printStage(
    'write',
    'Write model to Hive. Wrapper adapters automatically handle transformation flow.',
  );
  await box.put(primaryUserKey, demo);

  printStage(
    'read-after-write',
    'Fetch the same key after write and print full flow to validate restore path.',
  );
  final restoredFromBox = box.get(primaryUserKey);
  if (restoredFromBox != null) {
    printProfileFlow('post-write fetched', restoredFromBox, cipher, baseCtx);
  }

  printStage('shutdown', 'Close resources and end the example run cleanly.');
  await box.close();
  await Hive.close();
}
