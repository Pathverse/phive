import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'naming_parent.g.dart';

@PHiveType(20)
class NamingParent {
  @PHiveField(0)
  @PHivePrimaryKey()
  final String id;
  NamingParent(this.id);
}
