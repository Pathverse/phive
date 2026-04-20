// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:phive/phive.dart';
import 'package:source_gen/source_gen.dart';
import 'package:hive_ce_generator/src/helper/helper.dart' as hive_helper;

/// Generates `PTypeAdapter` implementations for `@PHiveType` models.
class PhiveGenerator extends GeneratorForAnnotation<PHiveType> {
  @override
  /// Builds a generated adapter for a single annotated model declaration.
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! InterfaceElement) {
      throw InvalidGenerationSourceError(
        'PHiveType can only be applied to classes or enums.',
        element: element,
      );
    }

    final cls = hive_helper.getClass(element);
    final constr = hive_helper.getConstructor(cls);
    final config = _readTypeConfig(annotation, element);
    final className = element.name;
    final typeId = annotation.read('typeId').intValue;

    final writeBlocks = <String>[];
    final readBlocks = <String>[];
    final constructorArgs = <String>[];

    final mappedFields = _collectMappedFields(
      element: element,
      cls: cls,
      constr: constr,
      autoFields: config.autoFields,
    );

    for (final field in mappedFields) {
      final name = field.name;
      final hooksSource = _mergeHooksSource(
        config.modelHooksSource,
        field.hooksSource,
      );
      final typeString = field.type;

      writeBlocks.add('''
    // $name (index ${field.index})
    final ctx_$name = PHiveCtx()..value = obj.$name;
    runPreWrite(const $hooksSource, ctx_$name);
    writer.write(serializePayload(ctx_$name.value, ctx_$name.pendingMetadata));
    runPostWrite(const $hooksSource, ctx_$name);''');

      readBlocks.add('''
    // $name (index ${field.index})
    final raw_$name = reader.read();
    final ctx_$name = extractPayload(raw_$name);
    runPostRead(const $hooksSource, ctx_$name);
    final res_$name = ctx_$name.value as $typeString;''');
    }

    // Safely reconstruct the class
    for (final param in constr.formalParameters) {
      final field = _findFieldByName(mappedFields, param.displayName);
      if (field != null) {
        final name = field.name;
        if (param.isNamed) {
          constructorArgs.add('$name: res_$name');
        } else {
          constructorArgs.add('res_$name');
        }
      }
    }

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
''';
  }

  /// Reads annotation-level generator options for a single model.
  _PhiveTypeConfig _readTypeConfig(
    ConstantReader annotation,
    InterfaceElement element,
  ) {
    return _PhiveTypeConfig(
      modelHooksSource: _extractModelHooksSource(element),
      autoFields: annotation.peek('autoFields')?.boolValue ?? false,
    );
  }

  /// Collects mapped fields from constructor parameters and accessors.
  List<_CollectedField> _collectMappedFields({
    required InterfaceElement element,
    required InterfaceElement cls,
    required ConstructorElement constr,
    required bool autoFields,
  }) {
    final fieldsByName = <String, _CollectedField>{};
    final constructorFields =
        constr.formalParameters.map((it) => it.displayName).toSet();

    for (final param in constr.formalParameters) {
      final spec = _fieldFromParameter(param, autoFields: autoFields);
      if (spec != null) {
        fieldsByName[param.displayName] = spec;
      }
    }

    final supertypes = cls.allSupertypes.map((it) => it.element).toList();
    for (final type in [cls, ...supertypes]) {
      if (type.name == 'Object') {
        continue;
      }

      for (final accessor in [...type.getters, ...type.setters]) {
        if (accessor.isStatic) {
          continue;
        }

        if (accessor is GetterElement &&
            accessor.correspondingSetter == null &&
            !constructorFields.contains(accessor.displayName)) {
          continue;
        }

        final spec = _fieldFromAccessor(
          accessor,
          constructorFields: constructorFields,
          autoFields: autoFields,
        );
        if (spec == null) {
          continue;
        }

        final existing = fieldsByName[spec.name];
        if (existing == null || spec.hasExplicitAnnotation) {
          fieldsByName[spec.name] = spec;
        }
      }
    }

    final mappedFields = _assignResolvedIndexes(
      element,
      [...fieldsByName.values],
    );

    if (mappedFields.isEmpty) {
      throw InvalidGenerationSourceError(
        'No fields were mapped for ${element.name}. '
        'Add @PHiveField annotations or enable autoFields on @PHiveType.',
        element: element,
      );
    }

    mappedFields.sort((a, b) => a.index!.compareTo(b.index!));
    return mappedFields;
  }

  /// Creates a field mapping candidate from a constructor parameter.
  _CollectedField? _fieldFromParameter(
    FormalParameterElement param, {
    required bool autoFields,
  }) {
    final phiveFieldMeta = _findPhiveFieldAnnotation(param.metadata.annotations);
    if (phiveFieldMeta == null && !autoFields) {
      return null;
    }

    final fieldConfig = _parseFieldAnnotation(phiveFieldMeta);
    return _CollectedField(
      name: param.displayName,
      index: fieldConfig.index,
      hooksSource: fieldConfig.hooksSource,
      type: param.type.getDisplayString(withNullability: true),
      hasExplicitAnnotation: phiveFieldMeta != null,
    );
  }

  /// Creates a field mapping candidate from a getter or setter accessor.
  _CollectedField? _fieldFromAccessor(
    PropertyAccessorElement accessor, {
    required Set<String> constructorFields,
    required bool autoFields,
  }) {
    final fieldVar = accessor.variable;
    final phiveFieldMeta = _findPhiveFieldAnnotation(
      [...fieldVar.metadata.annotations, ...accessor.metadata.annotations],
    );
    final shouldInfer =
        autoFields && constructorFields.contains(accessor.displayName);

    if (phiveFieldMeta == null && !shouldInfer) {
      return null;
    }

    final fieldConfig = _parseFieldAnnotation(phiveFieldMeta);
    return _CollectedField(
      name: accessor.displayName,
      index: fieldConfig.index,
      hooksSource: fieldConfig.hooksSource,
      type: accessor.returnType.getDisplayString(withNullability: true),
      hasExplicitAnnotation: phiveFieldMeta != null,
    );
  }

  /// Parses a `PHiveField` annotation into generator-friendly config.
  _FieldAnnotationConfig _parseFieldAnnotation(ElementAnnotation? annotation) {
    if (annotation == null) {
      return const _FieldAnnotationConfig(index: null, hooksSource: '[]');
    }

    String hooksSource = '[]';
    int? index;

    try {
      final parsedString = annotation.toSource();
      final hooksMatch = RegExp(r'hooks:\s*(\[.*?\])').firstMatch(parsedString);
      if (hooksMatch != null) {
        hooksSource = hooksMatch.group(1)!;
      }

      final indexMatch =
          RegExp(r'@PHiveField\(\s*(\d+)').firstMatch(parsedString);
      if (indexMatch != null) {
        index = int.parse(indexMatch.group(1)!);
      }
    } catch (_) {}

    return _FieldAnnotationConfig(index: index, hooksSource: hooksSource);
  }

  /// Returns the mapped field for a constructor parameter name, if present.
  _CollectedField? _findFieldByName(
    List<_CollectedField> fields,
    String name,
  ) {
    for (final field in fields) {
      if (field.name == name) {
        return field;
      }
    }

    return null;
  }

  /// Finds the first `PHiveField` annotation in an annotation list.
  ElementAnnotation? _findPhiveFieldAnnotation(
    List<ElementAnnotation> annotations,
  ) {
    for (final meta in annotations) {
      final metaElement = meta.element;
      if (metaElement != null &&
          (metaElement.name == 'PHiveField' ||
              metaElement.enclosingElement?.name == 'PHiveField')) {
        return meta;
      }
    }

    return null;
  }

  /// Resolves inferred field indexes while preserving explicit indexes.
  List<_CollectedField> _assignResolvedIndexes(
    InterfaceElement element,
    List<_CollectedField> fields,
  ) {
    final usedIndexes = <int, String>{};
    for (final field in fields) {
      final index = field.index;
      if (index == null) {
        continue;
      }

      final existing = usedIndexes[index];
      if (existing != null) {
        throw InvalidGenerationSourceError(
          'Duplicate PHiveField index $index on fields $existing and ${field.name}.',
          element: element,
        );
      }
      usedIndexes[index] = field.name;
    }

    var nextIndex = 0;
    return fields.map((field) {
      if (field.index != null) {
        return field;
      }

      while (usedIndexes.containsKey(nextIndex)) {
        nextIndex += 1;
      }

      final resolved = field.copyWith(index: nextIndex);
      usedIndexes[nextIndex] = field.name;
      nextIndex += 1;
      return resolved;
    }).toList(growable: false);
  }

  /// Extracts model-level hooks declared on `@PHiveType`.
  String _extractModelHooksSource(InterfaceElement element) {
    for (final annotation in element.metadata.annotations) {
      final source = annotation.toSource();
      if (!source.startsWith('@PHiveType(')) {
        continue;
      }

      final hooksMatch = RegExp(r'hooks:\s*(\[.*?\])').firstMatch(source);
      if (hooksMatch != null) {
        return hooksMatch.group(1)!;
      }
    }

    return '[]';
  }

  /// Merges model-level and field-level hook source expressions.
  String _mergeHooksSource(String modelHooksSource, String fieldHooksSource) {
    final modelHooks = modelHooksSource.trim();
    final fieldHooks = fieldHooksSource.trim();

    if (modelHooks == '[]') {
      return fieldHooks;
    }

    if (fieldHooks == '[]') {
      return modelHooks;
    }

    return '[...$modelHooks, ...$fieldHooks]';
  }
}

/// Carries resolved `@PHiveType` generator options for one model.
class _PhiveTypeConfig {
  /// Source text for model-level hook declarations.
  final String modelHooksSource;

  /// Whether unannotated constructor-backed fields should be inferred.
  final bool autoFields;

  /// Creates an immutable container for type-level generator options.
  const _PhiveTypeConfig({
    required this.modelHooksSource,
    required this.autoFields,
  });
}

/// Stores parsed `@PHiveField` annotation data before index resolution.
class _FieldAnnotationConfig {
  /// Explicit field index, if one was declared.
  final int? index;

  /// Source text for field-level hook declarations.
  final String hooksSource;

  /// Creates an immutable field annotation parse result.
  const _FieldAnnotationConfig({required this.index, required this.hooksSource});
}

/// Represents one mapped field collected for adapter generation.
class _CollectedField {
  /// Field name used in generated adapter code.
  final String name;

  /// Explicit or resolved field index.
  final int? index;

  /// Source text for the field-level hooks list.
  final String hooksSource;

  /// Dart type string used for read casts.
  final String type;

  /// Whether the field came from an explicit `@PHiveField` annotation.
  final bool hasExplicitAnnotation;

  /// Creates an immutable collected field description.
  const _CollectedField({
    required this.name,
    required this.index,
    required this.hooksSource,
    required this.type,
    required this.hasExplicitAnnotation,
  });

  /// Returns a copy with selected fields replaced.
  _CollectedField copyWith({
    String? name,
    int? index,
    String? hooksSource,
    String? type,
    bool? hasExplicitAnnotation,
  }) {
    return _CollectedField(
      name: name ?? this.name,
      index: index ?? this.index,
      hooksSource: hooksSource ?? this.hooksSource,
      type: type ?? this.type,
      hasExplicitAnnotation:
          hasExplicitAnnotation ?? this.hasExplicitAnnotation,
    );
  }
}
