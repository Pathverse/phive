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
}
