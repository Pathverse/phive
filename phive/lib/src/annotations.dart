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

/// Marks the field that should back generated router registration for a model.
class PHivePrimaryKey {
  /// Optional box name override used by generated router descriptors.
  final String? boxName;

  /// Creates a primary-key annotation for generated router descriptors.
  const PHivePrimaryKey({this.boxName});
}

/// Declares a parent-key field that should register a router containership ref.
class PHiveRef {
  /// Parent model type used to build `createRef<Child, Parent>()` calls.
  final Type parentType;

  /// Optional ref-box name override used by generated router descriptors.
  final String? refBoxName;

  /// Creates a ref annotation for generator-driven router descriptors.
  const PHiveRef(this.parentType, {this.refBoxName});
}

/// Declares a PHive model type whose Hive typeId is assigned automatically.
///
/// Unlike [PHiveType], no `typeId` is supplied at the call site. Instead the
/// generator reads the workspace-level `phive_type_registry.json` file and
/// hard-codes the assigned integer into the generated adapter.  Run the
/// `assign_type_ids` CLI tool once after adding new annotated classes so the
/// registry is populated before `build_runner` is invoked.
class PHiveAutoType {
  /// Model-level hooks merged into every mapped field pipeline.
  final List<PHiveHook>? hooks;

  /// Enables deterministic field inference when `@PHiveField` is omitted.
  ///
  /// When enabled, constructor-backed fields without explicit `@PHiveField`
  /// annotations are assigned the next available field index in constructor
  /// order. Explicit indexes always win.
  final bool autoFields;

  /// Creates a PHive auto-type annotation whose typeId is registry-assigned.
  const PHiveAutoType({this.hooks, this.autoFields = false});
}

/// Wraps supplemental metadata values that travel alongside payload state.
class PhiveMetaVar<T> {
  /// Optional metadata payload stored for the variable scope.
  final T? value;

  /// Creates a metadata wrapper for hook-managed side-channel values.
  const PhiveMetaVar([this.value]);
}
