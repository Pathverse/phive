/// CLI tool: scans a Dart package for `@PHiveAutoType` classes and assigns
/// each a stable Hive typeId in `phive_type_registry.json`.
///
/// Usage:
///   dart run phive_generator:assign_type_ids [options]
///
/// Options:
///   --dir {path}         Directory to scan for .dart files. Default: lib/
///   --root {path}        Package root that band paths are relative to.
///                        Default: the current directory
///   --registry {path}    Registry file path. Default: phive_type_registry.json
///   --start {int}        Minimum typeId for unbanded classes. Default: 0
///   --band {name}        Only assign and retire within this band.
///   --guard-field-types  Record and enforce tolerant models' field types.
///   --reidentify {key}   Retire an incompatible type's typeId and allocate a new
///                        one for its changed field shape (repeatable).
///   --retire-id {N|N-M}  Retire abandoned IDs. Inclusive ranges, repeatable.
///   --tombstones {path}   Generate explicit tombstone registration.
///   --dry-run            Print changes without writing to disk.
///   --help               Show this help message.
///
/// The tool is idempotent: running it again without source changes leaves the
/// registry unchanged. Banded classes that disappear are retired, and their
/// identifiers are never reassigned.
///
/// Run this tool after annotating or changing `@PHiveAutoType` classes, then
/// commit `phive_type_registry.json` before invoking `build_runner`.
library;

import 'dart:io';

import 'package:phive_generator/src/assignment.dart';
import 'package:phive_generator/src/resolved_scan.dart';
import 'package:phive_generator/src/type_registry.dart';
import 'package:phive_generator/src/tombstone_emitter.dart';

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) return; // --help was printed

  final scanDir = Directory(options.scanDir);
  if (!scanDir.existsSync()) {
    stderr.writeln(
      'Error: scan directory "${options.scanDir}" does not exist.',
    );
    exitCode = 1;
    return;
  }

  final registryFile = File(options.registryPath);
  final TypeIdRegistry registry;
  try {
    registry = registryFile.existsSync()
        ? TypeIdRegistry.fromJson(registryFile.readAsStringSync())
        : TypeIdRegistry.empty();
  } on FormatException catch (error) {
    stderr.writeln('Error: invalid registry: ${error.message}');
    exitCode = 1;
    return;
  }

  final AssignmentReport report;
  try {
    final scanned = await scanResolved(
      scanDir,
      root: Directory(options.rootDir),
    );
    report = applyScan(
      registry,
      scanned,
      startAt: options.startAt,
      retireIds: options.retireIds,
      onlyBand: options.band,
      reidentify: options.reidentify,
      guardFieldTypes: options.guardFieldTypes,
    );
  } on StateError catch (error) {
    stderr.writeln('Error: ${error.message}');
    exitCode = 1;
    return;
  }

  final updated = report.registry;
  stdout.writeln('Discovered ${report.bandsByKey.length} class(es):');
  for (final entry in report.bandsByKey.entries) {
    final band = entry.value == null ? 'unbanded' : 'band ${entry.value}';
    final marker = report.assigned.contains(entry.key)
        ? '+'
        : report.reidentified.contains(entry.key)
        ? '~'
        : ' ';
    stdout.writeln(
      '  $marker ${entry.key} → typeId ${updated.lookupTypeId(entry.key)} '
      '($band)',
    );
  }
  for (final key in report.retired) {
    stdout.writeln('  - $key retired');
  }

  for (var i = 0; i < report.explicitlyRetired.length; i++) {
    final start = report.explicitlyRetired[i];
    var end = start;
    while (i + 1 < report.explicitlyRetired.length &&
        report.explicitlyRetired[i + 1] == end + 1) {
      end = report.explicitlyRetired[++i];
    }
    stdout.writeln(
      '  x ${start == end ? '$start' : '$start-$end'} retired (explicit)',
    );
  }
  final unchanged = updated.toJson() == registry.toJson();
  if (options.dryRun) {
    stdout.writeln(
      '\n[dry-run] Registry NOT written to "${options.registryPath}".',
    );
    if (!unchanged) {
      stdout.writeln('Resulting registry would be:');
      stdout.writeln(updated.toJson());
    }
    if (options.tombstones != null) {
      stdout.writeln(
        '[dry-run] Tombstones NOT written to "${options.tombstones}".',
      );
    }
    return;
  }

  final tombstoneContent = options.tombstones == null
      ? null
      : emitTombstoneFile(updated);
  if (unchanged && registryFile.existsSync()) {
    stdout.writeln('\nRegistry unchanged.');
  } else {
    registryFile.writeAsStringSync(updated.toJson());
    stdout.writeln('\nRegistry written to "${options.registryPath}".');
  }
  if (options.tombstones case final path?) {
    final file = File(path);
    final content = tombstoneContent!;
    if (file.existsSync() && file.readAsStringSync() == content) {
      stdout.writeln('Tombstones unchanged.');
    } else {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
      stdout.writeln('Tombstones written to "$path".');
    }
  }
}

// ── Argument parsing ──────────────────────────────────────────────────────────

class _Options {
  final String scanDir;
  final String rootDir;
  final String registryPath;
  final int startAt;
  final String? band;
  final Set<String> reidentify;
  final bool dryRun;
  final bool guardFieldTypes;
  final Set<int> retireIds;
  final String? tombstones;

  const _Options({
    required this.scanDir,
    required this.rootDir,
    required this.registryPath,
    required this.startAt,
    required this.band,
    required this.reidentify,
    required this.dryRun,
    required this.guardFieldTypes,
    required this.retireIds,
    required this.tombstones,
  });
}

_Options? _parseArgs(List<String> args) {
  var scanDir = 'lib';
  var rootDir = '.';
  var registryPath = 'phive_type_registry.json';
  var startAt = 0;
  String? band;
  final reidentify = <String>{};
  var dryRun = false;
  var guardFieldTypes = false;
  final retireIds = <int>{};
  String? tombstones;

  String value(int i, String flag) {
    if (i + 1 >= args.length) _die('$flag requires a value');
    return args[i + 1];
  }

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--help':
      case '-h':
        _printHelp();
        return null;
      case '--guard-field-types':
        guardFieldTypes = true;
      case '--dry-run':
        dryRun = true;
      case '--dir':
        scanDir = value(i++, '--dir');
      case '--root':
        rootDir = value(i++, '--root');
      case '--registry':
        registryPath = value(i++, '--registry');
      case '--band':
        band = value(i++, '--band');
      case '--reidentify':
        reidentify.add(value(i++, '--reidentify'));
      case '--tombstones':
        tombstones = value(i++, '--tombstones');
      case '--retire-id':
        final spec = value(i++, '--retire-id');
        final match = RegExp(r'^(\d+)(?:-(\d+))?$').firstMatch(spec);
        if (match == null) _die('--retire-id $spec: expected N or N-M');
        final start = int.tryParse(match.group(1)!);
        final end = int.tryParse(match.group(2) ?? match.group(1)!);
        if (start == null || end == null || start > 65439 || end > 65439) {
          _die('--retire-id $spec: typeId must be in 0..65439');
        }
        if (start > end) _die('--retire-id $spec: range start exceeds end');
        retireIds.addAll(Iterable.generate(end - start + 1, (i) => start + i));
      case '--start':
        startAt =
            int.tryParse(value(i++, '--start')) ??
            _die('--start must be an integer');
      default:
        _die('Unknown argument: ${args[i]}');
    }
  }

  return _Options(
    scanDir: scanDir,
    rootDir: rootDir,
    registryPath: registryPath,
    startAt: startAt,
    band: band,
    reidentify: reidentify,
    dryRun: dryRun,
    guardFieldTypes: guardFieldTypes,
    retireIds: retireIds,
    tombstones: tombstones,
  );
}

Never _die(String message) {
  stderr.writeln('Error: $message');
  stderr.writeln('Run with --help for usage.');
  exit(1);
}

void _printHelp() {
  stdout.writeln('''
assign_type_ids — Assign Hive typeIds to @PHiveAutoType classes.

Usage:
  dart run phive_generator:assign_type_ids [options]

Options:
  --dir <path>         Directory to scan for .dart source files.
                       Default: lib/
  --root <path>        Package root that band path globs are relative to.
                       Default: current directory
  --registry <path>    Path to the registry JSON file.
                       Default: phive_type_registry.json
  --start <int>        Minimum typeId for unbanded classes.
                       Default: 0
  --band <name>        Only assign and retire within this band.
  --guard-field-types  Enroll scanned tolerant models from accepted source.
                       Recorded field types are checked on every later run.
  --reidentify <key>   Replace the ID after an incompatible shape, kind or
                       guarded field type change, within the same band.
                       Repeatable. Example: --reidentify api/v1/Card
  --retire-id <N|N-M>  Retire abandoned IDs. Inclusive ranges, repeatable.
  --tombstones <path>   Generate explicit tombstone registration.
  --dry-run            Print each class's band and typeId without writing.
  --help               Show this message.

Workflow:
  1. Annotate your models with @PHiveAutoType.
  2. Run this tool to populate phive_type_registry.json.
  3. Commit phive_type_registry.json.
  4. Run build_runner as normal.
''');
}
