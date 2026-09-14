import 'package:phive/phive.dart';
import 'naming_parent.dart' as first;
import 'naming_parent.dart' as second;

const storeName = r'''cards_$'"\path''';
const refName = 'relations_v1';

@PHiveType(70)
class ExplicitDefault {
  @PHiveField(0)
  @PHivePrimaryKey()
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent)
  final String parentId;
  ExplicitDefault(this.id, this.parentId);
}

@PHiveType(70)
class ExplicitPrefix {
  @PHiveField(0)
  @PHivePrimaryKey()
  final String id;
  @PHiveField(1)
  @PHiveRef(second.NamingParent)
  final String parentId;
  ExplicitPrefix(this.id, this.parentId);
}

@PHiveType(70)
class ExplicitCustom {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'cards_v1')
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: 'links_v1')
  final String parentId;
  ExplicitCustom(this.id, this.parentId);
}

@PHiveType(70)
class ExplicitConstant {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: storeName)
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: refName)
  final String parentId;
  ExplicitConstant(this.id, this.parentId);
}

@PHiveType(70)
class ExplicitNull {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: null)
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: null)
  final String parentId;
  ExplicitNull(this.id, this.parentId);
}

@PHiveType(70)
class ExplicitBeforeRename {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'stable_cards')
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: 'stable_links')
  final String parentId;
  ExplicitBeforeRename(this.id, this.parentId);
}

@PHiveType(70)
class ExplicitAfterRename {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'stable_cards')
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: 'stable_links')
  final String parentId;
  ExplicitAfterRename(this.id, this.parentId);
}

@PHiveAutoType()
class AutomaticDefault {
  @PHiveField(0)
  @PHivePrimaryKey()
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent)
  final String parentId;
  AutomaticDefault(this.id, this.parentId);
}

@PHiveAutoType()
class AutomaticPrefix {
  @PHiveField(0)
  @PHivePrimaryKey()
  final String id;
  @PHiveField(1)
  @PHiveRef(second.NamingParent)
  final String parentId;
  AutomaticPrefix(this.id, this.parentId);
}

@PHiveAutoType()
class AutomaticCustom {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'cards_v1')
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: 'links_v1')
  final String parentId;
  AutomaticCustom(this.id, this.parentId);
}

@PHiveAutoType()
class AutomaticConstant {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: storeName)
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: refName)
  final String parentId;
  AutomaticConstant(this.id, this.parentId);
}

@PHiveAutoType()
class AutomaticNull {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: null)
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: null)
  final String parentId;
  AutomaticNull(this.id, this.parentId);
}

@PHiveAutoType()
class AutomaticBeforeRename {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'stable_cards')
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: 'stable_links')
  final String parentId;
  AutomaticBeforeRename(this.id, this.parentId);
}

@PHiveAutoType()
class AutomaticAfterRename {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'stable_cards')
  final String id;
  @PHiveField(1)
  @PHiveRef(first.NamingParent, refBoxName: 'stable_links')
  final String parentId;
  AutomaticAfterRename(this.id, this.parentId);
}
