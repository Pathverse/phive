import '../consumer.dart';

class CollectionBoxAdapter implements PHiveConsumerAdapter {
  @override
  final Set<int> providedSlots = const {
    PHiveConsumerSlots.overloadableBox,
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
