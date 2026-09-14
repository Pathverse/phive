import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'naming_parent.dart' as parents;
export 'naming_parent.dart';

part 'naming_models.g.dart';

const customStoreName =
    'cards_'
    'v1';
const customRefName = 'cards_by_parent_v1';

abstract interface class NamingChild {
  String get id;
  String get parentId;
}

@PHiveType(21)
class NamingCard implements NamingChild {
  @override
  @PHiveField(0)
  @PHivePrimaryKey()
  final String id;

  @override
  @PHiveField(1)
  @PHiveRef(parents.NamingParent)
  final String parentId;

  NamingCard(this.id, this.parentId);
}

@PHiveAutoType()
class AutoNamingCard implements NamingChild {
  @override
  @PHiveField(0)
  @PHivePrimaryKey()
  final String id;

  @override
  @PHiveField(1)
  @PHiveRef(parents.NamingParent)
  final String parentId;

  AutoNamingCard(this.id, this.parentId);
}

@PHiveType(23)
class CustomNamingCard implements NamingChild {
  @override
  @PHiveField(0)
  @PHivePrimaryKey(boxName: customStoreName)
  final String id;

  @override
  @PHiveField(1)
  @PHiveRef(parents.NamingParent, refBoxName: customRefName)
  final String parentId;

  CustomNamingCard(this.id, this.parentId);
}

@PHiveAutoType()
class AutoCustomNamingCard implements NamingChild {
  @override
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'auto_cards_v1')
  final String id;

  @override
  @PHiveField(1)
  @PHiveRef(parents.NamingParent, refBoxName: 'auto_cards_by_parent_v1')
  final String parentId;

  AutoCustomNamingCard(this.id, this.parentId);
}
