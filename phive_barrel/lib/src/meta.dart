import 'dart:typed_data';

/// Provides encryption seed material for hooks that need symmetric keys.
abstract class PhiveSeedProvider {
  /// Returns a key synchronously from memory. Expects [init] to have been called.
  List<int> getSeedSync(String? seedId);

  /// Initializes the seeds dynamically.
  Future<void> init();
}

/// Holds the active seed provider used by PHive encryption hooks.
class PhiveMetaRegistry {
  /// Seed provider registered for the current process.
  static PhiveSeedProvider? seedProvider;

  /// Registers the process-wide seed provider used by encryption hooks.
  static void registerSeedProvider(PhiveSeedProvider provider) {
    seedProvider = provider;
  }

  /// Initializes the registered seed provider before encrypted reads or writes.
  static Future<void> init() async {
    if (seedProvider != null) {
      await seedProvider!.init();
    }
  }

  /// Returns a read-only snapshot of a loaded AES key.
  static List<int> requireSeedSync(String? seedId) {
    final provider = seedProvider;
    if (provider == null) {
      throw StateError(
        'No Phive seed provider is registered. '
        'Call PhiveMetaRegistry.registerSeedProvider(...) and await '
        'PhiveMetaRegistry.init() before using encryption hooks.',
      );
    }
    final seed = provider.getSeedSync(seedId);
    final length = seed.length;
    if (length != 16 && length != 24 && length != 32) {
      throw StateError(
        'Invalid AES seed length $length. Expected 16, 24, or 32 bytes.',
      );
    }
    return Uint8List.fromList(seed).asUnmodifiableView();
  }
}
