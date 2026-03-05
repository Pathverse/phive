
class PHiveActionException implements Exception {
  final String message;
  // code 
  // 0 = throw
  // 1 = consume
  // 2 = run targeted callback
  // 3 = delete key
  // 4 = clear box
  // 5 = set custom value (provided)
  
  final Set<int> codes;
  PHiveActionException(this.message,  {this.codes = const {0}}) {
    // check 3 and 4 are not both present
    if (codes.contains(3) && codes.contains(4)) {
      throw ArgumentError('Codes 3 and 4 cannot both be present in PHiveActionException');
    }
  }

  @override
  String toString() => 'PHiveActionException: $message';
}

class PHiveConsumerExceptionMessages {
  static const String ttlExpired = 'TTLExpired';
  static const String boxOpenFailed = 'BoxOpenFailed';
}