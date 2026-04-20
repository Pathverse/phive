/// PHiveRouter — abstract interface and shared types for the phive routing layer.
///
/// The router is responsible for:
///   - Mapping Dart types to Hive boxes (type registry)
///   - Managing parent→child ref stores (secondary indices)
///   - Providing container-scoped CRUD operations
///
/// Two concrete implementations exist:
///   - [PHiveDynamicRouter]: runtime registration, one box per type. Flexible.
///   - [PHiveStaticRouter]: compile-time registration via generator, single
///     CollectionBox. Optimised for web (one IndexedDB store).

/// Abstract router contract shared by [PHiveDynamicRouter] and [PHiveStaticRouter].
abstract class PHiveRouter {
  /// Register a Dart type [T] with the router.
  ///
  /// [primaryKey] — extracts the storage key from an instance of [T].
  /// [boxName]    — override the default box name (defaults to T.toString().toLowerCase()).
  void register<T>({
    required String Function(T item) primaryKey,
    String? boxName,
  });

  /// Declare a parent→child containership relationship.
  ///
  /// [T] is the child type. [P] is the parent type.
  /// [resolve] extracts the parent's primary key from a child instance.
  /// [refBoxName] overrides the default ref box name.
  ///
  /// Example:
  /// ```dart
  /// router.createRef<Card, Lesson>(resolve: (card) => card.lessonId);
  /// ```
  void createRef<T, P>({
    required String Function(T item) resolve,
    String? refBoxName,
  });

  /// Returns a [PHiveContainerHandle] that identifies the ref store entry
  /// for [parent]'s children of type [T].
  ///
  /// Throws [StateError] if no ref for [T]→[P] has been registered.
  PHiveContainerHandle<T> containerOf<T, P>(P parent);

  /// Store [item] in its registered box.
  ///
  /// Also updates every ref store where [T] is registered as a child type,
  /// appending the item's primary key to the relevant parent entry.
  ///
  /// Throws [StateError] if [T] has not been registered.
  Future<void> store<T>(T item);

  /// Retrieve an item of type [T] by its primary [key].
  ///
  /// Returns null if the key does not exist.
  /// Throws [StateError] if [T] has not been registered.
  Future<T?> get<T>(String key);

  /// Delete an item of type [T] by its primary [key].
  ///
  /// Does NOT cascade into ref stores — orphan ref entries are possible.
  /// Use [deleteContainer] or [deleteWithChildren] for cascade behaviour.
  /// Throws [StateError] if [T] has not been registered.
  Future<void> delete<T>(String key);

  /// Fetch all child items of type [T] referenced by [handle].
  ///
  /// Returns an empty list if the container has no entries.
  Future<List<T>> getContainer<T>(PHiveContainerHandle<T> handle);

  /// Delete all child items of type [T] referenced by [handle],
  /// then delete the ref store entry itself.
  Future<void> deleteContainer<T>(PHiveContainerHandle<T> handle);

  /// Delete [item] from its primary box and cascade-delete all children
  /// across every ref relationship where [T] is the parent type.
  Future<void> deleteWithChildren<T>(T item);

  /// Pre-open all registered boxes.
  ///
  /// Useful for [PHiveStaticRouter] on web where opening boxes upfront avoids
  /// latency on first access (one IndexedDB store vs. many).
  Future<void> ensureOpen();
}

/// A lightweight handle that identifies a specific ref store entry.
///
/// Created by [PHiveRouter.containerOf] and consumed by
/// [PHiveRouter.getContainer] and [PHiveRouter.deleteContainer].
class PHiveContainerHandle<T> {
  /// The name of the Hive box that holds ref lists for this relationship.
  final String refBoxName;

  /// The parent's primary key — identifies which entry in the ref box to use.
  final String parentKey;

  const PHiveContainerHandle({
    required this.refBoxName,
    required this.parentKey,
  });
}

/// Internal descriptor for a registered type.
///
/// Stored in the router's type registry keyed by [Type].
class PHiveTypeRegistration {
  /// Dynamic wrapper around the typed primary key resolver.
  final String Function(dynamic item) primaryKey;

  /// The Hive box name used to store items of this type.
  final String boxName;

  const PHiveTypeRegistration({
    required this.primaryKey,
    required this.boxName,
  });
}

/// Internal descriptor for a registered ref (parent→child relationship).
///
/// Stored in the router's ref list.
class PHiveRefRegistration {
  /// The Dart [Type] of the child (e.g., Card).
  final Type childType;

  /// The Dart [Type] of the parent (e.g., Lesson).
  final Type parentType;

  /// Dynamic wrapper that extracts the parent key from a child instance.
  final String Function(dynamic item) resolve;

  /// The Hive box name used to store ref lists for this relationship.
  final String refBoxName;

  const PHiveRefRegistration({
    required this.childType,
    required this.parentType,
    required this.resolve,
    required this.refBoxName,
  });
}
