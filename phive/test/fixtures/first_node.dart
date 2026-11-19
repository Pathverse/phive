import 'package:hive_ce/hive.dart';

class Node {
  const Node(this.id);
  final String id;
}

class NodeAdapter extends TypeAdapter<Node> {
  @override
  final int typeId = 54;

  @override
  Node read(BinaryReader reader) => Node(reader.readString());

  @override
  void write(BinaryWriter writer, Node obj) => writer.writeString(obj.id);
}
