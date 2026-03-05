import 'package:hive_ce/hive.dart';

import '../consumer.dart';
import '../exception.dart';

const bool _isWebRuntime =
    bool.fromEnvironment('dart.library.js_interop') ||
    bool.fromEnvironment('dart.library.js_util');

class DefaultHiveAdapter implements PHiveConsumerAdapter {
  @override
  final Set<int> providedSlots = const {
    PHiveConsumerSlots.overloadableBox,
    PHiveConsumerSlots.overloadableGet,
    PHiveConsumerSlots.overloadableSet,
    PHiveConsumerSlots.overloadableDelete,
    PHiveConsumerSlots.overloadableClear,
  };

  final Map<String, BoxBase<dynamic>> _boxInstances = {};
  final Map<String, Future<BoxBase<dynamic>>> _openingFutures = {};

  Future<void> _resetCorruptedBox(String boxName) async {
    if (_isWebRuntime) {
      return;
    }
    _boxInstances.remove(boxName);
    _openingFutures.remove(boxName);
    await Hive.deleteBoxFromDisk(boxName);
  }

  Future<BoxBase<T>> _resolveBoxFromCtx<T>(PHiveConsumerCtx<T> ctx) async {
    final current = ctx.overloadableBox;
    if (current != null && current.isOpen) {
      return current;
    }

    final opened = await _getBox<T>(ctx.boxName!);
    ctx.overloadableBox = opened;
    return opened;
  }

  @override
  Future<void> hydrate<T>(PHiveConsumerCtx<T> ctx) async {
    if (ctx.boxName == null) {
      return;
    }

    ctx.overloadableBox ??= await _getBox<T>(ctx.boxName!);

    ctx.overloadableGetMethod ??= (dynamic key) async {
      final box = await _resolveBoxFromCtx<T>(ctx);
      if (box is LazyBox<T>) {
        return await box.get(key);
      }
      return (box as Box<T>).get(key);
    };

    ctx.overloadableSetMethod ??= (dynamic key, T value) async {
      final box = await _resolveBoxFromCtx<T>(ctx);
      await box.put(key, value);
    };

    ctx.overloadableDeleteMethod ??= (dynamic key) async {
      final box = await _resolveBoxFromCtx<T>(ctx);
      await box.delete(key);
    };

    ctx.overloadableClearMethod ??= () async {
      final box = await _resolveBoxFromCtx<T>(ctx);
      await box.clear();
    };
  }

  Future<BoxBase<T>> _getBox<T>(String boxName) async {
    final cached = _boxInstances[boxName];
    if (cached != null && cached.isOpen) {
      return cached as BoxBase<T>;
    }

    if (Hive.isBoxOpen(boxName)) {
      try {
        final openedLazy = Hive.lazyBox<T>(boxName);
        _boxInstances[boxName] = openedLazy;
        return openedLazy;
      } catch (_) {
        final opened = Hive.box<T>(boxName);
        _boxInstances[boxName] = opened;
        return opened;
      }
    }

    final opening = _openingFutures[boxName];
    if (opening != null) {
      final opened = await opening;
      return opened as BoxBase<T>;
    }

    final openFuture =
        Hive.openLazyBox<T>(boxName).then<BoxBase<dynamic>>((box) {
      _boxInstances[boxName] = box;
      return box;
    });

    _openingFutures[boxName] = openFuture;

    try {
      final opened = await openFuture;
      return opened as BoxBase<T>;
    } on PHiveActionException catch (e) {
      await _resetCorruptedBox(boxName);
      if (_isWebRuntime) {
        throw PHiveActionException(e.message, codes: {1});
      }
      rethrow;
    } catch (_) {
      throw PHiveActionException(
        PHiveConsumerExceptionMessages.boxOpenFailed,
        codes: const {1},
      );
    } finally {
      _openingFutures.remove(boxName);
    }
  }

  @override
  Future<void> ensureOpen<T>(String boxName) async {
    await _getBox<T>(boxName);
  }

  @override
  Future<void> clear<T>(PHiveConsumerCtx<T> ctx) async {
    await hydrate<T>(ctx);
    await ctx.overloadableClearMethod!();
  }

  @override
  Future<void> delete<T>(PHiveConsumerCtx<T> ctx) async {
    await hydrate<T>(ctx);
    await ctx.overloadableDeleteMethod!(ctx.keyOverride ?? ctx.key);
  }

  @override
  Future<T?> get<T>(PHiveConsumerCtx<T> ctx) async {
    await hydrate<T>(ctx);
    return await ctx.overloadableGetMethod!(ctx.keyOverride ?? ctx.key);
  }

  @override
  Future<void> set<T>(PHiveConsumerCtx<T> ctx) async {
    await hydrate<T>(ctx);
    await ctx.overloadableSetMethod!(ctx.keyOverride ?? ctx.key, ctx.value as T);
  }
}
