import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';
import 'models/settings.dart';
import 'models/user_profile.dart';

// ── Router setup ─────────────────────────────────────────────────────────────
//
// Both types are singleton-per-box (one Settings, one UserProfile at a time),
// so the primary key is a fixed constant string.
//
// Box names match the old PHiveConsumer box names for storage compatibility.

final _router = PHiveDynamicRouter()
  ..register<Settings>(
    primaryKey: (_) => 'current_config',
    boxName: 'app_config',
  )
  ..register<UserProfile>(
    primaryKey: (_) => 'active_user',
    boxName: 'user_sessions',
  );

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phive Secure Cache Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Phive Cache Storage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Settings? _loadedSettings;
  UserProfile? _loadedProfile;
  String _status = 'Initializing...';
  DateTime? _lastSavedAt;
  DateTime? _lastRestoredAt;
  int _restoreCount = 0;

  @override
  void initState() {
    super.initState();
    _warmup();
  }

  Future<void> _warmup() async {
    try {
      await _router.ensureOpen();
      if (!mounted) return;
      setState(() {
        _status = 'Ready. Use Simulate Login then Restore Cache.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'Ready (lazy open). Use Simulate Login then Restore Cache.';
      });
    }
  }

  String _timeLabel(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

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

    // PHive hooks (encryption, TTL) fire inside the generated PTypeAdapter
    // during Hive's write path — the router just routes to the right box.
    await _router.store(userSettings);
    await _router.store(userProfile);

    final savedAt = DateTime.now();
    setState(() {
      _lastSavedAt = savedAt;
      _status = 'Saved to cache at ${_timeLabel(savedAt)}';
    });
  }

  Future<void> _loadCache() async {
    setState(() => _status = 'Loading from disk...');

    Settings? s;
    UserProfile? p;
    final restoredAt = DateTime.now();
    String statusMsg =
        'Restore #${_restoreCount + 1} succeeded at ${_timeLabel(restoredAt)}';

    try {
      s = await _router.get<Settings>('current_config');
      p = await _router.get<UserProfile>('active_user');

      if (s == null || p == null) {
        statusMsg =
            'Restore #${_restoreCount + 1} at ${_timeLabel(restoredAt)} returned empty (expired or missing).';
      }
    } on PHiveActionException catch (e) {
      // Hooks throw PHiveActionException for TTL expiry and other conditions.
      debugPrint('[PHiveRouter][GET] ${e.message} codes=${e.codes}');
      statusMsg =
          'Restore #${_restoreCount + 1} failed at ${_timeLabel(restoredAt)}: ${e.message}';
    } catch (e) {
      statusMsg =
          'Restore #${_restoreCount + 1} failed at ${_timeLabel(restoredAt)}: $e';
    }

    setState(() {
      _loadedSettings = s;
      _loadedProfile = p;
      _restoreCount += 1;
      _lastRestoredAt = restoredAt;
      _status = statusMsg;
    });
  }

  Future<void> _clearCache() async {
    // Delete the known singleton keys from each box.
    await _router.delete<Settings>('current_config');
    await _router.delete<UserProfile>('active_user');
    setState(() {
      _loadedSettings = null;
      _loadedProfile = null;
      _status = 'Cache wiped.';
    });
  }

  @override
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
              // Status Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Colors.deepPurple.shade900,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save: ${_lastSavedAt == null ? '-' : _timeLabel(_lastSavedAt!)}   '
                      'Restore: ${_lastRestoredAt == null ? '-' : _timeLabel(_lastRestoredAt!)}   '
                      'Count: $_restoreCount',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Cache viewer
              if (_loadedSettings != null && _loadedProfile != null) ...[
                _buildCard(
                  title: 'Freezed User Profile',
                  icon: Icons.person,
                  children: [
                    _dataRow('ID', _loadedProfile!.id),
                    _dataRow('Temp Session', _loadedProfile!.tempSessionId,
                        hook: 'TTL 10S'),
                    _dataRow('Oauth Token', _loadedProfile!.encryptedToken,
                        hook: 'GCM Encrypted'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'App Settings Module',
                  icon: Icons.settings,
                  children: [
                    _dataRow('Username', _loadedSettings!.username),
                    _dataRow('Secret Key', _loadedSettings!.secretKey,
                        hook: 'GCM Encrypted'),
                    _dataRow('Session', _loadedSettings!.cachedToken,
                        hook: 'TTL 10S'),
                    _dataRow('UI Config', _loadedSettings!.config.toString(),
                        hook: 'Universal JSON Encrypted'),
                  ],
                ),
              ] else ...[
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No valid cache in memory.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loginSimulatedUser,
                    icon: const Icon(Icons.download),
                    label: const Text('Simulate Login'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _loadCache,
                    icon: const Icon(Icons.storage),
                    label: const Text('Restore Cache'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _clearCache,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Purge Storage',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value, {String? hook}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(fontFamily: 'monospace')),
                if (hook != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '🛡️ $hook',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
