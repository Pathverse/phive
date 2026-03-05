abstract class PhiveSeedProvider {
  /// Returns a key synchronously from memory. Expects [init] to have been called.
  List<int> getSeedSync(String? seedId);
  
  /// Initializes the seeds dynamically.
  Future<void> init();
}

class PhiveMetaRegistry {
  static PhiveSeedProvider? seedProvider;

  static void registerSeedProvider(PhiveSeedProvider provider) {
    seedProvider = provider;
  }

  static Future<void> init() async {
    if (seedProvider != null) {
      await seedProvider!.init();
    }
  }
}
