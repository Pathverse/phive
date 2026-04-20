class PHiveActionException implements Exception {
  final String message;
  // code
  // 0 = throw (rethrow, fatal)
  // 1 = consume (return null silently)
  // 2 = run targeted callback
  // 3 = delete key
  // 4 = clear box
  // 5 = set custom value (provided via context)
  final Set<int> codes;

  PHiveActionException(this.message, {this.codes = const {0}}) {
    // Codes 3 (delete key) and 4 (clear box) are mutually exclusive.
    if (codes.contains(3) && codes.contains(4)) {
      throw ArgumentError(
        'Codes 3 and 4 cannot both be present in PHiveActionException.',
      );
    }
  }

  @override
  String toString() => 'PHiveActionException: $message';
}
