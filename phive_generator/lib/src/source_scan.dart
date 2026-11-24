import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// One `@PHiveAutoType` class found by a parse-only scan.
///
/// The scan reads the class declaration without type resolution. Its field
/// list covers unnamed-constructor parameters (with `autoFields`) and members
/// annotated with `@PHiveField`; the generator, which resolves the full type,
/// rejects a build whose fields disagree with the recorded registry shape.
class ScannedAutoType {
  /// Simple class name.
  final String className;

  /// Package-relative POSIX path of the declaring library.
  final String path;

  /// Whether `classHooks` contains `TolerantLayout`.
  final bool tolerant;

  /// Whether any hook other than `TolerantLayout` is declared, so positional
  /// records of this type carry a metadata header.
  final bool hasOtherHooks;

  /// Mapped field names in declaration order.
  final List<String> fields;

  /// Fields with a literal `@PHiveField` index, mapped to it.
  final Map<String, int> explicitIndexes;

  /// Fields whose `@PHiveField` index is not an integer literal.
  final List<String> unresolvedIndexes;

  /// Creates one scan result.
  const ScannedAutoType({
    required this.className,
    required this.path,
    required this.tolerant,
    required this.hasOtherHooks,
    required this.fields,
    required this.explicitIndexes,
    required this.unresolvedIndexes,
  });

  /// Field names in stored positional order: explicit indexes first claim
  /// their slots, then remaining fields fill gaps in declaration order,
  /// matching the generator's index inference.
  List<String> get positionalOrder {
    final used = <int, String>{
      for (final entry in explicitIndexes.entries) entry.value: entry.key,
    };
    var next = 0;
    for (final name in fields) {
      if (explicitIndexes.containsKey(name)) continue;
      while (used.containsKey(next)) {
        next += 1;
      }
      used[next] = name;
      next += 1;
    }
    final indexes = used.keys.toList()..sort();
    return [for (final index in indexes) used[index]!];
  }
}

/// Scans [dir] for `@PHiveAutoType` classes using the Dart parser only.
///
/// Paths are reported relative to [root] with `/` separators.
List<ScannedAutoType> scanAutoTypes(Directory dir, {required Directory root}) {
  final rootPath = _normalize(root.absolute.path);
  final results = <ScannedAutoType>[];
  final dartFiles =
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in dartFiles) {
    final unit = parseString(
      content: file.readAsStringSync(),
      path: file.path,
      throwIfDiagnostics: false,
    ).unit;
    final absolute = _normalize(file.absolute.path);
    final relative = absolute.startsWith('$rootPath/')
        ? absolute.substring(rootPath.length + 1)
        : absolute;

    for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
      final annotation = declaration.metadata
          .where((it) => _simpleName(it.name.name) == 'PHiveAutoType')
          .firstOrNull;
      if (annotation == null) continue;
      results.add(_scanClass(declaration, annotation, relative));
    }
  }

  results.sort((a, b) => a.className.compareTo(b.className));
  return results;
}

ScannedAutoType _scanClass(
  ClassDeclaration declaration,
  Annotation annotation,
  String path,
) {
  final arguments = annotation.arguments?.arguments ?? const <Expression>[];
  NamedExpression? named(String name) => arguments
      .whereType<NamedExpression>()
      .where((it) => it.name.label.name == name)
      .firstOrNull;

  final autoFields = named('autoFields')?.expression is BooleanLiteral &&
      (named('autoFields')!.expression as BooleanLiteral).value;
  final classHooks = _listElements(named('classHooks')?.expression);
  final hooks = _listElements(named('hooks')?.expression);
  final tolerant = classHooks.any(_isTolerantLayout);
  final hasOtherHooks =
      hooks.isNotEmpty || classHooks.any((hook) => !_isTolerantLayout(hook));

  final fields = <String>[];
  final explicit = <String, int>{};
  final unresolved = <String>[];

  void addField(String name, NodeList<Annotation> metadata) {
    final fieldAnnotation = metadata
        .where((it) => _simpleName(it.name.name) == 'PHiveField')
        .firstOrNull;
    if (fieldAnnotation == null && !autoFields) return;
    if (!fields.contains(name)) fields.add(name);
    if (fieldAnnotation == null) return;
    final args = fieldAnnotation.arguments?.arguments ?? const <Expression>[];
    final index = args.whereType<IntegerLiteral>().firstOrNull?.value;
    final positional = args.where((it) => it is! NamedExpression).firstOrNull;
    if (index != null) {
      explicit[name] = index;
    } else if (positional != null) {
      unresolved.add(name);
    }
  }

  final members = declaration.body is BlockClassBody
      ? (declaration.body as BlockClassBody).members
      : const <ClassMember>[];
  final constructor = members
      .whereType<ConstructorDeclaration>()
      .where((it) => it.name == null && it.factoryKeyword == null)
      .firstOrNull;
  final fieldMetadata = <String, NodeList<Annotation>>{
    for (final field in members.whereType<FieldDeclaration>())
      if (!field.isStatic)
        for (final variable in field.fields.variables)
          variable.name.lexeme: field.metadata,
  };

  final visited = <String>{};
  if (constructor != null) {
    for (final parameter in constructor.parameters.parameters) {
      final name = parameter.name?.lexeme;
      if (name == null) continue;
      visited.add(name);
      final annotations = parameter.metadata.isNotEmpty
          ? parameter.metadata
          : fieldMetadata[name];
      if (annotations != null) {
        addField(name, annotations);
      } else if (autoFields && !fields.contains(name)) {
        fields.add(name);
      }
    }
  }
  for (final entry in fieldMetadata.entries) {
    if (visited.contains(entry.key)) continue;
    final annotated = entry.value.any(
      (it) => _simpleName(it.name.name) == 'PHiveField',
    );
    if (annotated) addField(entry.key, entry.value);
  }

  return ScannedAutoType(
    className: declaration.namePart.typeName.lexeme,
    path: path,
    tolerant: tolerant,
    hasOtherHooks: hasOtherHooks,
    fields: fields,
    explicitIndexes: explicit,
    unresolvedIndexes: unresolved,
  );
}

List<Expression> _listElements(Expression? expression) {
  if (expression is! ListLiteral) return const [];
  return expression.elements.whereType<Expression>().toList();
}

bool _isTolerantLayout(Expression hook) {
  if (hook is InstanceCreationExpression) {
    return _simpleName(hook.constructorName.type.name.lexeme) ==
        'TolerantLayout';
  }
  if (hook is MethodInvocation) {
    return hook.methodName.name == 'TolerantLayout';
  }
  return false;
}

String _simpleName(String name) => name.split('.').last;

String _normalize(String path) {
  // Resolve `.` and `..` segments so `--root .` matches scanned file paths.
  final resolved = Uri.file(path).normalizePath().toFilePath();
  final forward = resolved.replaceAll('\\', '/');
  return forward.endsWith('/') && forward.length > 1
      ? forward.substring(0, forward.length - 1)
      : forward;
}
