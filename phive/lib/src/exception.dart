import 'policy.dart';

/// Signals hook-driven read or write behavior that callers may need to handle.
class PHiveActionException implements Exception {
  /// Human-readable explanation for the action failure or policy event.
  final String message;

  /// Composable side effects the router should apply when handling this error.
  final Set<PHiveActionBehavior> behaviors;

  /// Creates an exception with a human-readable message and optional behaviors.
  PHiveActionException(this.message, {this.behaviors = const {}}) {
    if (behaviors.contains(PHiveActionBehavior.deleteEntry) &&
        behaviors.contains(PHiveActionBehavior.clearBox)) {
      throw ArgumentError(
        'deleteEntry and clearBox cannot both be present in PHiveActionException.',
      );
    }
  }

  @override
  /// Returns a compact log-friendly representation of the exception.
  String toString() => 'PHiveActionException: $message';
}
