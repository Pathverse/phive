/// Describes one storage or return-side effect requested by a PHive exception.
enum PHiveActionBehavior {
  /// Deletes the current entry associated with the active read operation.
  deleteEntry,

  /// Clears the current storage box associated with the active read operation.
  clearBox,

  /// Consumes the exception and returns null to the caller.
  returnNull,
}