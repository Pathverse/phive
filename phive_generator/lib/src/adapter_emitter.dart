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
/// [classHooksSource] is the whole-object hooks list expression from the model
/// annotation.
String emitAdapter({
  required String className,
  required int typeId,
  required List<CollectedField> mappedFields,
  required ConstructorElement constructor,
  required RouterDescriptorConfig? routerDescriptor,
  required String modelHooksSource,
  required String classHooksSource,
}) {
  final writeBlocks = <String>[];
  final readBlocks = <String>[];
  final constructorArgs = <String>[];
  final hasClassHooks = classHooksSource.trim() != '[]';
  final writeTarget = hasClassHooks ? 'write_obj' : 'obj';

  for (final field in mappedFields) {
    final hooks = mergeHooksSource(modelHooksSource, field.hooksSource);
    final rawReadSource = hasClassHooks && field == mappedFields.first
      ? 'has_class_metadata ? reader.read() : raw_class_metadata'
      : 'reader.read()';
  final readSharedMetadataLine = hasClassHooks
    ? '    applySharedMetadata(ctx_${field.name}, class_metadata);\n'
    : '';
  final writeSharedMetadataLine = hasClassHooks
    ? '    applySharedPendingMetadata(ctx_${field.name}, class_metadata);\n'
    : '';

    writeBlocks.add('''
    // ${field.name} (index ${field.index})
    final ctx_${field.name} = PHiveCtx()..value = $writeTarget.${field.name};
    runPreWrite(const $hooks, ctx_${field.name});
${writeSharedMetadataLine}    writer.write(serializePayload(ctx_${field.name}.value, ctx_${field.name}.pendingMetadata));
    runPostWrite(const $hooks, ctx_${field.name});''');

    readBlocks.add('''
    // ${field.name} (index ${field.index})
    final raw_${field.name} = $rawReadSource;
    final ctx_${field.name} = extractPayload(raw_${field.name});
${readSharedMetadataLine}    runPostRead(const $hooks, ctx_${field.name});
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
${_emitReadClassHooksPrelude(classHooksSource)}
${readBlocks.join('\n')}
${_emitReadReturnBlock(
    className: className,
    constructorArgs: constructorArgs,
    classHooksSource: classHooksSource,
  )}
  }

  @override
  void write(BinaryWriter writer, $className obj) {
${_emitWriteClassHooksPrelude(className: className, classHooksSource: classHooksSource)}
${writeBlocks.join('\n')}
${_emitWriteClassHooksPostlude(className: className, classHooksSource: classHooksSource)}
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

String _emitReadClassHooksBlock({
  required String className,
  required String classHooksSource,
}) {
  if (classHooksSource.trim() == '[]') {
    return '';
  }

  return '''    final ctx_obj = PHiveCtx()..value = result;
    applySharedMetadata(ctx_obj, class_metadata);
    runPostRead(const $classHooksSource, ctx_obj);
    return ctx_obj.value as $className;''';
}

String _emitReadReturnBlock({
  required String className,
  required List<String> constructorArgs,
  required String classHooksSource,
}) {
  if (classHooksSource.trim() == '[]') {
    return '''    return $className(
${constructorArgs.join(',\n')}
    );''';
  }

  return '''    final result = $className(
${constructorArgs.join(',\n')}
    );
${_emitReadClassHooksBlock(className: className, classHooksSource: classHooksSource)}''';
}

String _emitWriteClassHooksPrelude({
  required String className,
  required String classHooksSource,
}) {
  if (classHooksSource.trim() == '[]') return '';

  return '''    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const $classHooksSource, ctx_obj);
    final class_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    writer.write(serializeClassMetadataEnvelope(class_metadata));
    final write_obj = ctx_obj.value as $className;''';
}

String _emitWriteClassHooksPostlude({
  required String className,
  required String classHooksSource,
}) {
  if (classHooksSource.trim() == '[]') return '';

  return '    runPostWrite(const $classHooksSource, ctx_obj);';
}

/// Emits the read-side class metadata prelude when whole-object hooks exist.
String _emitReadClassHooksPrelude(String classHooksSource) {
  if (classHooksSource.trim() == '[]') return '';

  return '''    final raw_class_metadata = reader.read();
    final has_class_metadata = isClassMetadataEnvelope(raw_class_metadata);
    final class_metadata = has_class_metadata
        ? extractClassMetadataEnvelope(raw_class_metadata)
        : const <String, dynamic>{};
''';
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
