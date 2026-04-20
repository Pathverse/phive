import 'core.dart';

/// Declares a PHive model type and configures adapter generation scope.
class PHiveType {
  /// Stable Hive type identifier for the generated adapter.
  final int typeId;

  /// Model-level hooks merged into every mapped field pipeline.
  final List<PHiveHook>? hooks;

  /// Enables deterministic field inference when `@PHiveField` is omitted.
  ///
  /// When enabled, constructor-backed fields without explicit `@PHiveField`
  /// annotations are assigned the next available field index in constructor
  /// order. Explicit indexes always win.
  final bool autoFields;

  /// Creates a PHive type annotation for generator-driven adapters.
  const PHiveType(this.typeId, {this.hooks, this.autoFields = false});
}

/// Declares a mapped PHive field and its adapter pipeline scope.
class PHiveField {
  /// Stable field index written to the generated adapter.
  final int index;

  /// Field-level hooks merged with model-level hooks for this field.
  final List<PHiveHook>? hooks;

  /// Creates a PHive field annotation for a single persisted property.
  const PHiveField(this.index, {this.hooks});
}

/// Wraps supplemental metadata values that travel alongside payload state.
class PhiveMetaVar<T> {
  /// Optional metadata payload stored for the variable scope.
  final T? value;

  /// Creates a metadata wrapper for hook-managed side-channel values.
  const PhiveMetaVar([this.value]);
}
