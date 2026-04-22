// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:phive/phive.dart';
import 'package:source_gen/source_gen.dart';
import 'package:hive_ce_generator/src/helper/helper.dart' as hive_helper;

import 'adapter_emitter.dart';
import 'annotation_helpers.dart';
import 'field_collection.dart';
import 'router_collection.dart';

/// Generates `PTypeAdapter` implementations for `@PHiveType` models.
///
/// The typeId is read directly from the annotation at the call site.  For
/// models that need auto-assigned identifiers see [PhiveAutoTypeGenerator].
class PhiveGenerator extends GeneratorForAnnotation<PHiveType> {
  @override
  /// Builds a generated adapter for a single `@PHiveType`-annotated model.
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
    final typeId = annotation.read('typeId').intValue;
    final autoFields = annotation.peek('autoFields')?.boolValue ?? false;

    final mappedFields = collectMappedFields(
      element: element,
      cls: cls,
      constr: constr,
      autoFields: autoFields,
    );

    final routerDescriptor = collectRouterDescriptorConfig(
      element: element,
      cls: cls,
      constr: constr,
    );

    return emitAdapter(
      className: element.displayName,
      typeId: typeId,
      mappedFields: mappedFields,
      constructor: constr,
      routerDescriptor: routerDescriptor,
      modelHooksSource: extractModelHooksSource(element),
      classHooksSource: extractModelClassHooksSource(element),
    );
  }
}
