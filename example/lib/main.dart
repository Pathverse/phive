import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';
import 'package:example/ui/phive_example_app.dart';
import 'models/demo_lesson.dart';
import 'models/demo_lesson_card.dart';
import 'models/settings.dart';
import 'models/user_profile.dart';

/// Builds the dynamic router used by the hook-focused example section.
PHiveDynamicRouter _buildDynamicRouter() {
  final router = PHiveDynamicRouter();
  router.applyDescriptors(const [
    SettingsRouterDescriptor(),
    UserProfileRouterDescriptor(),
  ]);
  return router;
}

/// Builds the static router used by the relations-focused example section.
PHiveStaticRouter _buildStaticRouter() {
  final router = PHiveStaticRouter(collectionName: 'phive_example_relations');
  router.applyDescriptors(const [
    DemoLessonRouterDescriptor(),
    DemoLessonCardRouterDescriptor(),
  ]);
  return router;
}

final _dynamicRouter = _buildDynamicRouter();

final _staticRouter = _buildStaticRouter();

/// Boots the example application and registers all runtime dependencies.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register secure storage for cryptographic hooks
  PhiveMetaRegistry.registerSeedProvider(SecureStorageSeedProvider());
  await PhiveMetaRegistry.init();

  // Initialize Hive CE
  await Hive.initFlutter();

  // Register generated TypeAdapters
  Hive.registerAdapter(SettingsAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(DemoLessonAdapter());
  Hive.registerAdapter(DemoLessonCardAdapter());

  runApp(
    PhiveExampleApp(
      dynamicRouter: _dynamicRouter,
      staticRouter: _staticRouter,
    ),
  );
}
