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

/// Signals that a stored record no longer matches the model reading it.
///
/// Raised by generated adapters when a record cannot be restored faithfully,
/// for example because a stored value has the wrong type or a required field
/// is absent. It requests no behavior by itself: the router's per-registration
/// drift policy decides whether the error reaches the caller or the entry is
/// removed and treated as a miss.
class PHiveSchemaDriftException extends PHiveActionException {
  /// Simple name of the model type whose record drifted.
  final String typeName;

  /// Field that could not be restored, or `null` for a record-level drift.
  final String? fieldName;

  /// Why the record could not be restored.
  final String reason;

  /// Creates a schema-drift signal for [typeName] and optional [fieldName].
  PHiveSchemaDriftException({
    required this.typeName,
    this.fieldName,
    required this.reason,
  }) : super(
         'Schema drift in '
         '${fieldName == null ? typeName : '$typeName.$fieldName'}: $reason',
       );

  @override
  /// Returns a compact log-friendly representation of the drift.
  String toString() => 'PHiveSchemaDriftException: $message';
}
