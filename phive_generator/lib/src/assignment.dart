import 'resolved_scan.dart';
import 'type_registry.dart';

/// Outcome of applying one source scan to a registry.
class AssignmentReport {
  /// The updated registry.
  final TypeIdRegistry registry;

  /// Keys newly assigned (or reactivated) in this run.
  final List<String> assigned;

  /// Keys retired in this run because their class was not found.
  final List<String> retired;

  /// Keys re-identified in this run.
  final List<String> reidentified;

  /// Resolved band per scanned class key (`null` for unbanded).
  final Map<String, String?> bandsByKey;

  /// Creates a report.
  const AssignmentReport({
    required this.registry,
    required this.assigned,
    required this.retired,
    required this.reidentified,
    required this.bandsByKey,
  });
}

/// Applies [scanned] classes to [registry].
///
/// - Each class is keyed by its band, resolved from its path, or by its simple
///   name when unbanded.
/// - New keys are assigned; retired keys found again are reactivated.
/// - Banded keys in a band covered by this scan whose class was not found are
///   retired. Unbanded keys are retired only in an already versioned registry,
///   so a flat registry is never converted by a plain rerun.
/// - Field shapes are recorded when the registry is versioned or any scanned
///   class is tolerant. Positional shape changes require [reidentify].
/// - [onlyBand] restricts assignment and retirement to one band.
///
/// Throws [StateError] (including [RegistryShapeChangeError]) for conflicts.
AssignmentReport applyScan(
  TypeIdRegistry registry,
  List<ScannedType> scanned, {
  int startAt = 0,
  String? onlyBand,
  Set<String> reidentify = const {},
}) {
  if (onlyBand != null && !registry.bands.containsKey(onlyBand)) {
    throw StateError('Unknown band "$onlyBand".');
  }

  final bandsByKey = <String, String?>{};
  final selected = <String, ScannedType>{};
  for (final type in scanned) {
    final band = registry.bandForPath(type.path)?.name;
    if (onlyBand != null && band != onlyBand) continue;
    final key = TypeIdRegistry.keyFor(type.className, band: band);
    final previous = selected[key];
    if (previous != null) {
      throw StateError(
        '"$key" is declared in both ${previous.path} and ${type.path}.',
      );
    }
    selected[key] = type;
    bandsByKey[key] = band;
  }

  final unknownReidentify = reidentify.difference(selected.keys.toSet());
  if (unknownReidentify.isNotEmpty) {
    throw StateError(
      '--reidentify names keys not found in this scan: '
      '${unknownReidentify.join(', ')}.',
    );
  }

  var current = registry;
  final assigned = <String>[];
  for (final entry in selected.entries) {
    if (current.contains(entry.key)) continue;
    current = current.assign(
      entry.value.className,
      startAt: startAt,
      band: bandsByKey[entry.key],
    );
    assigned.add(entry.key);
  }

  final coveredBands = {
    for (final type in scanned) registry.bandForPath(type.path)?.name,
  }..remove(null);
  final retired = <String>[];
  for (final key in current.assignments.keys.toList()..sort()) {
    if (selected.containsKey(key)) continue;
    final band = current.bandOfKey(key)?.name;
    final inScope = band == null
        ? onlyBand == null && registry.isVersioned
        : coveredBands.contains(band) && (onlyBand == null || band == onlyBand);
    if (!inScope) continue;
    current = current.retire(key);
    retired.add(key);
  }

  final recordShapes =
      current.isVersioned ||
      selected.values.any(
        (type) => type.tolerant || type.kind == ScannedKind.enumeration,
      );
  final reidentified = <String>[];
  if (recordShapes) {
    for (final entry in selected.entries) {
      final type = entry.value;
      final beforeId = current.lookupTypeId(entry.key);
      current = current.recordShape(
        entry.key,
        type.tolerant ? type.fields : type.positionalOrder,
        tolerant: type.tolerant,
        enumeration: type.kind == ScannedKind.enumeration,
        explicitTags: type.tolerant || type.kind == ScannedKind.enumeration
            ? type.explicitTags
            : const {},
        reidentify: reidentify.contains(entry.key),
        hadOtherHooks: type.hasOtherHooks,
        previouslyRegistered: registry.contains(entry.key),
      );
      if (current.lookupTypeId(entry.key) != beforeId) {
        reidentified.add(entry.key);
      }
    }
  } else if (reidentify.isNotEmpty) {
    throw StateError(
      '--reidentify needs recorded field shapes; declare a band or adopt '
      'TolerantLayout first.',
    );
  }

  return AssignmentReport(
    registry: current,
    assigned: assigned,
    retired: retired,
    reidentified: reidentified,
    bandsByKey: bandsByKey,
  );
}
