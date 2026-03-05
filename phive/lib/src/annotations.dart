import 'core.dart';

class PHiveType {
  final int typeId;
  final List<PHiveHook>? hooks;

  const PHiveType(this.typeId, {this.hooks});
}

class PHiveField {
  final int index;
  final List<PHiveHook>? hooks;

  const PHiveField(this.index, {this.hooks});
}

class PhiveMetaVar<T> {
  final T? value;
  const PhiveMetaVar([this.value]);
}
