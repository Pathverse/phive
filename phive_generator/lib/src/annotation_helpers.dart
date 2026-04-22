import 'package:analyzer/dart/element/element.dart';

/// Shared utilities for reading Dart annotation metadata inside generators.
///
/// All functions are pure — they receive resolved [ElementAnnotation] or
/// [InterfaceElement] values and return source strings or annotation objects
/// without performing any I/O or mutations.

/// Finds the first annotation in [annotations] whose element name matches
/// [annotationName], or `null` if none is found.
ElementAnnotation? findAnnotationNamed(
  List<ElementAnnotation> annotations,
  String annotationName,
) {
  for (final meta in annotations) {
    final element = meta.element;
    if (element != null &&
        (element.name == annotationName ||
            element.enclosingElement?.name == annotationName)) {
      return meta;
    }
  }
  return null;
}

/// Extracts the hooks list source text declared on the `@PHiveType` or
/// `@PHiveAutoType` annotation of [element], returning `'[]'` when absent.
String extractModelHooksSource(InterfaceElement element) {
  for (final annotation in element.metadata.annotations) {
    final source = annotation.toSource();
    if (!source.startsWith('@PHiveType(') &&
        !source.startsWith('@PHiveAutoType(')) {
      continue;
    }
    final hooksMatch = RegExp(r'hooks:\s*(\[.*?\])').firstMatch(source);
    if (hooksMatch != null) {
      return hooksMatch.group(1)!;
    }
  }
  return '[]';
}

/// Returns a merged hooks source expression combining [modelHooksSource] and
/// [fieldHooksSource].
///
/// When one side is empty (`'[]'`) the other side is returned unchanged.
/// When both are non-empty a spread merge expression is returned.
String mergeHooksSource(String modelHooksSource, String fieldHooksSource) {
  final model = modelHooksSource.trim();
  final field = fieldHooksSource.trim();
  if (model == '[]') return field;
  if (field == '[]') return model;
  return '[...$model, ...$field]';
}

/// Extracts the value of a named string argument from an annotation source
/// literal, returning `null` when the argument is absent.
///
/// Handles both single- and double-quoted strings.
String? extractNamedStringArgument(String source, String argumentName) {
  final match = RegExp(
    '$argumentName:\\s*((?:\'.*?\')|(?:".*?"))',
  ).firstMatch(source);
  return match?.group(1);
}
