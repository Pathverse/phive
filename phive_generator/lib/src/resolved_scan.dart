import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
// ignore: implementation_imports
import 'package:hive_ce_generator/src/helper/helper.dart' as hive_helper;

import 'annotation_helpers.dart';
import 'field_collection.dart';
import 'tolerant_emitter.dart';

/// Kind of persisted declaration.
enum ScannedKind { model, enumeration }

/// Resolved shape used by assignment and adapter generation.
class ScannedType {
  final String className;
  final String path;
  final ScannedKind kind;
  final bool tolerant;
  final bool hasOtherHooks;
  final List<String> fields;
  final Map<String, int> explicitTags;

  const ScannedType({
    required this.className,
    required this.path,
    required this.kind,
    required this.tolerant,
    required this.hasOtherHooks,
    required this.fields,
    required this.explicitTags,
  });

  List<String> get positionalOrder => fields;
}

/// Resolves package libraries and collects the generator's field shapes.
Future<List<ScannedType>> scanResolved(
  Directory dir, {
  required Directory root,
}) async {
  final rootPath = _normalize(root.absolute.path);
  if (!File('$rootPath/.dart_tool/package_config.json').existsSync()) {
    throw StateError(
      'No package config found in ${root.path}. '
      'Run `dart pub get` (or `flutter pub get`) before assign_type_ids.',
    );
  }
  final collection = AnalysisContextCollection(includedPaths: [rootPath]);
  final results = <ScannedType>[];
  try {
    final files =
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final absolute = _normalize(file.absolute.path);
      final session = collection.contextFor(absolute).currentSession;
      final library = await session.getResolvedLibrary(absolute);
      if (library is! ResolvedLibraryResult) continue;
      final path = absolute.substring(rootPath.length + 1);
      for (final element in [
        ...library.element.classes,
        ...library.element.enums,
      ]) {
        final meta = findAnnotationNamed(
          element.metadata.annotations,
          'PHiveAutoType',
        );
        if (meta == null) continue;
        final value = meta.computeConstantValue();
        if (value == null || value.isNull) {
          throw StateError(
            '$path: cannot evaluate @PHiveAutoType on ${element.displayName}',
          );
        }
        final uri = value.type?.element?.library?.uri.toString() ?? '';
        if (!uri.startsWith('package:phive/')) continue;
        try {
          final annotation = ConstantReader(value);
          results.add(
            element is EnumElement
                ? scanEnum(element, annotation, path)
                : scanModel(element as ClassElement, annotation, path),
          );
        } on InvalidGenerationSourceError catch (error) {
          throw StateError('$path: ${error.message}');
        } on StateError catch (error) {
          throw StateError('$path: ${error.message}');
        }
      }
    }
    return results..sort((a, b) => a.className.compareTo(b.className));
  } finally {
    await collection.dispose();
  }
}

bool hookListNonEmpty(ConstantReader annotation, String name) =>
    annotation.peek(name)?.listValue.isNotEmpty ?? false;

/// Collects a model through the same field collector as the adapter generator.
ScannedType scanModel(
  ClassElement element,
  ConstantReader annotation,
  String path,
) {
  final cls = hive_helper.getClass(element);
  final constructor = hive_helper.getConstructor(cls);
  final mapped = collectMappedFields(
    element: element,
    cls: cls,
    constr: constructor,
    autoFields: annotation.peek('autoFields')?.boolValue ?? false,
  );
  final classHooks = annotation.peek('classHooks')?.listValue ?? [];
  return ScannedType(
    className: element.displayName,
    path: path,
    kind: ScannedKind.model,
    tolerant: hasTolerantLayout(annotation),
    hasOtherHooks:
        hookListNonEmpty(annotation, 'hooks') ||
        classHooks.any((hook) => hook.type?.element?.name != 'TolerantLayout'),
    fields: [for (final field in mapped) field.name],
    explicitTags: {
      for (final field in mapped)
        if (field.hasExplicitAnnotation) field.name: field.index!,
    },
  );
}

/// Collects enum constants and their evaluated explicit tags.
ScannedType scanEnum(
  EnumElement element,
  ConstantReader annotation,
  String path,
) {
  final cases = element.fields.where((field) => field.isEnumConstant);
  return ScannedType(
    className: element.displayName,
    path: path,
    kind: ScannedKind.enumeration,
    tolerant: false,
    hasOtherHooks:
        hookListNonEmpty(annotation, 'hooks') ||
        hookListNonEmpty(annotation, 'classHooks'),
    fields: [for (final field in cases) field.name!],
    explicitTags: {
      for (final field in cases)
        // ignore: use_null_aware_elements
        if (phiveFieldIndexOf(field) case final tag?) field.name!: tag,
    },
  );
}

int? phiveFieldIndexOf(FieldElement field) => findAnnotationNamed(
  field.metadata.annotations,
  'PHiveField',
)?.computeConstantValue()?.getField('index')?.toIntValue();

String _normalize(String path) {
  final normalized = Uri.file(
    path,
  ).normalizePath().toFilePath().replaceAll('\\', '/');
  return normalized.endsWith('/') && normalized.length > 1
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}
