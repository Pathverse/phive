import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'pinned_field_order.g.dart';

@PHiveType(116)
class PinnedFieldOrder {
  // The old generator inferred position 0 from the previous constant index 8.
  @PHiveField(0)
  final String first;

  @PHiveField(1)
  final String second;

  PinnedFieldOrder(this.first, this.second);
}
