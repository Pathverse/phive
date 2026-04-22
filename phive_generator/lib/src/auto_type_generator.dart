// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:phive/phive.dart';
import 'package:source_gen/source_gen.dart';
// ignore: implementation_imports
import 'package:hive_ce_generator/src/helper/helper.dart' as hive_helper;

import 'adapter_emitter.dart';
import 'annotation_helpers.dart';
import 'field_collection.dart';
import 'router_collection.dart';
import 'type_registry.dart';

/// Generates `PTypeAdapter` implementations for `@PHiveAutoType` models.
///
/// Unlike [PhiveGenerator], no typeId is read from the annotation.  Instead
/// the generator resolves the id from a [TypeIdRegistry]:
///
/// - In production (`PhiveAutoTypeGenerator.fromFile`) the registry is read
///   from `phive_type_registry.json` in the annotated class's package root via
///   the `build_runner` asset system.
/// - In tests a pre-populated registry can be injected via the default
///   constructor so snapshot tests remain hermetic without touching the disk.
///
/// Throws [InvalidGenerationSourceError] when the annotated class is not found
/// in the registry, prompting the developer to run the `assign_type_ids` CLI.
class PhiveAutoTypeGenerator extends GeneratorForAnnotation<PHiveAutoType> {
  /// Registry used to resolve typeIds.  Non-null only when injected for tests.
  final TypeIdRegistry? _testRegistry;

  /// Creates a generator that uses an injected [testRegistry].
  ///
  /// Intended exclusively for unit and snapshot tests.  Pass the registry that
  /// maps each fixture class name to a deterministic typeId.
  PhiveAutoTypeGenerator({TypeIdRegistry? testRegistry})
      : _testRegistry = testRegistry;

  /// Creates a generator that reads the registry from `phive_type_registry.json`
  /// at build time via the `build_runner` asset graph.
  factory PhiveAutoTypeGenerator.fromFile() =>
      PhiveAutoTypeGenerator(testRegistry: null);

  @override
  /// Builds a generated adapter for a single `@PHiveAutoType`-annotated model.
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! InterfaceElement) {
      throw InvalidGenerationSourceError(
        'PHiveAutoType can only be applied to classes or enums.',
        element: element,
      );
    }

    final className = element.displayName;
    final registry = await _resolveRegistry(buildStep);

    if (!registry.contains(className)) {
      throw InvalidGenerationSourceError(
        '"$className" is not in phive_type_registry.json.  '
        'Run `dart run phive_generator:assign_type_ids` to register it '
        'before running build_runner.',
        element: element,
      );
    }

    final typeId = registry.lookupTypeId(className);
    final cls = hive_helper.getClass(element);
    final constr = hive_helper.getConstructor(cls);
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
      className: className,
      typeId: typeId,
      mappedFields: mappedFields,
      constructor: constr,
      routerDescriptor: routerDescriptor,
      modelHooksSource: extractModelHooksSource(element),
    );
  }

  /// Returns the [TypeIdRegistry] to use for this generation pass.
  ///
  /// When [_testRegistry] is set it is returned directly (test path).
  ///
  /// Otherwise the registry is read from `phive_type_registry.json` via
  /// [dart:io] rather than through the build-step asset graph.  Root-level
  /// JSON files are not reliably included in the tracked asset graph across
  /// all `build_runner` configurations, whereas [dart:io] reads directly from
  /// the working directory — which `build_runner` always sets to the consuming
  /// package root.  The trade-off is that changing the registry file does not
  /// automatically invalidate the build cache; running `build_runner build`
  /// explicitly after `assign_type_ids` is the expected workflow.
  Future<TypeIdRegistry> _resolveRegistry(BuildStep buildStep) async {
    if (_testRegistry != null) return _testRegistry;

    final registryFile = File('phive_type_registry.json');
    if (!registryFile.existsSync()) {
      throw StateError(
        'phive_type_registry.json not found in the package root.  '
        'Run `dart run phive_generator:assign_type_ids` to create it.',
      );
    }

    return TypeIdRegistry.fromJson(registryFile.readAsStringSync());
  }
}
