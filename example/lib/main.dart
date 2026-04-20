import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';
import 'package:example/ui/phive_example_app.dart';
import 'models/demo_lesson.dart';
import 'models/demo_lesson_card.dart';
import 'models/settings.dart';
import 'models/user_profile.dart';

// ── Router setup ─────────────────────────────────────────────────────────────
//
// Both types are singleton-per-box (one Settings, one UserProfile at a time),
// so the primary key is a fixed constant string.
//
// Box names match the old PHiveConsumer box names for storage compatibility.

final _dynamicRouter = PHiveDynamicRouter()
  ..register<Settings>(
    primaryKey: (_) => 'current_config',
    boxName: 'app_config',
  )
  ..register<UserProfile>(
    primaryKey: (_) => 'active_user',
    boxName: 'user_sessions',
  );

final _staticRouter = PHiveStaticRouter(collectionName: 'phive_example_relations')
  ..register<DemoLesson>(
    primaryKey: (lesson) => lesson.lessonId,
    boxName: 'demo_lessons',
  )
  ..register<DemoLessonCard>(
    primaryKey: (card) => card.cardId,
    boxName: 'demo_lesson_cards',
  )
  ..createRef<DemoLessonCard, DemoLesson>(
    resolve: (card) => card.lessonId,
    refBoxName: 'demo_lesson_cards_by_lesson',
  );

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
