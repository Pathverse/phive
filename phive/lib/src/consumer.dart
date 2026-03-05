
import 'package:hive_ce/hive.dart';

import 'adapters/default_hive_adapter.dart';
import 'exception.dart';

typedef PHiveConsumerGetMethod<T> = Future<T?> Function(dynamic key);
typedef PHiveConsumerSetMethod<T> = Future<void> Function(dynamic key, T value);
typedef PHiveConsumerDeleteMethod = Future<void> Function(dynamic key);
typedef PHiveConsumerClearMethod = Future<void> Function();

class PHiveConsumerSlots {
  static const int overloadableBox = 10;
  static const int overloadableGet = 20;
  static const int overloadableSet = 21;
  static const int overloadableDelete = 22;
  static const int overloadableClear = 23;
}

class PHiveConsumerCtx<T> {
  final void Function(PHiveActionException)? customCallback;
  final T? overwriteValue;
  final String? key;
  final Map<String, dynamic> consumerMeta;
  final Map<String, dynamic> meta;

  T? value;
  String? boxName;
  String? keyOverride;

  BoxBase<T>? overloadableBox;
  PHiveConsumerGetMethod<T>? overloadableGetMethod;
  PHiveConsumerSetMethod<T>? overloadableSetMethod;
  PHiveConsumerDeleteMethod? overloadableDeleteMethod;
  PHiveConsumerClearMethod? overloadableClearMethod;

  PHiveConsumerCtx({
    this.customCallback,
    this.overwriteValue,
    this.key,
    this.value,
    this.boxName,
    this.keyOverride,
    Map<String, dynamic>? consumerMeta,
    Map<String, dynamic>? meta,
    this.overloadableBox,
    this.overloadableGetMethod,
    this.overloadableSetMethod,
    this.overloadableDeleteMethod,
    this.overloadableClearMethod,
  })  : consumerMeta = consumerMeta ?? <String, dynamic>{},
        meta = meta ?? <String, dynamic>{};
}

abstract class PHiveConsumerAdapter {
  Set<int> get providedSlots;
  Future<void> hydrate<T>(PHiveConsumerCtx<T> ctx);
  Future<void> ensureOpen<T>(String boxName);
  Future<void> set<T>(PHiveConsumerCtx<T> ctx);
  Future<void> delete<T>(PHiveConsumerCtx<T> ctx);
  Future<void> clear<T>(PHiveConsumerCtx<T> ctx);
  Future<T?> get<T>(PHiveConsumerCtx<T> ctx);
}

class PHiveConsumer<T> {
  final String boxName;
  final List<PHiveConsumerAdapter> adapters;
  final Map<String, dynamic> consumerMeta;

  PHiveConsumer(
    this.boxName, {
    PHiveConsumerAdapter? adapter,
    List<PHiveConsumerAdapter>? adapters,
    Map<String, dynamic>? consumerMeta,
  })  : adapters = _buildAdapters(adapter: adapter, adapters: adapters),
        consumerMeta = consumerMeta ?? <String, dynamic>{} {
    _guardAdapterSlots(this.adapters);
  }

  static List<PHiveConsumerAdapter> _buildAdapters({
    PHiveConsumerAdapter? adapter,
    List<PHiveConsumerAdapter>? adapters,
  }) {
    if (adapter == null && (adapters == null || adapters.isEmpty)) {
      return [DefaultHiveAdapter()];
    }

    if (adapter != null && (adapters == null || adapters.isEmpty)) {
      return [adapter];
    }

    if (adapter == null) {
      return [...adapters!];
    }

    return [adapter, ...adapters!];
  }

  static void _guardAdapterSlots(List<PHiveConsumerAdapter> adapters) {
    final Map<int, PHiveConsumerAdapter> bySlot = {};
    for (final adapter in adapters) {
      for (final slot in adapter.providedSlots) {
        final existing = bySlot[slot];
        if (existing != null) {
          throw ArgumentError(
            'PHiveConsumer adapter slot collision on $slot between '
            '${existing.runtimeType} and ${adapter.runtimeType}',
          );
        }
        bySlot[slot] = adapter;
      }
    }
  }

  Future<PHiveConsumerCtx<T>> _prepareContext(PHiveConsumerCtx<T> context) async {
    context.boxName ??= boxName;
    for (final entry in consumerMeta.entries) {
      context.consumerMeta.putIfAbsent(entry.key, () => entry.value);
    }
    for (final adapter in adapters) {
      await adapter.hydrate<T>(context);
    }
    return context;
  }

  PHiveConsumerAdapter get _primaryAdapter => adapters.first;

  Future<void> ensureOpen() async {
    for (final adapter in adapters) {
      await adapter.ensureOpen<T>(boxName);
    }
  }

  Future<T?> get(String key, {PHiveConsumerCtx<T>? ctx}) async {
    final context = ctx ?? PHiveConsumerCtx<T>(key: key);
    context.keyOverride ??= key;
    await _prepareContext(context);

    try {
      return await _primaryAdapter.get<T>(context);
    } on PHiveActionException catch (e) {
      if (context.customCallback != null) {
        context.customCallback!(e);
      }

      if (e.codes.contains(0)) {
        rethrow;
      }

      if (e.codes.contains(3)) {
        await _primaryAdapter.delete<T>(context);
      } else if (e.codes.contains(4)) {
        await _primaryAdapter.clear<T>(context);
      }

      if (e.codes.contains(5)) {
        return context.overwriteValue; // Return graceful fallback
      }

      if (e.codes.contains(1)) {
        return null; // Consume error to return null
      }

      return null;
    }
  }

  Future<void> put(String key, T value) async {
    final context =
        PHiveConsumerCtx<T>(boxName: boxName, key: key, value: value);
    await _prepareContext(context);
    await _primaryAdapter.set<T>(context);
  }

  Future<void> delete(String key, {PHiveConsumerCtx<T>? ctx}) async {
    final context = ctx ?? PHiveConsumerCtx<T>(boxName: boxName, key: key);
    context.keyOverride ??= key;
    await _prepareContext(context);
    await _primaryAdapter.delete<T>(context);
  }

  Future<void> clear() async {
    final context = PHiveConsumerCtx<T>(boxName: boxName);
    await _prepareContext(context);
    await _primaryAdapter.clear<T>(context);
  }
}

