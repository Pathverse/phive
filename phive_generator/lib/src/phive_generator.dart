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
    final className = element.displayName;
    final typeId = annotation.read('typeId').intValue;
    final routerDescriptor = _collectRouterDescriptorConfig(
      element: element,
      cls: cls,
      constr: constr,
    );

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

    final descriptorBlock = _buildRouterDescriptorBlock(
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

  /// Collects descriptor metadata for router registration annotations.
  _RouterDescriptorConfig? _collectRouterDescriptorConfig({
    required InterfaceElement element,
    required InterfaceElement cls,
    required ConstructorElement constr,
  }) {
    final membersByName = <String, _CollectedRouterMember>{};

    for (final param in constr.formalParameters) {
      final member = _routerMemberFromParameter(param);
      if (member != null) {
        membersByName[param.displayName] = member;
      }
    }

    final supertypes = cls.allSupertypes.map((it) => it.element).toList();
    for (final type in [cls, ...supertypes]) {
      if (type.name == 'Object') {
        continue;
      }

      for (final accessor in type.getters) {
        if (accessor.isStatic) {
          continue;
        }

        final member = _routerMemberFromAccessor(accessor);
        if (member == null) {
          continue;
        }

        final existing = membersByName[member.name];
        if (existing == null || member.hasExplicitAnnotation) {
          membersByName[member.name] = member;
        }
      }
    }

    if (membersByName.isEmpty) {
      return null;
    }

    final members = membersByName.values.toList(growable: false);
    final primaryKeys = members.where((it) => it.isPrimaryKey).toList();
    if (primaryKeys.length > 1) {
      throw InvalidGenerationSourceError(
        'Only one @PHivePrimaryKey may be declared on ${element.name}.',
        element: element,
      );
    }

    if (primaryKeys.isEmpty) {
      throw InvalidGenerationSourceError(
        '${element.name} declares router annotations but no @PHivePrimaryKey.',
        element: element,
      );
    }

    final primaryKey = primaryKeys.single;
    _validateRouterStringField(
      element: element,
      fieldName: primaryKey.name,
      fieldType: primaryKey.type,
      annotationName: 'PHivePrimaryKey',
    );

    final refs = <_RouterRefConfig>[];
    for (final member in members.where((it) => it.refParentTypeSource != null)) {
      _validateRouterStringField(
        element: element,
        fieldName: member.name,
        fieldType: member.type,
        annotationName: 'PHiveRef',
      );
      refs.add(_RouterRefConfig(
        fieldName: member.name,
        parentTypeSource: member.refParentTypeSource!,
        refBoxNameSource: member.refBoxNameSource,
      ));
    }

    return _RouterDescriptorConfig(
      primaryKeyFieldName: primaryKey.name,
      boxNameSource: primaryKey.boxNameSource,
      refs: refs,
    );
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

  /// Creates router descriptor metadata from a constructor parameter.
  _CollectedRouterMember? _routerMemberFromParameter(
    FormalParameterElement param,
  ) {
    final primaryKeyAnnotation = _findAnnotationNamed(
      param.metadata.annotations,
      'PHivePrimaryKey',
    );
    final refAnnotation = _findAnnotationNamed(
      param.metadata.annotations,
      'PHiveRef',
    );

    if (primaryKeyAnnotation == null && refAnnotation == null) {
      return null;
    }

    final primaryKeyConfig = _parsePrimaryKeyAnnotation(primaryKeyAnnotation);
    final refConfig = _parseRefAnnotation(refAnnotation);
    return _CollectedRouterMember(
      name: param.displayName,
      type: param.type.getDisplayString(withNullability: true),
      isPrimaryKey: primaryKeyConfig.isPrimaryKey,
      boxNameSource: primaryKeyConfig.boxNameSource,
      refParentTypeSource: refConfig.parentTypeSource,
      refBoxNameSource: refConfig.refBoxNameSource,
      hasExplicitAnnotation: true,
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

  /// Creates router descriptor metadata from a property accessor.
  _CollectedRouterMember? _routerMemberFromAccessor(
    PropertyAccessorElement accessor,
  ) {
    final annotations = [
      ...accessor.variable.metadata.annotations,
      ...accessor.metadata.annotations,
    ];
    final primaryKeyAnnotation = _findAnnotationNamed(
      annotations,
      'PHivePrimaryKey',
    );
    final refAnnotation = _findAnnotationNamed(annotations, 'PHiveRef');

    if (primaryKeyAnnotation == null && refAnnotation == null) {
      return null;
    }

    final primaryKeyConfig = _parsePrimaryKeyAnnotation(primaryKeyAnnotation);
    final refConfig = _parseRefAnnotation(refAnnotation);
    return _CollectedRouterMember(
      name: accessor.displayName,
      type: accessor.returnType.getDisplayString(withNullability: true),
      isPrimaryKey: primaryKeyConfig.isPrimaryKey,
      boxNameSource: primaryKeyConfig.boxNameSource,
      refParentTypeSource: refConfig.parentTypeSource,
      refBoxNameSource: refConfig.refBoxNameSource,
      hasExplicitAnnotation: true,
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
    return _findAnnotationNamed(annotations, 'PHiveField');
  }

  /// Finds the first annotation with a matching runtime type name.
  ElementAnnotation? _findAnnotationNamed(
    List<ElementAnnotation> annotations,
    String annotationName,
  ) {
    for (final meta in annotations) {
      final metaElement = meta.element;
      if (metaElement != null &&
          (metaElement.name == annotationName ||
              metaElement.enclosingElement?.name == annotationName)) {
        return meta;
      }
    }

    return null;
  }

  /// Parses `@PHivePrimaryKey` into generator-friendly router config.
  _PrimaryKeyAnnotationConfig _parsePrimaryKeyAnnotation(
    ElementAnnotation? annotation,
  ) {
    if (annotation == null) {
      return const _PrimaryKeyAnnotationConfig(
        isPrimaryKey: false,
        boxNameSource: null,
      );
    }

    final parsedString = annotation.toSource();
    return _PrimaryKeyAnnotationConfig(
      isPrimaryKey: true,
      boxNameSource: _extractNamedStringArgument(parsedString, 'boxName'),
    );
  }

  /// Parses `@PHiveRef` into generator-friendly router config.
  _RefAnnotationConfig _parseRefAnnotation(ElementAnnotation? annotation) {
    if (annotation == null) {
      return const _RefAnnotationConfig(
        parentTypeSource: null,
        refBoxNameSource: null,
      );
    }

    final parsedString = annotation.toSource();
    final parentMatch = RegExp(r'@PHiveRef\(\s*([A-Za-z0-9_\.]+)')
        .firstMatch(parsedString);
    return _RefAnnotationConfig(
      parentTypeSource: parentMatch?.group(1),
      refBoxNameSource: _extractNamedStringArgument(parsedString, 'refBoxName'),
    );
  }

  /// Extracts a quoted named string argument from one annotation source literal.
  String? _extractNamedStringArgument(String source, String argumentName) {
    final match = RegExp(
      '$argumentName:\\s*((?:\'.*?\')|(?:".*?"))',
    ).firstMatch(source);
    return match?.group(1);
  }

  /// Validates that router descriptor annotations are placed on string fields.
  void _validateRouterStringField({
    required InterfaceElement element,
    required String fieldName,
    required String fieldType,
    required String annotationName,
  }) {
    if (fieldType != 'String') {
      throw InvalidGenerationSourceError(
        '@$annotationName can only be applied to String fields. '
        '$fieldName on ${element.name} is $fieldType.',
        element: element,
      );
    }
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

  /// Builds the optional generated router descriptor block for one model.
  String _buildRouterDescriptorBlock({
    required String className,
    required _RouterDescriptorConfig? descriptor,
  }) {
    if (descriptor == null) {
      return '';
    }

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

/// Stores parsed `@PHivePrimaryKey` data before descriptor generation.
class _PrimaryKeyAnnotationConfig {
  /// Whether the field should drive router registration.
  final bool isPrimaryKey;

  /// Optional source text for a generated box-name override.
  final String? boxNameSource;

  /// Creates an immutable primary-key annotation parse result.
  const _PrimaryKeyAnnotationConfig({
    required this.isPrimaryKey,
    required this.boxNameSource,
  });
}

/// Stores parsed `@PHiveRef` data before descriptor generation.
class _RefAnnotationConfig {
  /// Source text for the parent type used in `createRef`.
  final String? parentTypeSource;

  /// Optional source text for a generated ref-box name override.
  final String? refBoxNameSource;

  /// Creates an immutable ref annotation parse result.
  const _RefAnnotationConfig({
    required this.parentTypeSource,
    required this.refBoxNameSource,
  });
}

/// Represents one field that contributes router-descriptor metadata.
class _CollectedRouterMember {
  /// Field name referenced by generated router closures.
  final String name;

  /// Dart type string used for router annotation validation.
  final String type;

  /// Whether this field is the generated router primary key.
  final bool isPrimaryKey;

  /// Optional source text for the generated box-name override.
  final String? boxNameSource;

  /// Optional source text for the generated ref parent type.
  final String? refParentTypeSource;

  /// Optional source text for the generated ref-box name override.
  final String? refBoxNameSource;

  /// Whether the router metadata came from an explicit annotation.
  final bool hasExplicitAnnotation;

  /// Creates an immutable router descriptor member description.
  const _CollectedRouterMember({
    required this.name,
    required this.type,
    required this.isPrimaryKey,
    required this.boxNameSource,
    required this.refParentTypeSource,
    required this.refBoxNameSource,
    required this.hasExplicitAnnotation,
  });
}

/// Carries one generated ref registration for a router descriptor.
class _RouterRefConfig {
  /// Child field that resolves the parent key for this ref.
  final String fieldName;

  /// Source text for the parent type argument.
  final String parentTypeSource;

  /// Optional source text for the ref-box name override.
  final String? refBoxNameSource;

  /// Creates an immutable generated ref description.
  const _RouterRefConfig({
    required this.fieldName,
    required this.parentTypeSource,
    required this.refBoxNameSource,
  });
}

/// Carries the resolved router descriptor config for one annotated model.
class _RouterDescriptorConfig {
  /// Field used for generated `register<T>()` primary-key extraction.
  final String primaryKeyFieldName;

  /// Optional source text for the generated box-name override.
  final String? boxNameSource;

  /// Generated child-to-parent ref registrations for this model.
  final List<_RouterRefConfig> refs;

  /// Creates an immutable router descriptor generation result.
  const _RouterDescriptorConfig({
    required this.primaryKeyFieldName,
    required this.boxNameSource,
    required this.refs,
  });
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
