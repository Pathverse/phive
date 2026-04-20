import 'package:flutter/material.dart';
import 'package:phive/phive.dart';

import '../models/demo_lesson.dart';
import '../models/demo_lesson_card.dart';
import '../models/settings.dart';
import '../models/user_profile.dart';
import 'widgets/action_button_bar.dart';
import 'widgets/cache_card.dart';
import 'widgets/phive_data_row.dart';
import 'widgets/router_relations_panel.dart';
import 'widgets/status_badge.dart';

/// Root widget for the PHive example application.
class PhiveExampleApp extends StatelessWidget {
  /// Creates the application shell around the example home page.
  const PhiveExampleApp({
    super.key,
    required this.dynamicRouter,
    required this.staticRouter,
  });

  /// Router used by the example to store and restore hook-driven cache models.
  final PHiveRouter dynamicRouter;

  /// Router used by the example to demonstrate ref and container behavior.
  final PHiveRouter staticRouter;

  @override
  /// Builds the MaterialApp wrapper for the example experience.
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phive Secure Cache Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: PhiveExampleHomePage(
        title: 'Phive Cache Storage',
        dynamicRouter: dynamicRouter,
        staticRouter: staticRouter,
      ),
    );
  }
}

/// Stateful home page that demonstrates PHive cache storage and restore flows.
class PhiveExampleHomePage extends StatefulWidget {
  /// Creates the example home page with a title and storage router.
  const PhiveExampleHomePage({
    super.key,
    required this.title,
    required this.dynamicRouter,
    required this.staticRouter,
  });

  /// Title shown in the app bar.
  final String title;

  /// Router used to persist and restore the hooked cache demo records.
  final PHiveRouter dynamicRouter;

  /// Router used to persist and restore the relations demo records.
  final PHiveRouter staticRouter;

  @override
  /// Creates state for the example home page.
  State<PhiveExampleHomePage> createState() => _PhiveExampleHomePageState();
}

/// Manages the example page state and cache actions.
class _PhiveExampleHomePageState extends State<PhiveExampleHomePage> {
  Settings? _loadedSettings;
  UserProfile? _loadedProfile;
  String _status = 'Initializing...';
  String _relationStatus = 'Seed the lesson graph to inspect router containers.';
  DateTime? _lastSavedAt;
  DateTime? _lastRestoredAt;
  int _restoreCount = 0;
  DemoLesson? _loadedLesson;
  List<DemoLessonCard> _loadedLessonCards = const [];

  @override
  /// Warms the router when the example page first mounts.
  void initState() {
    super.initState();
    _warmup();
  }

  /// Pre-opens the example storage boxes when available.
  Future<void> _warmup() async {
    try {
      await widget.dynamicRouter.ensureOpen();
      await widget.staticRouter.ensureOpen();
      if (!mounted) return;
      setState(() {
        _status = 'Ready. Use Simulate Login then Restore Cache.';
        _relationStatus =
            'Static router ready. Seed the lesson graph to inspect containers.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'Ready (lazy open). Use Simulate Login then Restore Cache.';
        _relationStatus =
            'Static router will open on demand. Seed the lesson graph to inspect containers.';
      });
    }
  }

  /// Formats a timestamp for compact status output.
  String _timeLabel(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  /// Writes simulated API results into local storage.
  Future<void> _loginSimulatedUser() async {
    setState(() => _status = 'Authenticating...');

    final userSettings = Settings(
      username: 'AliceTheDev',
      secretKey: 'sk_live_db12a8934dfb3r832b',
      cachedToken: 'session_token_live_x883da',
      config: {'theme': 'dark', 'notifications': true, 'version': 2.0},
    );

    final userProfile = UserProfile(
      id: 'USR_90210',
      encryptedToken: 'secret_oauth2_refresh_token',
      tempSessionId: 'sess_tmp_60min_abcdef',
    );

    await widget.dynamicRouter.store(userSettings);
    await widget.dynamicRouter.store(userProfile);

    final savedAt = DateTime.now();
    setState(() {
      _lastSavedAt = savedAt;
      _status = 'Saved to cache at ${_timeLabel(savedAt)}';
    });
  }

  /// Restores cached records and updates the visible status state.
  Future<void> _loadCache() async {
    setState(() => _status = 'Loading from disk...');

    Settings? settings;
    UserProfile? profile;
    final restoredAt = DateTime.now();
    var statusMsg =
        'Restore #${_restoreCount + 1} succeeded at ${_timeLabel(restoredAt)}';

    try {
      settings = await widget.dynamicRouter.get<Settings>('current_config');
      profile = await widget.dynamicRouter.get<UserProfile>('active_user');

      if (settings == null || profile == null) {
        statusMsg =
            'Restore #${_restoreCount + 1} at ${_timeLabel(restoredAt)} returned empty (expired or missing).';
      }
    } on PHiveActionException catch (error) {
      debugPrint('[PHiveRouter][GET] ${error.message} codes=${error.codes}');
      statusMsg =
          'Restore #${_restoreCount + 1} failed at ${_timeLabel(restoredAt)}: ${error.message}';
    } catch (error) {
      statusMsg =
          'Restore #${_restoreCount + 1} failed at ${_timeLabel(restoredAt)}: $error';
    }

    setState(() {
      _loadedSettings = settings;
      _loadedProfile = profile;
      _restoreCount += 1;
      _lastRestoredAt = restoredAt;
      _status = statusMsg;
    });
  }

  /// Removes the known singleton cache entries from storage.
  Future<void> _clearCache() async {
    await widget.dynamicRouter.delete<Settings>('current_config');
    await widget.dynamicRouter.delete<UserProfile>('active_user');
    setState(() {
      _loadedSettings = null;
      _loadedProfile = null;
      _status = 'Cache wiped.';
    });
  }

  /// Returns the fixed lesson used by the router relations demo.
  DemoLesson _demoLesson() {
    return const DemoLesson(
      lessonId: 'lesson_router_intro',
      title: 'Router Containers 101',
    );
  }

  /// Returns the child cards used by the router relations demo.
  List<DemoLessonCard> _demoLessonCards() {
    return const [
      DemoLessonCard(
        cardId: 'card_router_1',
        lessonId: 'lesson_router_intro',
        prompt: 'What does createRef register?',
        answer: 'A parent-child relationship backed by a ref store.',
      ),
      DemoLessonCard(
        cardId: 'card_router_2',
        lessonId: 'lesson_router_intro',
        prompt: 'What does getContainer return?',
        answer: 'All child items currently referenced by a parent handle.',
      ),
      DemoLessonCard(
        cardId: 'card_router_3',
        lessonId: 'lesson_router_intro',
        prompt: 'What does deleteWithChildren do?',
        answer: 'It removes the parent and cascade-deletes registered children.',
      ),
    ];
  }

  /// Stores one lesson graph and immediately reloads it through the router.
  Future<void> _seedRelationGraph() async {
    setState(() {
      _relationStatus = 'Seeding lesson graph...';
    });

    final lesson = _demoLesson();
    final cards = _demoLessonCards();

    try {
      await widget.staticRouter.store(lesson);
      for (final card in cards) {
        await widget.staticRouter.store(card);
      }

      final handle =
          widget.staticRouter.containerOf<DemoLessonCard, DemoLesson>(lesson);
      final loadedCards =
          await widget.staticRouter.getContainer<DemoLessonCard>(handle);

      setState(() {
        _loadedLesson = lesson;
        _loadedLessonCards = loadedCards;
        _relationStatus =
            'Seeded ${loadedCards.length} cards under ${lesson.title}.';
      });
    } catch (error) {
      setState(() {
        _relationStatus = 'Failed to seed relation graph: $error';
      });
    }
  }

  /// Loads the demo lesson graph from the router and updates the UI.
  Future<void> _loadRelationGraph() async {
    setState(() {
      _relationStatus = 'Loading lesson container...';
    });

    final lessonSeed = _demoLesson();

    try {
        final lesson =
          await widget.staticRouter.get<DemoLesson>(lessonSeed.lessonId);
      if (lesson == null) {
        setState(() {
          _loadedLesson = null;
          _loadedLessonCards = const [];
          _relationStatus = 'No lesson graph found. Seed it first.';
        });
        return;
      }

        final handle =
          widget.staticRouter.containerOf<DemoLessonCard, DemoLesson>(lesson);
        final cards = await widget.staticRouter.getContainer<DemoLessonCard>(handle);

      setState(() {
        _loadedLesson = lesson;
        _loadedLessonCards = cards;
        _relationStatus =
            'Loaded lesson ${lesson.title} with ${cards.length} related cards.';
      });
    } catch (error) {
      setState(() {
        _relationStatus = 'Failed to load relation graph: $error';
      });
    }
  }

  /// Deletes only the lesson cards while preserving the lesson itself.
  Future<void> _deleteRelationCards() async {
    setState(() {
      _relationStatus = 'Deleting contained cards only...';
    });

    final lesson = _demoLesson();

    try {
        final handle =
          widget.staticRouter.containerOf<DemoLessonCard, DemoLesson>(lesson);
        await widget.staticRouter.deleteContainer<DemoLessonCard>(handle);
        final reloadedLesson =
          await widget.staticRouter.get<DemoLesson>(lesson.lessonId);

      setState(() {
        _loadedLesson = reloadedLesson;
        _loadedLessonCards = const [];
        _relationStatus =
            'Deleted child cards while preserving the parent lesson.';
      });
    } catch (error) {
      setState(() {
        _relationStatus = 'Failed to delete child cards: $error';
      });
    }
  }

  /// Cascade-deletes the lesson and all registered child cards.
  Future<void> _cascadeDeleteRelationGraph() async {
    setState(() {
      _relationStatus = 'Cascade deleting lesson graph...';
    });

    final lessonSeed = _demoLesson();

    try {
      final lesson =
          await widget.staticRouter.get<DemoLesson>(lessonSeed.lessonId);
      await widget.staticRouter.deleteWithChildren<DemoLesson>(
        lesson ?? lessonSeed,
      );

      setState(() {
        _loadedLesson = null;
        _loadedLessonCards = const [];
        _relationStatus = 'Cascade deleted the lesson and its child cards.';
      });
    } catch (error) {
      setState(() {
        _relationStatus = 'Failed to cascade delete lesson graph: $error';
      });
    }
  }

  /// Builds the hook-focused section header text block.
  Widget _buildHookSectionHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hooked Cache Demo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Demonstrates generated adapters, field-level encryption, and TTL-backed values restored through PHiveDynamicRouter.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Builds the cache viewer section for loaded models or empty state.
  Widget _buildCacheViewer(BuildContext context) {
    if (_loadedSettings != null && _loadedProfile != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CacheCard(
            title: 'Freezed User Profile',
            icon: Icons.person,
            children: [
              PhiveDataRow(label: 'ID', value: _loadedProfile!.id),
              PhiveDataRow(
                label: 'Temp Session',
                value: _loadedProfile!.tempSessionId,
                hook: 'TTL 10S',
              ),
              PhiveDataRow(
                label: 'Oauth Token',
                value: _loadedProfile!.encryptedToken,
                hook: 'GCM Encrypted',
              ),
            ],
          ),
          const SizedBox(height: 16),
          CacheCard(
            title: 'App Settings Module',
            icon: Icons.settings,
            children: [
              PhiveDataRow(label: 'Username', value: _loadedSettings!.username),
              PhiveDataRow(
                label: 'Secret Key',
                value: _loadedSettings!.secretKey,
                hook: 'GCM Encrypted',
              ),
              PhiveDataRow(
                label: 'Session',
                value: _loadedSettings!.cachedToken,
                hook: 'TTL 10S',
              ),
              PhiveDataRow(
                label: 'UI Config',
                value: _loadedSettings!.config.toString(),
                hook: 'Universal JSON Encrypted',
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'No valid cache in memory.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  @override
  /// Builds the primary demo page layout.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHookSectionHeader(context),
              const SizedBox(height: 20),
              StatusBadge(
                status: _status,
                saveTime: _lastSavedAt == null ? '-' : _timeLabel(_lastSavedAt!),
                restoreTime: _lastRestoredAt == null
                    ? '-'
                    : _timeLabel(_lastRestoredAt!),
                restoreCount: _restoreCount,
              ),
              const SizedBox(height: 32),
              _buildCacheViewer(context),
              const SizedBox(height: 40),
              ActionButtonBar(
                onSimulateLogin: _loginSimulatedUser,
                onRestoreCache: _loadCache,
                onPurgeStorage: _clearCache,
              ),
              const SizedBox(height: 48),
              RouterRelationsPanel(
                status: _relationStatus,
                lesson: _loadedLesson,
                cards: _loadedLessonCards,
                onSeedGraph: _seedRelationGraph,
                onLoadContainer: _loadRelationGraph,
                onDeleteCards: _deleteRelationCards,
                onCascadeDelete: _cascadeDeleteRelationGraph,
              ),
            ],
          ),
        ),
      ),
    );
  }
}