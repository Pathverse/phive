import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'empty_models.g.dart';

@PHiveType(80)
class EmptyPositional {
  const EmptyPositional();
}

@PHiveType(81, classHooks: [TolerantLayout()])
class EmptyTagged {
  const EmptyTagged();
}

@PHiveType(82, autoFields: true)
class PositionalEmptyParent {
  @PHiveField(0)
  final String before;
  @PHiveField(1)
  final EmptyPositional positional;
  @PHiveField(2)
  final String between;
  @PHiveField(3)
  final EmptyTagged tagged;
  @PHiveField(4)
  final String after;

  const PositionalEmptyParent(
    this.before,
    this.positional,
    this.between,
    this.tagged,
    this.after,
  );
}

@PHiveType(83, autoFields: true, classHooks: [TolerantLayout()])
class TaggedEmptyParent {
  @PHiveField(0)
  final String before;
  @PHiveField(1)
  final EmptyPositional positional;
  @PHiveField(2)
  final String between;
  @PHiveField(3)
  final EmptyTagged tagged;
  @PHiveField(4)
  final String after;

  const TaggedEmptyParent(
    this.before,
    this.positional,
    this.between,
    this.tagged,
    this.after,
  );
}
