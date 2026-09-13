import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'plain_record.g.dart';

@PHiveType(13)
class PlainRecord {
  @PHiveField(0)
  final String id;

  @PHiveField(1)
  final int count;

  PlainRecord({required this.id, required this.count});
}
