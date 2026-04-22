import 'package:analyzer/dart/element/element.dart';

import 'annotation_helpers.dart';
import 'field_collection.dart';
import 'router_collection.dart';

/// Emits the full Dart source for one `PTypeAdapter` subclass and its optional
/// router descriptor class.
///
/// Entry point is [emitAdapter]. Both [PhiveGenerator] and
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
  final writePreparationBlocks = <String>[];
  final writeBlocks = <String>[];
  final readBlocks = <String>[];
  final constructorArgs = <String>[];
  final hasClassHooks = _hasHooks(classHooksSource);
  final hasMetadataHeader =
      hasClassHooks ||
      mappedFields.any(
        (field) =>
            _hasHooks(mergeHooksSource(modelHooksSource, field.hooksSource)),
      );
  final writeTarget = hasClassHooks ? 'write_obj' : 'obj';

  for (final field in mappedFields) {
    final hooks = mergeHooksSource(modelHooksSource, field.hooksSource);
    final readMetadataLines = hasMetadataHeader
        ? "    applyMetadata(ctx_${field.name}, metadata_header.globalMetadata);\n"
            "    applyMetadata(ctx_${field.name}, metadata_header.metadataForField('${field.name}'));\n"
        : '';

    if (hasMetadataHeader) {
      writePreparationBlocks.add('''
    // ${field.name} (index ${field.index})
    final ctx_${field.name} = PHiveCtx()..value = $writeTarget.${field.name};
    runPreWrite(const $hooks, ctx_${field.name});''');

      writeBlocks.add('''
    writer.write(ctx_${field.name}.value);
    runPostWrite(const $hooks, ctx_${field.name});''');
    } else {
      writeBlocks.add('''
    // ${field.name} (index ${field.index})
    final ctx_${field.name} = PHiveCtx()..value = $writeTarget.${field.name};
    runPreWrite(const $hooks, ctx_${field.name});
    writer.write(ctx_${field.name}.value);
    runPostWrite(const $hooks, ctx_${field.name});''');
    }

    readBlocks.add('''
    // ${field.name} (index ${field.index})
    final raw_${field.name} = reader.read();
    final ctx_${field.name} = PHiveCtx()..value = raw_${field.name};
${readMetadataLines}    runPostRead(const $hooks, ctx_${field.name});
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
${_emitReadMetadataHeaderPrelude(hasMetadataHeader)}
${readBlocks.join('\n')}
${_emitReadReturnBlock(
    className: className,
    constructorArgs: constructorArgs,
    hasMetadataHeader: hasMetadataHeader,
    classHooksSource: classHooksSource,
  )}
  }

  @override
  void write(BinaryWriter writer, $className obj) {
${_emitWriteClassHooksPrelude(
    className: className,
    classHooksSource: classHooksSource,
    hasMetadataHeader: hasMetadataHeader,
  )}
${writePreparationBlocks.join('\n')}
${_emitMetadataHeaderWriteBlock(
    mappedFields: mappedFields,
    hasMetadataHeader: hasMetadataHeader,
  )}
${writeBlocks.join('\n')}
${_emitWriteClassHooksPostlude(className: className, classHooksSource: classHooksSource)}
  }
}
$descriptorBlock
''';
}

// ── Private helpers ───────────────────────────────────────────────────────────

/// Returns whether one generated hook-list expression contains hooks.
bool _hasHooks(String hooksSource) {
  return hooksSource.trim() != '[]';
}

/// Finds one collected field that matches the supplied constructor parameter.
CollectedField? _findFieldByName(List<CollectedField> fields, String name) {
  for (final field in fields) {
    if (field.name == name) return field;
  }
  return null;
}

/// Emits the whole-object post-read hook block for metadata-aware models.
String _emitReadClassHooksBlock({
  required String className,
  required bool hasMetadataHeader,
  required String classHooksSource,
}) {
  if (classHooksSource.trim() == '[]') {
    return '';
  }

  return '''    final ctx_obj = PHiveCtx()..value = result;
${hasMetadataHeader ? '    applyMetadata(ctx_obj, metadata_header.globalMetadata);\n' : ''}    runPostRead(const $classHooksSource, ctx_obj);
    return ctx_obj.value as $className;''';
}

/// Emits the generated return block for the adapter read method.
String _emitReadReturnBlock({
  required String className,
  required List<String> constructorArgs,
  required bool hasMetadataHeader,
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
${_emitReadClassHooksBlock(
    className: className,
    hasMetadataHeader: hasMetadataHeader,
    classHooksSource: classHooksSource,
  )}''';
}

/// Emits the write prelude that prepares global metadata before field writes.
String _emitWriteClassHooksPrelude({
  required String className,
  required String classHooksSource,
  required bool hasMetadataHeader,
}) {
  if (!hasMetadataHeader) return '';

  if (classHooksSource.trim() == '[]') {
    return '    final global_metadata = const <String, dynamic>{};';
  }

  return '''    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const $classHooksSource, ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as $className;''';
}

/// Emits the whole-object post-write hook block for generated adapters.
String _emitWriteClassHooksPostlude({
  required String className,
  required String classHooksSource,
}) {
  if (classHooksSource.trim() == '[]') return '';

  return '    runPostWrite(const $classHooksSource, ctx_obj);';
}

/// Emits the read-side metadata header prelude when hooks are present.
String _emitReadMetadataHeaderPrelude(bool hasMetadataHeader) {
  if (!hasMetadataHeader) return '';

  return '    final metadata_header = extractMetadataHeader(reader.read());\n';
}

/// Emits the single metadata header write for metadata-aware adapters.
String _emitMetadataHeaderWriteBlock({
  required List<CollectedField> mappedFields,
  required bool hasMetadataHeader,
}) {
  if (!hasMetadataHeader) return '';

  final perFieldEntries = mappedFields
      .map(
        (field) =>
            "        if (ctx_${field.name}.pendingMetadata.isNotEmpty) '${field.name}': Map<String, dynamic>.from(ctx_${field.name}.pendingMetadata),",
      )
      .join('\n');

  return '''    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
$perFieldEntries
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));''';
}

/// Emits the optional generated router descriptor for the annotated model.
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
