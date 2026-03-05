import '../consumer.dart';

class ScopeProviderAdapter implements PHiveConsumerAdapter {
  final String envMetaKey;
  final String separator;

  ScopeProviderAdapter({
    this.envMetaKey = 'env',
    this.separator = '::',
  });

  @override
  final Set<int> providedSlots = const {
    PHiveConsumerSlots.overloadableGet,
    PHiveConsumerSlots.overloadableSet,
    PHiveConsumerSlots.overloadableDelete,
    PHiveConsumerSlots.overloadableClear,
  };

  @override
  Future<void> hydrate<T>(PHiveConsumerCtx<T> ctx) async {}

  @override
  Future<void> ensureOpen<T>(String boxName) async {}

  @override
  Future<void> set<T>(PHiveConsumerCtx<T> ctx) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete<T>(PHiveConsumerCtx<T> ctx) async {
    throw UnimplementedError();
  }

  @override
  Future<void> clear<T>(PHiveConsumerCtx<T> ctx) async {
    throw UnimplementedError();
  }

  @override
  Future<T?> get<T>(PHiveConsumerCtx<T> ctx) async {
    throw UnimplementedError();
  }
}
