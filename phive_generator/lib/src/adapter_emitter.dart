import 'package:analyzer/dart/element/element.dart';

import 'annotation_helpers.dart';
import 'field_collection.dart';
import 'router_collection.dart';

/// Emits the full Dart source for one `PTypeAdapter` subclass and its optional
/// router descriptor class.
///
/// Entry point is [emitAdapter].  Both [PhiveGenerator] and
/// [PhiveAutoTypeGenerator] delegate here after resolving their respective
/// [typeId] sources.

// ── Public API ────────────────────────────────────────────────────────────────

/// Returns the generated Dart source string for one annotated model.
///
/// [className] and [typeId] are supplied by the calling generator.
/// [mappedFields] and [constructor] come from [collectMappedFields].
/// [routerDescriptor] comes from [collectRouterDescriptorConfig] and may be
/// `null` when the model declares no router annotations.
/// [modelHooksSource] is the hooks list expression from the model annotation.
String emitAdapter({
  required String className,
  required int typeId,
  required List<CollectedField> mappedFields,
  required ConstructorElement constructor,
  required RouterDescriptorConfig? routerDescriptor,
  required String modelHooksSource,
}) {
  final writeBlocks = <String>[];
  final readBlocks = <String>[];
  final constructorArgs = <String>[];

  for (final field in mappedFields) {
    final hooks = mergeHooksSource(modelHooksSource, field.hooksSource);

    writeBlocks.add('''
    // ${field.name} (index ${field.index})
    final ctx_${field.name} = PHiveCtx()..value = obj.${field.name};
    runPreWrite(const $hooks, ctx_${field.name});
    writer.write(serializePayload(ctx_${field.name}.value, ctx_${field.name}.pendingMetadata));
    runPostWrite(const $hooks, ctx_${field.name});''');

    readBlocks.add('''
    // ${field.name} (index ${field.index})
    final raw_${field.name} = reader.read();
    final ctx_${field.name} = extractPayload(raw_${field.name});
    runPostRead(const $hooks, ctx_${field.name});
    final res_${field.name} = ctx_${field.name}.value as ${field.type};''');
  }

  for (final param in constructor.formalParameters) {
    final field = _findFieldByName(mappedFields, param.displayName);
    if (field == null) continue;
    if (param.isNamed) {
      constructorArgs.add('${field.name}: res_${field.name}');
    } else {
      constructorArgs.add('res_${field.name}');
    }
  }

  final descriptorBlock = _emitRouterDescriptorBlock(
    className: className,
    descriptor: routerDescriptor,
  );

  return '''
  // ignore_for_file: non_constant_identifier_names

class ${className}Adapter extends PTypeAdapter<$className> {
  @override
  final int typeId = $typeId;

  @override
  $className read(BinaryReader reader) {
${readBlocks.join('\n')}
    return $className(
${constructorArgs.join(',\n')}
    );
  }

  @override
  void write(BinaryWriter writer, $className obj) {
${writeBlocks.join('\n')}
  }
}
$descriptorBlock
''';
}

// ── Private helpers ───────────────────────────────────────────────────────────

CollectedField? _findFieldByName(List<CollectedField> fields, String name) {
  for (final field in fields) {
    if (field.name == name) return field;
  }
  return null;
}

String _emitRouterDescriptorBlock({
  required String className,
  required RouterDescriptorConfig? descriptor,
}) {
  if (descriptor == null) return '';

  final lines = <String>[
    '    router.register<$className>(',
    '      primaryKey: (item) => item.${descriptor.primaryKeyFieldName},',
  ];
  if (descriptor.boxNameSource != null) {
    lines.add('      boxName: ${descriptor.boxNameSource},');
  }
  lines.add('    );');

  for (final ref in descriptor.refs) {
    lines.addAll([
      '    router.createRef<$className, ${ref.parentTypeSource}>(',
      '      resolve: (item) => item.${ref.fieldName},',
      if (ref.refBoxNameSource != null)
        '      refBoxName: ${ref.refBoxNameSource},',
      '    );',
    ]);
  }

  return '''

/// Generated router descriptor for $className registration and refs.
class ${className}RouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for $className.
  const ${className}RouterDescriptor();

  @override
  void apply(PHiveRouter router) {
${lines.join('\n')}
  }
}
''';
}
