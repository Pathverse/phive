import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import 'field_collection.dart';

/// Returns an expression converting the stored [value] to [type].
///
/// Shared by the positional and tolerant emitters.
String emitConversion(DartType type, String value) => _convert(type, value, 0);

/// Emits the declaration and conversion of `res_<field>` from [valueExpr].
///
/// Falls back to a plain cast when the field type is unresolved. A conversion
/// `TypeError` is reported as `PHiveSchemaDriftException` naming [className]
/// and the field.
String emitConvertedRead({
  required CollectedField field,
  required String className,
  required String valueExpr,
}) {
  final type = field.dartType;
  if (type == null) {
    return '    final res_${field.name} = $valueExpr as ${field.type};';
  }
  final display = type.getDisplayString();
  return '''
    final $display res_${field.name};
    try {
      res_${field.name} = ${emitConversion(type, valueExpr)};
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: '$className',
        fieldName: '${field.name}',
        reason: 'stored \${$valueExpr.runtimeType} does not match $display',
      );
    }''';
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

