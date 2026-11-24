import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'enum_models.g.dart';

@PHiveAutoType()
enum ProofColor { red, green, blue }

@PHiveAutoType()
enum ProofColorReordered {
  @PHiveField(2)
  blue,
  @PHiveField(0)
  red,
  @PHiveField(1)
  green,
}

@PHiveAutoType()
enum ProofColorTrimmed {
  @PHiveField(0)
  red,
  @PHiveField(1)
  green,
}

@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
class Palette {
  final ProofColor primary;
  final List<ProofColor> extras;
  const Palette(this.primary, this.extras);
}

@PHiveType(62)
class PositionalPalette {
  @PHiveField(0)
  final ProofColor primary;
  const PositionalPalette(this.primary);
}

/// A later build's enum reader under the original enum's identifier.
class ReorderedColorAs extends ProofColorReorderedAdapter {
  @override
  int get typeId => ProofColorAdapter().typeId;
}

/// An enum reader without blue under the original identifier.
class TrimmedColorAs extends ProofColorTrimmedAdapter {
  @override
  int get typeId => ProofColorAdapter().typeId;
}
