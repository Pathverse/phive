/// Signals hook-driven read or write behavior that callers may need to handle.
///
/// The optional [codes] set carries PHive-specific handling hints such as
/// delete-on-read-expiry or consume-and-return-null behavior.
class PHiveActionException implements Exception {
  /// Human-readable explanation for the action failure or policy event.
  final String message;
  // code
  // 0 = throw (rethrow, fatal)
  // 1 = consume (return null silently)
  // 2 = run targeted callback
  // 3 = delete key
  // 4 = clear box
  // 5 = set custom value (provided via context)
  /// Handling codes that describe how higher layers should react.
  final Set<int> codes;

  /// Creates an exception with one or more handling codes.
  PHiveActionException(this.message, {this.codes = const {0}}) {
    // Codes 3 (delete key) and 4 (clear box) are mutually exclusive.
    if (codes.contains(3) && codes.contains(4)) {
      throw ArgumentError(
        'Codes 3 and 4 cannot both be present in PHiveActionException.',
      );
    }
  }

  @override
  /// Returns a compact log-friendly representation of the exception.
  String toString() => 'PHiveActionException: $message';
}
