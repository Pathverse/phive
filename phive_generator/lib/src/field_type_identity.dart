import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import 'field_collection.dart';

/// Identifies the value read from each mapped member, with inherited type
/// arguments substituted in the context of the concrete model.
Map<String, String> resolvedFieldTypes(
  InterfaceElement model,
  List<CollectedField> fields,
) => {
  for (final field in fields)
    field.name: _identity(
      model.thisType.lookUpGetter(field.name, model.library)?.returnType ??
          field.dartType!,
      const {},
    ),
};

String _identity(DartType type, Map<TypeParameterElement, String> parameters) {
  final suffix = type.nullabilitySuffix == NullabilitySuffix.question
      ? '?'
      : '';
  String nested(DartType t) => _identity(t, parameters);
  if (type is InterfaceType) {
    final element = type.element;
    final uri = element.library.uri;
    final name = uri.toString() == 'dart:core'
        ? element.displayName
        : '${_libraryKey(element.library)}#${element.displayName}';
    final args = type.typeArguments;
    return '$name${args.isEmpty ? '' : '<${args.map(nested).join(', ')}>'}$suffix';
  }
  if (type is RecordType) {
    final positional = type.positionalFields.map((f) => nested(f.type));
    final named = [
      for (final f in type.namedFields) '${f.name}: ${nested(f.type)}',
    ]..sort();
    return '(${[...positional, if (named.isNotEmpty) '{${named.join(', ')}}'].join(', ')})$suffix';
  }
  if (type is FunctionType) {
    final scope = {...parameters};
    for (final param in type.typeParameters) {
      scope[param] = '@${scope.length}';
    }
    String local(DartType t) => _identity(t, scope);
    final bounds = [
      for (final param in type.typeParameters)
        '${scope[param]} extends ${param.bound == null ? 'Object?' : local(param.bound!)}',
    ];
    final required = type.normalParameterTypes.map(local);
    final optional = type.optionalParameterTypes.map(local);
    final named = [
      for (final p in type.formalParameters.where((p) => p.isNamed))
        '${p.name}: ${p.isRequiredNamed ? 'required ' : ''}${local(p.type)}',
    ]..sort();
    final args = [
      ...required,
      if (optional.isNotEmpty) '[${optional.join(', ')}]',
      if (named.isNotEmpty) '{${named.join(', ')}}',
    ];
    return '${local(type.returnType)} Function${bounds.isEmpty ? '' : '<${bounds.join(', ')}>'}(${args.join(', ')})$suffix';
  }
  if (type is TypeParameterType) {
    return '${parameters[type.element] ?? type.element.displayName}$suffix';
  }
  if (type is DynamicType) return 'dynamic';
  if (type is NeverType) return 'Never$suffix';
  if (type is VoidType) return 'void';
  throw StateError(
    'Cannot establish field identity for unresolved type ${type.getDisplayString()}',
  );
}

String _libraryKey(LibraryElement library) {
  final uri = library.uri;
  if (uri.scheme == 'file') {
    final root = library.session.analysisContext.contextRoot.root.toUri().path;
    if (uri.path.startsWith(root)) return uri.path.substring(root.length);
  }
  if (uri.scheme == 'asset') return uri.pathSegments.skip(1).join('/');
  return uri.toString();
}
