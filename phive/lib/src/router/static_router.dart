import 'router.dart';

/// A [PHiveRouter] implementation where all types are declared at compile time.
///
/// **Storage strategy:** a single [CollectionBox] (one physical Hive box)
/// stores all registered types under namespaced keys:
///   `"TypeName::primaryKey"` for primary items.
///   `"__ref::ParentType→ChildType::parentKey"` for ref lists.
///
/// **Web optimisation:** one physical box = one IndexedDB store. Opening cost
/// is paid once at [ensureOpen], after which all reads/writes hit the same
/// already-open store. This is significantly faster than [PHiveDynamicRouter]
/// on web when you have many types.
///
/// **Intended usage:**
/// ```dart
/// // Types are declared via generator annotations:
/// // @PHiveType(typeId: 1, primaryKey: #lessonId)
/// // @PHiveRef(parent: Card, resolve: #lessonId)
/// // abstract class Lesson with _$Lesson { ... }
///
/// final router = PHiveStaticRouter(boxName: 'phive_static');
/// await router.ensureOpen();
/// await router.store(lesson);
/// ```
///
/// **Status:** Pending generator support.
/// The generator must emit [PHiveTypeRegistration] + [PHiveRefRegistration]
/// objects per annotated class, which [PHiveStaticRouter.fromConfig] consumes.
class PHiveStaticRouter implements PHiveRouter {
  /// The name of the single CollectionBox used for all types.
  final String boxName;

  PHiveStaticRouter({this.boxName = 'phive_static'});

  /// Construct a [PHiveStaticRouter] from generator-emitted config objects.
  ///
  /// Each annotated class produces a config entry (type + ref definitions).
  /// The router builds its full namespace map from these entries at init time.
  ///
  /// Example (planned):
  /// ```dart
  /// final router = PHiveStaticRouter.fromConfig([
  ///   LessonRouterDef(),
  ///   CardRouterDef(),
  /// ]);
  /// await router.ensureOpen();
  /// ```
  ///
  /// Status: pending generator support — [PHiveStaticRouterEntry] and emitted
  /// *RouterDef classes do not exist yet.
  factory PHiveStaticRouter.fromConfig(
    List<dynamic> configs, {
    String boxName = 'phive_static',
  }) {
    throw UnimplementedError(
      'PHiveStaticRouter.fromConfig() is pending generator support. '
      'The generator must emit PHiveStaticRouterEntry objects per @PHiveType class.',
    );
  }

  @override
  void register<T>({
    required String Function(T item) primaryKey,
    String? boxName,
  }) {
    throw UnimplementedError(
      'PHiveStaticRouter does not support runtime registration. '
      'Types must be declared at compile time via @PHiveType annotations '
      'and consumed via PHiveStaticRouter.fromConfig().',
    );
  }

  @override
  void createRef<T, P>({
    required String Function(T item) resolve,
    String? refBoxName,
  }) {
    throw UnimplementedError(
      'PHiveStaticRouter does not support runtime ref registration. '
      'Refs must be declared at compile time via @PHiveRef annotations.',
    );
  }

  @override
  PHiveContainerHandle<T> containerOf<T, P>(P parent) {
    throw UnimplementedError('PHiveStaticRouter is not yet implemented.');
  }

  @override
  Future<void> store<T>(T item) {
    throw UnimplementedError('PHiveStaticRouter is not yet implemented.');
  }

  @override
  Future<T?> get<T>(String key) {
    throw UnimplementedError('PHiveStaticRouter is not yet implemented.');
  }

  @override
  Future<void> delete<T>(String key) {
    throw UnimplementedError('PHiveStaticRouter is not yet implemented.');
  }

  @override
  Future<List<T>> getContainer<T>(PHiveContainerHandle<T> handle) {
    throw UnimplementedError('PHiveStaticRouter is not yet implemented.');
  }

  @override
  Future<void> deleteContainer<T>(PHiveContainerHandle<T> handle) {
    throw UnimplementedError('PHiveStaticRouter is not yet implemented.');
  }

  @override
  Future<void> deleteWithChildren<T>(T item) {
    throw UnimplementedError('PHiveStaticRouter is not yet implemented.');
  }

  @override
  Future<void> ensureOpen() {
    throw UnimplementedError('PHiveStaticRouter is not yet implemented.');
  }
}
