class PHiveActionException implements Exception {
  final String message;

  const PHiveActionException(this.message);

  @override
  String toString() => 'PHiveActionException: $message';
}

class TTLExpired extends PHiveActionException {
  const TTLExpired(super.message);
}
