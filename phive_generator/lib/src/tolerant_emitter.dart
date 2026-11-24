import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'adapter_emitter.dart';
import 'annotation_helpers.dart';
import 'field_collection.dart';
import 'router_collection.dart';
import 'schema_fingerprint.dart';

/// Emits the `PTypeAdapter` for a model that declares the tolerant layout.
///
/// Record layout: a version-3 metadata header, then one `Map<int, dynamic>` of
/// field tag to value. Reads look fields up by tag:
/// - unknown tags are ignored;
/// - absent nullable fields restore as `null` or their constructor default;
/// - an absent required field, or a stored value of the wrong type, raises
///   `PHiveSchemaDriftException`.
///
/// When [positionalFields] is given, version-2 records written by the type's
/// former positional adapter are read through that sequence. Without it, a
/// version-2 record raises schema drift.
String emitTolerantAdapter({
  required Element element,
  required String className,
  required int typeId,
  required List<CollectedField> mappedFields,
  required ConstructorElement constructor,
  required RouterDescriptorConfig? routerDescriptor,
  required String modelHooksSource,
  required String classHooksSource,
  required Map<String, int> tags,
  Map<String, int> retiredTags = const {},
  List<String>? positionalFields,
}) {
  for (final field in mappedFields) {
    if (!tags.containsKey(field.name)) {
      throw InvalidGenerationSourceError(
        'Field "${field.name}" of $className has no tag in '
        'phive_type_registry.json. Run '
        '`dart run phive_generator:assign_type_ids` before build_runner.',
        element: element,
      );
    }
  }
  final declared = {for (final field in mappedFields) field.name};
  final stale = tags.keys.where((name) => !declared.contains(name)).toList();
  if (stale.isNotEmpty) {
    throw InvalidGenerationSourceError(
      'phive_type_registry.json records fields ${stale.join(', ')} for '
      '$className that it no longer declares. Run '
      '`dart run phive_generator:assign_type_ids` before build_runner.',
      element: element,
    );
  }

  final ordered = [...mappedFields]
    ..sort((a, b) => tags[a.name]!.compareTo(tags[b.name]!));
  final writePrep = <String>[];
  final writeEntries = <String>[];
  final writePost = <String>[];
  final perFieldMeta = <String>[];
  final readBlocks = <String>[];

  for (final field in ordered) {
    final tag = tags[field.name]!;
    final hooks = mergeHooksSource(modelHooksSource, field.hooksSource);
    final hooked = hooks.trim() != '[]';
    final type = field.dartType;
    if (type == null) {
      throw InvalidGenerationSourceError(
        'Could not resolve the type of ${field.name} on $className.',
        element: element,
      );
    }

    if (hooked) {
      writePrep.add('''
    // ${field.name} (tag $tag)
    final ctx_${field.name} = PHiveCtx()..value = write_obj.${field.name};
    runPreWrite(const $hooks, ctx_${field.name});''');
      writeEntries.add('      $tag: ctx_${field.name}.value,');
      writePost.add('    runPostWrite(const $hooks, ctx_${field.name});');
      perFieldMeta.add(
        "        if (ctx_${field.name}.pendingMetadata.isNotEmpty) "
        "'${field.name}': Map<String, dynamic>.from("
        "ctx_${field.name}.pendingMetadata),",
      );
    } else {
      writeEntries.add('      $tag: write_obj.${field.name},');
    }

    final rawSource = hooked
        ? '''
      final ctx_${field.name} = PHiveCtx()..value = values[$tag];
      applyMetadata(ctx_${field.name}, metadata_header.metadataForField('${field.name}'));
      applyMetadata(ctx_${field.name}, metadata_header.globalMetadata);
      runPreRead(const $hooks, ctx_${field.name});
      runPostRead(const $hooks, ctx_${field.name});
      final raw_${field.name} = ctx_${field.name}.value;'''
        : '      final raw_${field.name} = values[$tag];';

    final display = type.getDisplayString();
    readBlocks.add('''
    // ${field.name} (tag $tag)
    final $display res_${field.name};
    if (values.containsKey($tag)) {
$rawSource
      try {
        res_${field.name} = ${_convert(type, 'raw_${field.name}', 0)};
      } on TypeError {
        throw PHiveSchemaDriftException(
          typeName: '$className',
          fieldName: '${field.name}',
          reason: 'stored \${raw_${field.name}.runtimeType} does not match $display',
        );
      }
    } else {
${_absentBranch(field, type, constructor, className)}
    }''');
  }

  final positionalRead = positionalFields == null
      ? '''
      throw PHiveSchemaDriftException(
        typeName: '$className',
        reason: 'version-2 record without a recorded positional sequence',
      );'''
      : [
          '      values = <int, dynamic>{};',
          for (final name in positionalFields)
            if (tags.containsKey(name))
              '      values[${tags[name]}] = reader.read(); // $name'
            else
              '      reader.read(); // retired: $name',
        ].join('\n');

  final constructorArgs = <String>[];
  for (final param in constructor.formalParameters) {
    if (!declared.contains(param.displayName)) continue;
    constructorArgs.add(
      param.isNamed
          ? '${param.displayName}: res_${param.displayName}'
          : 'res_${param.displayName}',
    );
  }

  final fingerprintBlock = emitSchemaFingerprintGetter(
    computeSchemaFingerprint(
      typeId: typeId,
      layout: 'tolerant',
      tags: {for (final field in mappedFields) field.name: tags[field.name]!},
      types: {for (final field in mappedFields) field.name: field.type},
    ),
  );

  final descriptorBlock = emitRouterDescriptorSource(
    className: className,
    descriptor: routerDescriptor,
  );

  return '''
  // ignore_for_file: non_constant_identifier_names

class ${className}Adapter extends PTypeAdapter<$className> {
  @override
  final int typeId = $typeId;
$fingerprintBlock
  @override
  $className read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());
    final Map<int, dynamic> values;
    if (metadata_header.isTagged) {
      final raw_body = reader.read();
      if (raw_body is! Map) {
        throw PHiveSchemaDriftException(
          typeName: '$className',
          reason: 'tagged record body is not a map',
        );
      }
      values = <int, dynamic>{
        for (final entry in raw_body.entries)
          if (entry.key is int) entry.key as int: entry.value,
      };
    } else {
$positionalRead
    }
${readBlocks.join('\n')}
    final result = $className(
${constructorArgs.join(',\n')}
    );
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const $classHooksSource, ctx_obj);
    runPostRead(const $classHooksSource, ctx_obj);
    return ctx_obj.value as $className;
  }

  @override
  void write(BinaryWriter writer, $className obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const $classHooksSource, ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as $className;
${writePrep.join('\n')}
    final metadata_header = createMetadataHeader(
      version: PHiveMetadataHeader.taggedVersion,
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
${perFieldMeta.join('\n')}
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(<int, dynamic>{
${writeEntries.join('\n')}
    });
${writePost.join('\n')}
    runPostWrite(const $classHooksSource, ctx_obj);
  }
}
$descriptorBlock
''';
}

/// Emits the statement assigning an absent field.
String _absentBranch(
  CollectedField field,
  DartType type,
  ConstructorElement constructor,
  String className,
) {
  final param = constructor.formalParameters
      .where((it) => it.displayName == field.name)
      .firstOrNull;
  final defaultCode = param?.defaultValueCode;
  if (param != null && param.hasDefaultValue && defaultCode != null) {
    return '      res_${field.name} = $defaultCode;';
  }
  if (type.nullabilitySuffix == NullabilitySuffix.question ||
      type is DynamicType) {
    return '      res_${field.name} = null;';
  }
  return '''
      throw PHiveSchemaDriftException(
        typeName: '$className',
        fieldName: '${field.name}',
        reason: 'required field is missing',
      );''';
}

/// Returns an expression converting [value] to [type].
///
/// Hive restores collections as `List<dynamic>`, `Set<dynamic>` and
/// `Map<dynamic, dynamic>`, so collection types are rebuilt element by element.
/// Every check goes through `castStored`, whose `is` test survives optimized
/// web builds; a mismatch surfaces as a `TypeError` that the caller maps to
/// schema drift.
String _convert(DartType type, String value, int depth) {
  if (type is DynamicType) return value;
  final nullable = type.nullabilitySuffix == NullabilitySuffix.question;
  final display = type.getDisplayString();

  String? collection;
  if (type is InterfaceType && type.typeArguments.isNotEmpty) {
    final args = type.typeArguments;
    final e = 'e$depth';
    if (type.isDartCoreList || type.isDartCoreIterable) {
      collection =
          'castStored<List<dynamic>>($value)'
          '.map<${args[0].getDisplayString()}>'
          '(($e) => ${_convert(args[0], e, depth + 1)}).toList()';
    } else if (type.isDartCoreSet) {
      collection =
          'castStored<Iterable<dynamic>>($value)'
          '.map<${args[0].getDisplayString()}>'
          '(($e) => ${_convert(args[0], e, depth + 1)}).toSet()';
    } else if (type.isDartCoreMap) {
      final k = 'k$depth';
      final v = 'v$depth';
      collection =
          'castStored<Map<dynamic, dynamic>>($value)'
          '.map<${args[0].getDisplayString()}, '
          '${args[1].getDisplayString()}>(($k, $v) => MapEntry('
          '${_convert(args[0], k, depth + 1)}, '
          '${_convert(args[1], v, depth + 1)}))';
    }
  }

  if (collection == null) return 'castStored<$display>($value)';
  return nullable ? '$value == null ? null : $collection' : collection;
}

/// Whether the evaluated `classHooks` of [annotation] include `TolerantLayout`.
bool hasTolerantLayout(ConstantReader annotation) {
  final hooks = annotation.peek('classHooks');
  if (hooks == null || hooks.isNull) return false;
  for (final hook in hooks.listValue) {
    final element = hook.type?.element;
    if (element == null || element.name != 'TolerantLayout') continue;
    final library = element.library?.uri;
    if (library != null &&
        library.isScheme('package') &&
        library.pathSegments.first == 'phive') {
      return true;
    }
  }
  return false;
}
