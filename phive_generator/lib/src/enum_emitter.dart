import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'resolved_scan.dart';
import 'schema_fingerprint.dart';

/// Emits one integer-tag adapter for a resolved enum.
String emitEnumAdapter({
  required EnumElement element,
  required ConstantReader annotation,
  required int typeId,
  Map<String, int>? tags,
  String? key,
}) {
  final name = element.displayName;
  if (hookListNonEmpty(annotation, 'hooks') ||
      hookListNonEmpty(annotation, 'classHooks')) {
    throw InvalidGenerationSourceError(
      'Enum $name cannot declare hooks; enums are stored as a single tag.',
      element: element,
    );
  }
  final cases = element.fields.where((f) => f.isEnumConstant).toList();
  if (tags == null) {
    final missing = cases
        .where((f) => phiveFieldIndexOf(f) == null)
        .map((f) => f.name);
    if (missing.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '$name uses @PHiveType, so every case needs an explicit @PHiveField tag; missing on ${missing.join(', ')}.',
        element: element,
      );
    }
    tags = {for (final field in cases) field.name!: phiveFieldIndexOf(field)!};
    final byTag = <int, String>{};
    for (final entry in tags.entries) {
      final previous = byTag[entry.value];
      if (previous != null) {
        throw InvalidGenerationSourceError(
          'Duplicate PHiveField tag ${entry.value} on cases $previous and ${entry.key}.',
          element: element,
        );
      }
      byTag[entry.value] = entry.key;
    }
  }
  if (cases.length != tags.length ||
      cases.any((field) => !tags!.containsKey(field.name))) {
    throw InvalidGenerationSourceError(
      'The cases of "${key ?? name}" do not match phive_type_registry.json. Run `dart run phive_generator:assign_type_ids` before build_runner.',
      element: element,
    );
  }
  final ordered = tags.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  final fingerprint = emitSchemaFingerprintGetter(
    computeSchemaFingerprint(typeId: typeId, layout: 'enum', tags: tags),
  );
  return '''
// ignore_for_file: non_constant_identifier_names

class ${name}Adapter extends PTypeAdapter<$name> {
  @override
  final int typeId = $typeId;
$fingerprint
  @override
  $name read(BinaryReader reader) {
    final raw_tag = reader.read();
    if (raw_tag is! int) {
      throw PHiveSchemaDriftException(
        typeName: '$name',
        reason: 'stored \${raw_tag.runtimeType} is not an enum case tag',
      );
    }
    switch (raw_tag) {
${ordered.map((e) => '      case ${e.value}:\n        return $name.${e.key};').join('\n')}
      default:
        throw PHiveSchemaDriftException(
          typeName: '$name',
          reason: 'unknown case tag \$raw_tag',
        );
    }
  }

  @override
  void write(BinaryWriter writer, $name obj) {
    writer.write(switch (obj) {
${ordered.map((e) => '      $name.${e.key} => ${e.value},').join('\n')}
    });
  }
}
''';
}
