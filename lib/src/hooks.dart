import 'ctx.dart';
import 'var.dart';

typedef PHiveHookHandler =
    void Function(PHiveVar<dynamic> variable, PHiveCtx ctx);

class PHiveHookRegistry {
  final Map<String, List<PHiveHookHandler>> _preRead =
      <String, List<PHiveHookHandler>>{};
  final Map<String, List<PHiveHookHandler>> _postRead =
      <String, List<PHiveHookHandler>>{};
  final Map<String, List<PHiveHookHandler>> _preWrite =
      <String, List<PHiveHookHandler>>{};
  final Map<String, List<PHiveHookHandler>> _postWrite =
      <String, List<PHiveHookHandler>>{};

  void registerPreRead(String actionKey, PHiveHookHandler handler) {
    _preRead.putIfAbsent(actionKey, () => <PHiveHookHandler>[]).add(handler);
  }

  void registerPostRead(String actionKey, PHiveHookHandler handler) {
    _postRead.putIfAbsent(actionKey, () => <PHiveHookHandler>[]).add(handler);
  }

  void registerPreWrite(String actionKey, PHiveHookHandler handler) {
    _preWrite.putIfAbsent(actionKey, () => <PHiveHookHandler>[]).add(handler);
  }

  void registerPostWrite(String actionKey, PHiveHookHandler handler) {
    _postWrite.putIfAbsent(actionKey, () => <PHiveHookHandler>[]).add(handler);
  }

  void runPreRead(String actionKey, PHiveVar<dynamic> variable, PHiveCtx ctx) {
    final handlers = _preRead[actionKey];
    if (handlers == null) {
      return;
    }

    for (final handler in handlers) {
      handler(variable, ctx);
    }
  }

  void runPostRead(String actionKey, PHiveVar<dynamic> variable, PHiveCtx ctx) {
    final handlers = _postRead[actionKey];
    if (handlers == null) {
      return;
    }

    for (final handler in handlers) {
      handler(variable, ctx);
    }
  }

  void runPreWrite(String actionKey, PHiveVar<dynamic> variable, PHiveCtx ctx) {
    final handlers = _preWrite[actionKey];
    if (handlers == null) {
      return;
    }

    for (final handler in handlers) {
      handler(variable, ctx);
    }
  }

  void runPostWrite(
    String actionKey,
    PHiveVar<dynamic> variable,
    PHiveCtx ctx,
  ) {
    final handlers = _postWrite[actionKey];
    if (handlers == null) {
      return;
    }

    for (final handler in handlers) {
      handler(variable, ctx);
    }
  }
}

class PHiveModelHookBridge {
  final PHiveHookRegistry registry;

  const PHiveModelHookBridge(this.registry);

  void preWrite(String actionKey, PHiveVar<dynamic> variable, PHiveCtx ctx) {
    registry.runPreWrite(actionKey, variable, ctx);
  }

  void postWrite(String actionKey, PHiveVar<dynamic> variable, PHiveCtx ctx) {
    registry.runPostWrite(actionKey, variable, ctx);
  }

  void preRead(String actionKey, PHiveVar<dynamic> variable, PHiveCtx ctx) {
    registry.runPreRead(actionKey, variable, ctx);
  }

  void postRead(String actionKey, PHiveVar<dynamic> variable, PHiveCtx ctx) {
    registry.runPostRead(actionKey, variable, ctx);
  }
}
