import 'package:phive/phive.dart';

@PHiveType(70)
class EmptyPositional {
  const EmptyPositional();
  static const label = 'empty';
  String get description => label;
  Map<String, Object?> toJson() => {};
}

@PHiveType(71, classHooks: [TolerantLayout()])
class EmptyTolerant {
  const EmptyTolerant();
}

@PHiveAutoType()
class AutoEmptyPositional {
  const AutoEmptyPositional();
}

@PHiveAutoType(classHooks: [TolerantLayout()])
class AutoEmptyTolerant {
  const AutoEmptyTolerant();
}

class PassThrough extends PHiveHook {
  const PassThrough();
}

@PHiveType(74, classHooks: [PassThrough()])
class HookedEmptyPositional {
  const HookedEmptyPositional();
}

@PHiveType(75)
class UnmappedLocal {
  final String value = 'must persist';
  UnmappedLocal();
}

class BaseState {
  final String value = 'must persist';
}

@PHiveType(76)
class UnmappedInherited extends BaseState {
  UnmappedInherited();
}

mixin StateMixin {
  final String value = 'must persist';
}

@PHiveType(77)
class UnmappedMixin with StateMixin {
  UnmappedMixin();
}

@PHiveType(78)
class RequiredArgument {
  RequiredArgument(String input);
}

@PHiveType(79)
class OptionalArgument {
  OptionalArgument([String? input]);
}
