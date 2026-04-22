import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'annotation_helpers.dart';

/// Collects router-descriptor configuration for one annotated model.
///
/// Entry point is [collectRouterDescriptorConfig].  Returns `null` when the
/// model declares no `@PHivePrimaryKey` or `@PHiveRef` annotations.

// ── Public API ────────────────────────────────────────────────────────────────

/// Collects `@PHivePrimaryKey` and `@PHiveRef` annotations from [element] and
/// returns a [RouterDescriptorConfig], or `null` when neither annotation is
/// present on any field.
///
/// Throws [InvalidGenerationSourceError] when router annotations exist but
/// no primary key is declared, when multiple primary keys are found, or when a
/// router annotation is placed on a non-`String` field.
RouterDescriptorConfig? collectRouterDescriptorConfig({
  required InterfaceElement element,
  required InterfaceElement cls,
  required ConstructorElement constr,
}) {
  final membersByName = <String, _RouterMember>{};

  for (final param in constr.formalParameters) {
    final member = _routerMemberFromParameter(param);
    if (member != null) membersByName[param.displayName] = member;
  }

  final supertypes = cls.allSupertypes.map((it) => it.element).toList();
  for (final type in [cls, ...supertypes]) {
    if (type.name == 'Object') continue;

    for (final accessor in type.getters) {
      if (accessor.isStatic) continue;
      final member = _routerMemberFromAccessor(accessor);
      if (member == null) continue;

      final existing = membersByName[member.name];
      if (existing == null || member.hasExplicitAnnotation) {
        membersByName[member.name] = member;
      }
    }
  }

  if (membersByName.isEmpty) return null;

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

  final refs = <RouterRefConfig>[];
  for (final member in members.where((it) => it.refParentTypeSource != null)) {
    _validateRouterStringField(
      element: element,
      fieldName: member.name,
      fieldType: member.type,
      annotationName: 'PHiveRef',
    );
    refs.add(RouterRefConfig(
      fieldName: member.name,
      parentTypeSource: member.refParentTypeSource!,
      refBoxNameSource: member.refBoxNameSource,
    ));
  }

  return RouterDescriptorConfig(
    primaryKeyFieldName: primaryKey.name,
    boxNameSource: primaryKey.boxNameSource,
    refs: refs,
  );
}

// ── Private helpers ───────────────────────────────────────────────────────────

_RouterMember? _routerMemberFromParameter(FormalParameterElement param) {
  final primaryKeyAnnotation =
      findAnnotationNamed(param.metadata.annotations, 'PHivePrimaryKey');
  final refAnnotation =
      findAnnotationNamed(param.metadata.annotations, 'PHiveRef');
  if (primaryKeyAnnotation == null && refAnnotation == null) return null;

  final pkConfig = _parsePrimaryKeyAnnotation(primaryKeyAnnotation);
  final refConfig = _parseRefAnnotation(refAnnotation);
  return _RouterMember(
    name: param.displayName,
    type: param.type.getDisplayString(),
    isPrimaryKey: pkConfig.isPrimaryKey,
    boxNameSource: pkConfig.boxNameSource,
    refParentTypeSource: refConfig.parentTypeSource,
    refBoxNameSource: refConfig.refBoxNameSource,
    hasExplicitAnnotation: true,
  );
}

_RouterMember? _routerMemberFromAccessor(PropertyAccessorElement accessor) {
  final annotations = [
    ...accessor.variable.metadata.annotations,
    ...accessor.metadata.annotations,
  ];
  final primaryKeyAnnotation =
      findAnnotationNamed(annotations, 'PHivePrimaryKey');
  final refAnnotation = findAnnotationNamed(annotations, 'PHiveRef');
  if (primaryKeyAnnotation == null && refAnnotation == null) return null;

  final pkConfig = _parsePrimaryKeyAnnotation(primaryKeyAnnotation);
  final refConfig = _parseRefAnnotation(refAnnotation);
  return _RouterMember(
    name: accessor.displayName,
    type: accessor.returnType.getDisplayString(),
    isPrimaryKey: pkConfig.isPrimaryKey,
    boxNameSource: pkConfig.boxNameSource,
    refParentTypeSource: refConfig.parentTypeSource,
    refBoxNameSource: refConfig.refBoxNameSource,
    hasExplicitAnnotation: true,
  );
}

_PrimaryKeyConfig _parsePrimaryKeyAnnotation(ElementAnnotation? annotation) {
  if (annotation == null) {
    return const _PrimaryKeyConfig(isPrimaryKey: false, boxNameSource: null);
  }
  final source = annotation.toSource();
  return _PrimaryKeyConfig(
    isPrimaryKey: true,
    boxNameSource: extractNamedStringArgument(source, 'boxName'),
  );
}

_RefConfig _parseRefAnnotation(ElementAnnotation? annotation) {
  if (annotation == null) {
    return const _RefConfig(parentTypeSource: null, refBoxNameSource: null);
  }
  final source = annotation.toSource();
  final parentMatch =
      RegExp(r'@PHiveRef\(\s*([A-Za-z0-9_\.]+)').firstMatch(source);
  return _RefConfig(
    parentTypeSource: parentMatch?.group(1),
    refBoxNameSource: extractNamedStringArgument(source, 'refBoxName'),
  );
}

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

// ── Data classes ──────────────────────────────────────────────────────────────

/// Resolved router-descriptor configuration for one annotated model.
class RouterDescriptorConfig {
  /// Field used for generated `register<T>()` primary-key extraction.
  final String primaryKeyFieldName;

  /// Optional source text for the generated box-name override.
  final String? boxNameSource;

  /// Generated child-to-parent ref registrations for this model.
  final List<RouterRefConfig> refs;

  /// Creates an immutable router descriptor generation result.
  const RouterDescriptorConfig({
    required this.primaryKeyFieldName,
    required this.boxNameSource,
    required this.refs,
  });
}

/// One child-to-parent ref registration entry in a router descriptor.
class RouterRefConfig {
  /// Child field that resolves the parent key for this ref.
  final String fieldName;

  /// Source text for the parent type argument.
  final String parentTypeSource;

  /// Optional source text for the ref-box name override.
  final String? refBoxNameSource;

  /// Creates an immutable generated ref description.
  const RouterRefConfig({
    required this.fieldName,
    required this.parentTypeSource,
    required this.refBoxNameSource,
  });
}

/// One field that contributes router-descriptor metadata during collection.
class _RouterMember {
  final String name;
  final String type;
  final bool isPrimaryKey;
  final String? boxNameSource;
  final String? refParentTypeSource;
  final String? refBoxNameSource;
  final bool hasExplicitAnnotation;

  const _RouterMember({
    required this.name,
    required this.type,
    required this.isPrimaryKey,
    required this.boxNameSource,
    required this.refParentTypeSource,
    required this.refBoxNameSource,
    required this.hasExplicitAnnotation,
  });
}

class _PrimaryKeyConfig {
  final bool isPrimaryKey;
  final String? boxNameSource;
  const _PrimaryKeyConfig({required this.isPrimaryKey, required this.boxNameSource});
}

class _RefConfig {
  final String? parentTypeSource;
  final String? refBoxNameSource;
  const _RefConfig({required this.parentTypeSource, required this.refBoxNameSource});
}
