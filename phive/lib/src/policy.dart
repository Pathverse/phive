/// Describes one storage or return-side effect requested by a PHive exception.
enum PHiveActionBehavior {
  /// Deletes the current entry associated with the active read operation.
  deleteEntry,

  /// Clears the current storage box associated with the active read operation.
  clearBox,

  /// Consumes the exception and returns null to the caller.
  returnNull,
}

/// How a router registration responds when a stored record no longer matches
/// the model reading it.
///
/// Drift covers a `PHiveSchemaDriftException` raised by a generated adapter
/// or an explicitly registered tombstone, including nested values.
/// Untombstoned unknown identifiers and other errors always reach the caller.
enum PHiveDriftPolicy {
  /// The error reaches the caller and no data is removed. This is the default.
  propagate,

  /// The drifted entry is removed from the primary store and the read is a
  /// miss. Intended for caches that can be refilled from a source of truth.
  deleteAndMiss,
}
