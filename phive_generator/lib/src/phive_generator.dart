// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:phive/phive.dart';
import 'package:source_gen/source_gen.dart';
import 'package:collection/collection.dart';
import 'package:hive_ce_generator/src/helper/helper.dart' as hive_helper;

class PhiveGenerator extends GeneratorForAnnotation<PHiveType> {
  @override
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
    
    final className = element.name;
    final typeId = annotation.read('typeId').intValue;
    final modelHooksSource = _extractModelHooksSource(element);

    final writeBlocks = <String>[];
    final readBlocks = <String>[];
    final constructorArgs = <String>[];

    final mappedFields = <Map<String, dynamic>>[];
    final accessorNames = <String>{};
    final constructorFields = constr.formalParameters.map((it) => it.displayName).toSet();

    // 1. Process constructor parameters (Crucial for Freezed factories)
    for (final param in constr.formalParameters) {
      ElementAnnotation? phiveFieldMeta;
      final metaList = param.metadata.annotations;
      for (var i = 0; i < metaList.length; i++) {
        final meta = metaList[i];
        final metaElement = meta.element;
        if (metaElement != null && (metaElement.name == 'PHiveField' || metaElement.enclosingElement?.name == 'PHiveField')) {
          phiveFieldMeta = meta;
          break;
        }
      }

      if (phiveFieldMeta != null) {
        accessorNames.add(param.displayName);
        String hooksSource = '[]';
        int index = mappedFields.length;
        
        try {
          final parsedString = phiveFieldMeta.toSource();
          final match = RegExp(r'hooks:\s*(\[.*?\])').firstMatch(parsedString); 
          if (match != null) {
            hooksSource = match.group(1)!;
          }
          final indexMatch = RegExp(r'@PHiveField\(\s*(\d+)').firstMatch(parsedString);
          if (indexMatch != null) {
            index = int.parse(indexMatch.group(1)!);
          }
        } catch (_) {}

        mappedFields.add({
          'name': param.displayName,
          'index': index,
          'hooksSource': hooksSource,
          'type': param.type.getDisplayString(withNullability: true),
        });
      }
    }

    // 2. Process regular class getters/setters
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

        if (!accessorNames.add(accessor.displayName)) {
          continue; // Already processed via constructor param
        }

        final fieldVar = accessor.variable;
        final metaList = [...fieldVar.metadata.annotations, ...accessor.metadata.annotations];
        
        ElementAnnotation? phiveFieldMeta;
        for (var i = 0; i < metaList.length; i++) {
          final meta = metaList[i];
          final metaElement = meta.element;
          if (metaElement != null && (metaElement.name == 'PHiveField' || metaElement.enclosingElement?.name == 'PHiveField')) {
            phiveFieldMeta = meta;
            break;
          }
        }

        if (phiveFieldMeta != null) {
          String hooksSource = '[]';
          int index = mappedFields.length;
          
          try {
            final parsedString = phiveFieldMeta.toSource();
            final match = RegExp(r'hooks:\s*(\[.*?\])').firstMatch(parsedString); 
            if (match != null) {
              hooksSource = match.group(1)!;
            }
            final indexMatch = RegExp(r'@PHiveField\(\s*(\d+)').firstMatch(parsedString);
            if (indexMatch != null) {
              index = int.parse(indexMatch.group(1)!);
            }
          } catch (_) {}

          mappedFields.add({
            'name': accessor.displayName,
            'index': index,
            'hooksSource': hooksSource,
            'type': accessor.returnType.getDisplayString(withNullability: true),
          });
        }
      }
    }

    mappedFields.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

    for (final field in mappedFields) {
      final name = field['name'];
      final hooksSource = _mergeHooksSource(
        modelHooksSource,
        field['hooksSource'] as String,
      );
      final typeString = field['type'];

      writeBlocks.add('''
    // $name (index ${field['index']})
    final ctx_$name = PHiveCtx()..value = obj.$name;
    runPreWrite(const $hooksSource, ctx_$name);
    writer.write(serializePayload(ctx_$name.value, ctx_$name.pendingMetadata));
    runPostWrite(const $hooksSource, ctx_$name);''');

      readBlocks.add('''
    // $name (index ${field['index']})
    final raw_$name = reader.read();
    final ctx_$name = extractPayload(raw_$name);
    runPostRead(const $hooksSource, ctx_$name);
    final res_$name = ctx_$name.value as $typeString;''');
    }

    // Safely reconstruct the class
    for (final param in constr.formalParameters) {
      final field = mappedFields.firstWhereOrNull((f) => f['name'] == param.displayName);
      if (field != null) {
        final name = field['name'];
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
