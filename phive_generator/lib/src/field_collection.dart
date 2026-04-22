import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'annotation_helpers.dart';

/// Collects and resolves the set of Hive-mapped fields for one annotated model.
///
/// Entry point is [collectMappedFields].  All helpers below are file-private
/// and operate on the same resolved [InterfaceElement] / [ConstructorElement]
/// context passed from the generator.

// ── Public API ────────────────────────────────────────────────────────────────

/// Collects all [CollectedField] entries for [element] and returns them sorted
/// by their resolved field index.
///
/// When [autoFields] is true, constructor-backed fields without an explicit
/// `@PHiveField` annotation are included and assigned the next available index.
/// Explicit indexes always win over inferred ones.
///
/// Throws [InvalidGenerationSourceError] when no fields are found or when
/// duplicate explicit indexes are detected.
List<CollectedField> collectMappedFields({
  required InterfaceElement element,
  required InterfaceElement cls,
  required ConstructorElement constr,
  required bool autoFields,
}) {
  final fieldsByName = <String, CollectedField>{};
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
    if (type.name == 'Object') continue;

    for (final accessor in [...type.getters, ...type.setters]) {
      if (accessor.isStatic) continue;

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
      if (spec == null) continue;

      final existing = fieldsByName[spec.name];
      if (existing == null || spec.hasExplicitAnnotation) {
        fieldsByName[spec.name] = spec;
      }
    }
  }

  final resolved = _assignResolvedIndexes(element, [...fieldsByName.values]);

  if (resolved.isEmpty) {
    throw InvalidGenerationSourceError(
      'No fields were mapped for ${element.name}. '
      'Add @PHiveField annotations or enable autoFields on @PHiveType / @PHiveAutoType.',
      element: element,
    );
  }

  resolved.sort((a, b) => a.index!.compareTo(b.index!));
  return resolved;
}

// ── Private helpers ───────────────────────────────────────────────────────────

CollectedField? _fieldFromParameter(
  FormalParameterElement param, {
  required bool autoFields,
}) {
  final phiveFieldMeta =
      findAnnotationNamed(param.metadata.annotations, 'PHiveField');
  if (phiveFieldMeta == null && !autoFields) return null;

  final config = _parseFieldAnnotation(phiveFieldMeta);
  return CollectedField(
    name: param.displayName,
    index: config.index,
    hooksSource: config.hooksSource,
    type: param.type.getDisplayString(withNullability: true),
    hasExplicitAnnotation: phiveFieldMeta != null,
  );
}

CollectedField? _fieldFromAccessor(
  PropertyAccessorElement accessor, {
  required Set<String> constructorFields,
  required bool autoFields,
}) {
  final fieldVar = accessor.variable;
  final phiveFieldMeta = findAnnotationNamed(
    [...fieldVar.metadata.annotations, ...accessor.metadata.annotations],
    'PHiveField',
  );
  final shouldInfer =
      autoFields && constructorFields.contains(accessor.displayName);
  if (phiveFieldMeta == null && !shouldInfer) return null;

  final config = _parseFieldAnnotation(phiveFieldMeta);
  return CollectedField(
    name: accessor.displayName,
    index: config.index,
    hooksSource: config.hooksSource,
    type: accessor.returnType.getDisplayString(withNullability: true),
    hasExplicitAnnotation: phiveFieldMeta != null,
  );
}

_FieldAnnotationConfig _parseFieldAnnotation(ElementAnnotation? annotation) {
  if (annotation == null) {
    return const _FieldAnnotationConfig(index: null, hooksSource: '[]');
  }

  String hooksSource = '[]';
  int? index;

  try {
    final source = annotation.toSource();
    final hooksMatch = RegExp(r'hooks:\s*(\[.*?\])').firstMatch(source);
    if (hooksMatch != null) hooksSource = hooksMatch.group(1)!;

    final indexMatch = RegExp(r'@PHiveField\(\s*(\d+)').firstMatch(source);
    if (indexMatch != null) index = int.parse(indexMatch.group(1)!);
  } catch (_) {}

  return _FieldAnnotationConfig(index: index, hooksSource: hooksSource);
}

List<CollectedField> _assignResolvedIndexes(
  InterfaceElement element,
  List<CollectedField> fields,
) {
  final usedIndexes = <int, String>{};
  for (final field in fields) {
    final index = field.index;
    if (index == null) continue;

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
    if (field.index != null) return field;
    while (usedIndexes.containsKey(nextIndex)) nextIndex += 1;
    final resolved = field.copyWith(index: nextIndex);
    usedIndexes[nextIndex] = field.name;
    nextIndex += 1;
    return resolved;
  }).toList(growable: false);
}

// ── Data classes ──────────────────────────────────────────────────────────────

/// A Hive-mapped field collected from a model's constructor or accessors.
class CollectedField {
  /// Field name used in generated adapter code.
  final String name;

  /// Explicit or inferred field index (null until [_assignResolvedIndexes] runs).
  final int? index;

  /// Source text for the field-level hooks list expression.
  final String hooksSource;

  /// Dart type string used for read-side casts in the generated adapter.
  final String type;

  /// Whether this field came from an explicit `@PHiveField` annotation.
  final bool hasExplicitAnnotation;

  /// Creates an immutable description of one collected field.
  const CollectedField({
    required this.name,
    required this.index,
    required this.hooksSource,
    required this.type,
    required this.hasExplicitAnnotation,
  });

  /// Returns a copy with selected fields replaced.
  CollectedField copyWith({
    String? name,
    int? index,
    String? hooksSource,
    String? type,
    bool? hasExplicitAnnotation,
  }) {
    return CollectedField(
      name: name ?? this.name,
      index: index ?? this.index,
      hooksSource: hooksSource ?? this.hooksSource,
      type: type ?? this.type,
      hasExplicitAnnotation:
          hasExplicitAnnotation ?? this.hasExplicitAnnotation,
    );
  }
}

/// Parsed `@PHiveField` annotation data before index resolution.
class _FieldAnnotationConfig {
  final int? index;
  final String hooksSource;
  const _FieldAnnotationConfig({required this.index, required this.hooksSource});
}
